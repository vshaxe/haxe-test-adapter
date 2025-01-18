import haxe.Json;
import haxe.Timer;
import haxe.ds.ArraySort;
import haxe.io.Path;
import js.lib.Promise;
import sys.FileSystem;
import sys.io.File;
import _testadapter.data.Data;
import _testadapter.data.TestFilter;
import _testadapter.data.TestResults;
import lcov.Report;
import vscode.BranchCoverage;
import vscode.CancellationToken;
import vscode.DebugSession;
import vscode.DeclarationCoverage;
import vscode.ExtensionContext;
import vscode.FileCoverage;
import vscode.FileCoverageDetail;
import vscode.FileSystemWatcher;
import vscode.Location;
import vscode.OutputChannel;
import vscode.Position;
import vscode.ProcessExecution;
import vscode.Range;
import vscode.RelativePattern;
import vscode.StatementCoverage;
import vscode.Task;
import vscode.TaskEndEvent;
import vscode.TaskExecution;
import vscode.TestController;
import vscode.TestCoverageCount;
import vscode.TestItem;
import vscode.TestItemCollection;
import vscode.TestMessage;
import vscode.TestRun;
import vscode.TestRunRequest;
import vscode.Uri;
import vscode.WorkspaceFolder;

using StringTools;

typedef TestItemData = {
	test:TestMethodResults,
	testItem:TestItem,
	clazzUri:Uri
}

class HaxeTestController {
	static inline final HAXE_TESTS = "Haxe Tests";

	final context:ExtensionContext;
	final channel:OutputChannel;
	final controller:TestController;
	final dataWatcher:FileSystemWatcher;
	final workspaceFolder:WorkspaceFolder;
	var filter:TestFilter;
	var suiteResults:TestSuiteResults;
	var currentTask:Null<TaskExecution>;
	var currentRun:Null<TestRun>;
	var isCoverageRun:Bool;
	var delayForCoverageResults:Int;

	public function new(context:ExtensionContext, workspaceFolder:WorkspaceFolder) {
		this.context = context;
		this.workspaceFolder = workspaceFolder;

		delayForCoverageResults = getWaitForCoverage();

		channel = Vscode.window.createOutputChannel('${workspaceFolder.name} Tests');
		channel.appendLine('Starting test adapter for ${workspaceFolder.name}');

		controller = Vscode.tests.createTestController('haxe-test-controller-${workspaceFolder.name}', '${workspaceFolder.name} Tests');
		controller.createRunProfile('Run Tests for ${workspaceFolder.name}', vscode.TestRunProfileKind.Run, runHandler, true);
		controller.createRunProfile('Debug Tests for ${workspaceFolder.name}', vscode.TestRunProfileKind.Debug, debugHandler, false);

		if (isCoverageUIEnabled()) {
			final coverageProfile = controller.createRunProfile('Run Tests with Coverage for ${workspaceFolder.name}', vscode.TestRunProfileKind.Coverage,
				coverageHandler, true);

			coverageProfile.loadDetailedCoverage = loadDetailedCoverage;
			coverageProfile.loadDetailedCoverageForTest = loadDetailedCoverageForTest;
		}

		var pattern = new RelativePattern(workspaceFolder, "**/" + TestResults.getRelativeFileName());
		dataWatcher = Vscode.workspace.createFileSystemWatcher(pattern);
		dataWatcher.onDidCreate(onResultFile);
		dataWatcher.onDidChange(onResultFile);

		filter = new TestFilter(workspaceFolder.uri.fsPath);
		Vscode.tasks.onDidEndTask(testTaskEnded);
		Vscode.debug.onDidTerminateDebugSession(testDebugEnd);

		currentRun = controller.createTestRun(new TestRunRequest(), HAXE_TESTS);
		loadFrom(workspaceFolder.uri.path);
	}

	function runHandler(request:TestRunRequest, token:CancellationToken):Thenable<Void> {
		if (currentRun != null) {
			return Promise.reject("tests already running");
		}
		channel.appendLine("start running Tests");
		token.onCancellationRequested((e) -> cancel());

		isCoverageRun = false;
		currentRun = controller.createTestRun(request, HAXE_TESTS);
		setFilters(request);
		setAllStarted(controller.items);

		var vshaxe:Vshaxe = Vscode.extensions.getExtension("nadako.vshaxe").exports;
		var haxeExecutable = vshaxe.haxeExecutable.configuration;

		var testCommand:Null<Array<String>> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("testCommand");
		if (testCommand == null) {
			return Promise.reject("please set \"haxeTestExplorer.coverageCommand\" in settings.json");
		}
		testCommand = testCommand.map(arg -> if (arg == "${haxe}") haxeExecutable.executable else arg);

		var task = new Task({type: "haxe-test-explorer-run"}, workspaceFolder, "Running Haxe Tests", "haxe",
			new ProcessExecution(testCommand.shift(), testCommand, {env: haxeExecutable.env}), cast vshaxe.problemMatchers);
		var presentation = vshaxe.taskPresentation;
		task.presentationOptions = {
			reveal: presentation.reveal,
			echo: presentation.echo,
			focus: presentation.focus,
			panel: presentation.panel,
			showReuseMessage: presentation.showReuseMessage,
			clear: presentation.clear
		};

		var thenable:Thenable<TaskExecution> = Vscode.tasks.executeTask(task);
		return thenable.then(function(taskExecution:TaskExecution) {
			currentTask = taskExecution;
		}, taskLaunchError);
	}

	function coverageHandler(request:TestRunRequest, token:CancellationToken):Thenable<Void> {
		if (currentRun != null) {
			return Promise.reject("tests already running");
		}
		var testCommand:Null<Array<String>> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("coverageCommand");
		if (testCommand == null) {
			channel.appendLine("please set \"haxeTestExplorer.coverageCommand\" in settings.json");
			return Promise.reject("please set \"haxeTestExplorer.coverageCommand\" in settings.json");
		}

		channel.appendLine("start running Tests (with coveraqge)");
		token.onCancellationRequested((e) -> cancel());

		isCoverageRun = true;
		currentRun = controller.createTestRun(request, HAXE_TESTS);
		setFilters(request);
		setAllStarted(controller.items);

		var vshaxe:Vshaxe = Vscode.extensions.getExtension("nadako.vshaxe").exports;
		var haxeExecutable = vshaxe.haxeExecutable.configuration;

		testCommand = testCommand.map(arg -> if (arg == "${haxe}") haxeExecutable.executable else arg);

		var task = new Task({type: "haxe-test-explorer-run"}, workspaceFolder, "Running Haxe Tests with Coverage", "haxe",
			new ProcessExecution(testCommand.shift(), testCommand, {env: haxeExecutable.env}), cast vshaxe.problemMatchers);
		var presentation = vshaxe.taskPresentation;
		task.presentationOptions = {
			reveal: presentation.reveal,
			echo: presentation.echo,
			focus: presentation.focus,
			panel: presentation.panel,
			showReuseMessage: presentation.showReuseMessage,
			clear: presentation.clear
		};

		var thenable:Thenable<TaskExecution> = Vscode.tasks.executeTask(task);
		return thenable.then(function(taskExecution:TaskExecution) {
			currentTask = taskExecution;
			try {
				FileSystem.deleteFile(getInstumentFullCoveragePath());
			} catch (e) {
				// ignore delete error
			}
		}, taskLaunchError);
	}

	function debugHandler(request:TestRunRequest, token:CancellationToken):Thenable<Void> {
		channel.appendLine("start debugging Tests");
		token.onCancellationRequested((e) -> cancel());

		isCoverageRun = false;
		currentRun = controller.createTestRun(request, HAXE_TESTS);
		setFilters(request);
		setAllStarted(controller.items);

		var launchConfig = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("launchConfiguration");
		if (launchConfig == null) {
			return Promise.reject("please set \"haxeTestExplorer.launchConfiguration\" in settings.json");
		}
		var thenable:Thenable<Bool> = Vscode.debug.startDebugging(workspaceFolder, launchConfig);
		return thenable.then(function(b:Bool) {}, taskLaunchError);
	}

	function taskLaunchError(error) {
		channel.appendLine('Running tests for ${workspaceFolder.name} failed with $error');
		currentRun.appendOutput('Running tests for ${workspaceFolder.name} failed with $error');
		currentRun.end();
		currentRun = null;
	}

	function setFilters(request:TestRunRequest) {
		var include:Array<String> = [];
		var exclude:Array<String> = [];
		if (request.include != null) {
			include = request.include.map(f -> f.id);
		}
		if (request.exclude != null) {
			exclude = request.exclude.map(f -> f.id);
		}
		filter.set(include, exclude);
		channel.appendLine('include: [${include.join(", ")}] - exclude: [${exclude.join(", ")}]');
	}

	@:access(_testadapter.data.TestFilter)
	function setAllStarted(collection:TestItemCollection) {
		if (collection == null) {
			return;
		}
		var filters:TestFilterList = filter.testFilters;
		collection.forEach((item, col) -> {
			setAllStarted(item.children);
			if (filters.include.length > 0) {
				var found = false;
				for (id in filters.include) {
					if (id == item.id) {
						found = true;
						break;
					}
					if (item.id.startsWith('$id.')) {
						found = true;
						break;
					}
				}
				if (!found) {
					return null;
				}
			}
			if (filters.exclude.contains(item.id)) {
				return null;
			}
			currentRun.started(item);
			return null;
		});
	}

	function testTaskEnded(event:TaskEndEvent) {
		if ((currentTask == null) || Json.stringify(event.execution.task.definition) != Json.stringify(currentTask.task.definition)) {
			return;
		}
		loadFrom(workspaceFolder.uri.path);
		channel.appendLine('Running tests for ${workspaceFolder.name} finished');
		currentTask = null;
	}

	function testDebugEnd(session:DebugSession) {
		if (currentRun != null) {
			channel.appendLine('Debugging tests for ${workspaceFolder.name} finished');
			currentRun.end();
		}
		currentRun = null;
		currentTask = null;
	}

	function cancel() {
		if (currentRun != null) {
			currentRun.end();
		}
		currentRun = null;
		channel.appendLine('Test run for ${workspaceFolder.name} cancelled');
		Vscode.debug.stopDebugging();
		if (currentTask != null) {
			currentTask.terminate();
		}
		currentTask = null;
	}

	function onResultFile(uri:Uri) {
		if (currentRun == null) {
			currentRun = controller.createTestRun(new TestRunRequest(), HAXE_TESTS);
		}
		var unitTestFolder = Path.directory(uri.fsPath);
		var baseFolder = Path.directory(unitTestFolder);
		if (isCoverageRun) {
			Timer.delay(() -> loadFrom(baseFolder), delayForCoverageResults);
		} else {
			loadFrom(baseFolder);
		}
	}

	function loadFrom(baseFolder:String) {
		if (currentRun == null) {
			return;
		}
		filter = new TestFilter(baseFolder);
		suiteResults = TestResults.load(baseFolder);
		if (suiteResults == null) {
			currentRun.appendOutput("No tests results found!");
			currentRun.end();
			currentRun = null;
			return;
		}

		parseSuiteData(baseFolder, suiteResults);
		currentRun.appendOutput("Loaded tests results");
		currentRun.end();
		currentRun = null;
		channel.appendLine("Loaded tests results");
	}

	function makeFileName(baseFolder:String, file:String):String {
		var fileName:String = Path.join([baseFolder, file]);
		// it seems Test Explorer UI wants backslashes on Windows
		if (Sys.systemName() == "Windows") {
			fileName = fileName.replace("/", "\\");
		}
		return fileName;
	}

	function parseSuiteData(baseFolder:String, testSuiteResults:TestSuiteResults) {
		var key:String = testSuiteResults.name + ":" + workspaceFolder.name;
		var root:TestItem = controller.items.get(key);
		if (root == null) {
			root = controller.createTestItem(key, workspaceFolder.name);
			controller.items.add(root);
		}

		function sortByLine(a:{line:Null<Int>}, b:{line:Null<Int>}) {
			if (a.line == null || b.line == null) {
				return 0;
			}
			return a.line - b.line;
		}

		var classes = testSuiteResults.classes;
		ArraySort.sort(classes, (a, b) -> {
			if (a.pos == null || b.pos == null) {
				return 0;
			}
			if (a.pos.file != b.pos.file) {
				return Reflect.compare(a.pos.file, b.pos.file);
			}
			return sortByLine(a.pos, b.pos);
		});

		var testItems:Array<TestItemData> = [];
		for (clazz in classes) {
			var clazzUri:Uri = Uri.file(makeFileName(baseFolder, clazz.pos.file));
			var classItem:TestItem = controller.createTestItem(clazz.id, clazz.name, clazzUri);

			if (clazz.pos != null && clazz.pos.file != null && clazz.pos.line != null && clazz.pos.line != 0) {
				classItem.range = new Range(clazz.pos.line, 0, clazz.pos.line, 0);
			}
			ArraySort.sort(clazz.methods, sortByLine);
			for (test in clazz.methods) {
				var testItem:TestItem = controller.createTestItem(clazz.id + "." + test.name, test.name, clazzUri);
				if (clazz.pos != null && test.line != null && clazz.pos.file != null) {
					testItem.range = new Range(test.line, 0, test.line, 0);
				}
				classItem.children.add(testItem);
				testItems.push({
					test: test,
					testItem: testItem,
					clazzUri: clazzUri
				});
			}
			insertTestSuite(root, classItem);
		}
		for (item in testItems) {
			updateTestState(item.test, item.testItem, item.clazzUri);
		}
		final currentTestItems = testItems.map(f -> f.testItem);
		if (isCoverageUIEnabled() && isCoverageRun) {
			updateTestCoverage(currentTestItems);
		}
	}

	function insertTestSuite(root:TestItem, newItem:TestItem) {
		var pack:Array<String> = newItem.label.split(".");
		var id:Null<String> = null;
		var label:Null<String> = pack.pop();
		if (label == null) {
			root.children.add(newItem);
			return;
		}
		newItem.label = label;
		for (p in pack) {
			var found:Bool = false;
			root.children.forEach((child, collection) -> {
				if (found) {
					return null;
				}
				if (child.label == p) {
					root = child;
					found = true;
				}
				return null;
			});
			if (id == null) {
				id = p;
			} else {
				id += '.$p';
			}
			if (!found) {
				var packItem:TestItem = controller.createTestItem(id, p);
				root.children.add(packItem);
				root = packItem;
			}
		}
		root.children.add(newItem);
	}

	function updateTestState(test:TestMethodResults, testItem:TestItem, clazzUri:Uri) {
		switch (test.state) {
			case Success:
				if (test.executionTime == null) {
					currentRun.passed(testItem);
				} else {
					currentRun.passed(testItem, test.executionTime);
				}
			case Failure:
				var msg = buildFailureMessage(test);
				var line:Int = test.line;
				if (test.errorPos != null) {
					line = test.errorPos.line;
					clazzUri = Uri.file(makeFileName(workspaceFolder.uri.path, test.errorPos.file));
				}
				msg.location = new Location(clazzUri, new Range(line, 0, line + 1, 0));
				if (test.executionTime == null) {
					currentRun.failed(testItem, msg);
				} else {
					currentRun.failed(testItem, msg, test.executionTime);
				}
			case Error:
				var msg:TestMessage = new TestMessage(test.message);
				msg.location = new Location(clazzUri, new Range(test.line, 0, test.line + 1, 0));
				if (test.executionTime == null) {
					currentRun.errored(testItem, msg);
				} else {
					currentRun.errored(testItem, msg, test.executionTime);
				}
			case Ignore:
				currentRun.skipped(testItem);
		}
	}

	function buildFailureMessage(test:TestMethodResults):TestMessage {
		var msg:TestMessage = new TestMessage(test.message);
		// utest diff format
		var reg:EReg = ~/^expected "(.*)" but it is "(.*)"$/s;
		if (reg.match(test.message)) {
			msg = TestMessage.diff(test.message, reg.matched(1), reg.matched(2));
		}
		reg = ~/^expected (.*) but it is (.*)$/s;
		if (reg.match(test.message)) {
			msg = TestMessage.diff(test.message, reg.matched(1), reg.matched(2));
		}
		// munit diff format
		reg = ~/^Value \[(.*)\] was not equal to expected value \[(.*)\]$/s;
		if (reg.match(test.message)) {
			msg = TestMessage.diff(test.message, reg.matched(2), reg.matched(1));
		}
		// buddy diff format
		reg = ~/^Expected "(.*)", was "(.*)"$/s;
		if (reg.match(test.message)) {
			msg = TestMessage.diff(test.message, reg.matched(1), reg.matched(2));
		}
		// haxeunit + hexunit diff format
		reg = ~/[eE]xpected '(.*)' but was '(.*)'$/s;
		if (reg.match(test.message)) {
			msg = TestMessage.diff(test.message, reg.matched(1), reg.matched(2));
		}
		return msg;
	}

	function updateTestCoverage(currentTestItems:Array<TestItem>) {
		if (currentRun == null) {
			return;
		}
		if (currentTestItems.length <= 0) {
			return;
		}
		channel.appendLine("updateTestCoverage");

		var filteredTestItems:Null<Array<TestItem>> = null;
		if (isAttributableCoverageEnabled()) {
			filteredTestItems = [];
			for (item in currentTestItems) {
				final lcovFilename = makeFileName(workspaceFolder.uri.path, Path.join([Data.FOLDER, fileNameFormTestId(item.id) + ".lcov"]));

				if (FileSystem.exists(lcovFilename)) {
					filteredTestItems.push(item);
				}
			}
			if (filteredTestItems.length <= 0) {
				filteredTestItems = null;
			}
		}
		updateCoverageView(filteredTestItems, getFullCoveragePath());
		// 		for (item in filteredTestItems) {
		// 			final lcovFilename = makeFileName(workspaceFolder.uri.path, Path.join([Data.FOLDER, item.id + ".lcov"]));
		//
		// 			updateTestCoverageExtract([item], lcovFilename);
		// 		}
	}

	function updateCoverageView(filteredTestItems:Null<Array<TestItem>>, lcovPath:String) {
		if (!FileSystem.exists(lcovPath)) {
			return;
		}
		switch (Report.parse(File.getContent(lcovPath))) {
			case Failure(failure):
				channel.appendLine("failed to parse LCOV data: " + failure);
			case Success(data):
				for (file in data.sourceFiles) {
					var statementCoverage:TestCoverageCount = new TestCoverageCount(file.lines.hit, file.lines.found);
					var branchCoverage:TestCoverageCount = new TestCoverageCount(file.branches.hit, file.branches.found);
					var functionCoverage:TestCoverageCount = new TestCoverageCount(file.functions.hit, file.functions.found);
					var fileName = if (file.path.startsWith(workspaceFolder.uri.path)) {
						makeFileName(null, file.path);
					} else {
						makeFileName(workspaceFolder.uri.path, file.path);
					};

					if (filteredTestItems == null) {
						currentRun.addCoverage(new FileCoverage(Uri.parse(fileName), statementCoverage, branchCoverage, functionCoverage));
					} else {
						currentRun.addCoverage(new FileCoverage(Uri.parse(fileName), statementCoverage, branchCoverage, functionCoverage, filteredTestItems));
					}
				}
		}
	}

	function loadDetailedCoverage(testRun:TestRun, fileCoverage:FileCoverage, token:CancellationToken):Thenable<Array<FileCoverageDetail>> {
		return reportDetailedCoverage(getFullCoveragePath(), fileCoverage.uri.fsPath);
	}

	function loadDetailedCoverageForTest(testRun:TestRun, fileCoverage:FileCoverage, fromTestItem:TestItem,
			token:CancellationToken):Thenable<Array<FileCoverageDetail>> {
		final lcovFilename = makeFileName(workspaceFolder.uri.path, Path.join([Data.FOLDER, fileNameFormTestId(fromTestItem.id) + ".lcov"]));
		return reportDetailedCoverage(lcovFilename, fileCoverage.uri.fsPath);
	}

	function fileNameFormTestId(id:String):String {
		var regEx = ~/[^a-zA-Z0-9_.-]/g;
		return regEx.replace(id, "_");
	}

	function reportDetailedCoverage(lcovFileName:String, srcFileName:String):Thenable<Array<FileCoverageDetail>> {
		var details:Array<FileCoverageDetail> = [];

		if (!FileSystem.exists(lcovFileName)) {
			return Promise.reject("no coverage data found");
		}
		switch (Report.parse(File.getContent(lcovFileName))) {
			case Failure(failure):
				return Promise.reject(failure);
			case Success(data):
				for (file in data.sourceFiles) {
					var fileName = if (file.path.startsWith(workspaceFolder.uri.path)) {
						makeFileName(null, file.path);
					} else {
						makeFileName(workspaceFolder.uri.path, file.path);
					};
					if (fileName != srcFileName) {
						continue;
					}

					for (func in file.functions.data) {
						final coverageDetail = new DeclarationCoverage(func.functionName, func.executionCount > 0 ? func.executionCount : false,
							new Position(func.lineNumber - 1, 0));
						details.push(coverageDetail);
					}
					var branches:Array<BranchCoverage> = [];
					var block:Int = -1;
					for (branch in file.branches.data) {
						if (branch.blockNumber != block) {
							block = branch.blockNumber;
							branches = [];
							final coverageDetail = new StatementCoverage(branch.taken > 0 ? branch.taken : false, new Position(branch.lineNumber - 1, 0),
								branches);
							details.push(coverageDetail);
						}
						branches.push(new BranchCoverage(branch.taken > 0 ? branch.taken : false, new Position(branch.lineNumber - 1, 0)));
					}
					for (line in file.lines.data) {
						final coverageDetail = new StatementCoverage(line.executionCount > 0 ? line.executionCount : false,
							new Position(line.lineNumber - 1, 0));
						details.push(coverageDetail);
					}
				}
		}

		return Promise.resolve(details);
	}

	function isCoverageUIEnabled():Bool {
		var coverageUIEnabled:Null<Bool> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("enableCoverageUI");
		if (coverageUIEnabled == null) {
			return true;
		}
		return coverageUIEnabled;
	}

	function isAttributableCoverageEnabled():Bool {
		var attributableCoverageEnabled:Null<Bool> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("enableAttributableCoverage");
		if (attributableCoverageEnabled == null) {
			return true;
		}
		return attributableCoverageEnabled;
	}

	function getWaitForCoverage():Int {
		var waitForCoverage:Null<Int> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("waitForCoverage");
		if (waitForCoverage == null) {
			return 2000;
		}
		return waitForCoverage;
	}

	function getFullCoveragePath():String {
		final path = getInstumentFullCoveragePath();
		if (FileSystem.exists(path)) {
			return path;
		}
		var lcovPath:Null<String> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("lcovPath");
		if (lcovPath == null) {
			lcovPath = "lcov.info";
		}
		return makeFileName(workspaceFolder.uri.path, lcovPath);
	}

	function getInstumentFullCoveragePath():String {
		return makeFileName(workspaceFolder.uri.path, Path.join([Data.FOLDER, "lcov.info"]));
	}

	static function updateHaxelib(context:ExtensionContext) {
		Vscode.commands.registerCommand("haxeTestExplorer.setup", function() {
			var terminal = Vscode.window.createTerminal();
			terminal.sendText("haxelib dev test-adapter \"" + context.asAbsolutePath("test-adapter") + "\"");
			terminal.show();
			context.globalState.update("previousExtensionPath", context.extensionPath);
		});

		if (isExtensionPathChanged(context)) {
			Vscode.commands.executeCommand("haxeTestExplorer.setup");
		}
	}

	static function isExtensionPathChanged(context:ExtensionContext):Bool {
		var previousPath = context.globalState.get("previousExtensionPath");
		return (context.extensionPath != previousPath);
	}

	@:expose("activate")
	static function main(context:ExtensionContext) {
		for (folder in Vscode.workspace.workspaceFolders) {
			new HaxeTestController(context, folder);
		}
		updateHaxelib(context);
	}
}
