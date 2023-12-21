import haxe.Json;
import haxe.ds.ArraySort;
import haxe.io.Path;
import js.lib.Promise;
import vscode.OutputChannel;
import _testadapter.data.Data;
import _testadapter.data.TestFilter;
import _testadapter.data.TestResults;
import vscode.CancellationToken;
import vscode.DebugSession;
import vscode.ExtensionContext;
import vscode.FileSystemWatcher;
import vscode.Location;
import vscode.ProcessExecution;
import vscode.Range;
import vscode.RelativePattern;
import vscode.Task;
import vscode.TaskEndEvent;
import vscode.TaskExecution;
import vscode.TestController;
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

	public function new(context:ExtensionContext, workspaceFolder:WorkspaceFolder) {
		this.context = context;
		this.workspaceFolder = workspaceFolder;

		channel = Vscode.window.createOutputChannel('${workspaceFolder.name} Tests');
		channel.appendLine('Starting test adapter for ${workspaceFolder.name}');

		controller = Vscode.tests.createTestController('haxe-test-controller-${workspaceFolder.name}', '${workspaceFolder.name} Tests');
		controller.createRunProfile('Run Tests for ${workspaceFolder.name}', vscode.TestRunProfileKind.Run, runHandler, true);
		controller.createRunProfile('Debug Tests for ${workspaceFolder.name}', vscode.TestRunProfileKind.Debug, debugHandler, false);

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
			return Promise.reject();
		}
		channel.appendLine("start running Tests");
		token.onCancellationRequested((e) -> cancel());

		currentRun = controller.createTestRun(request, HAXE_TESTS);
		setFilters(request);
		setAllStarted(controller.items);

		var vshaxe:Vshaxe = Vscode.extensions.getExtension("nadako.vshaxe").exports;
		var haxeExecutable = vshaxe.haxeExecutable.configuration;

		var testCommand:Array<String> = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("testCommand");
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

	function debugHandler(request:TestRunRequest, token:CancellationToken):Thenable<Void> {
		channel.appendLine("start debugging Tests");
		token.onCancellationRequested((e) -> cancel());

		currentRun = controller.createTestRun(request, HAXE_TESTS);
		setFilters(request);
		setAllStarted(controller.items);

		var launchConfig = Vscode.workspace.getConfiguration("haxeTestExplorer", workspaceFolder).get("launchConfiguration");
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
	}

	function setAllStarted(collection:TestItemCollection) {
		if (collection == null) {
			return;
		}
		collection.forEach((item, col) -> {
			currentRun.started(item);
			setAllStarted(item.children);
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
		channel.appendLine('Debugging tests for ${workspaceFolder.name} finished');
		currentRun.end();
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
		loadFrom(baseFolder);
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
