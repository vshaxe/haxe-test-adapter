import haxe.Json;
import haxe.ds.ArraySort;
import haxe.io.Path;
import js.lib.Object;
import js.lib.Promise;
import _testadapter.data.Data;
import _testadapter.data.TestFilter;
import _testadapter.data.TestResults;
import vscode.EventEmitter;
import vscode.FileSystemWatcher;
import vscode.OutputChannel;
import vscode.ProcessExecution;
import vscode.RelativePattern;
import vscode.Task;
import vscode.TaskExecution;
import vscode.Uri;
import vscode.WorkspaceFolder;
import vscode.testadapter.api.data.TestInfo;
import vscode.testadapter.api.data.TestState;
import vscode.testadapter.api.data.TestSuiteInfo;
import vscode.testadapter.api.event.RetireEvent;
import vscode.testadapter.api.event.TestEvent;
import vscode.testadapter.api.event.TestLoadEvent;
import vscode.testadapter.util.Log;

using StringTools;

class HaxeTestAdapter {
	public final workspaceFolder:WorkspaceFolder;

	final testsEmitter:EventEmitter<TestLoadEvent>;
	final testStatesEmitter:EventEmitter<TestEvent>;
	final autorunEmitter:EventEmitter<Void>;
	final retireEmitter:EventEmitter<RetireEvent>;
	final channel:OutputChannel;
	final log:Log;
	final dataWatcher:FileSystemWatcher;
	var filter:TestFilter;
	var suiteResults:TestSuiteResults;
	var currentTask:Null<TaskExecution>;

	public function new(workspaceFolder:WorkspaceFolder, channel:OutputChannel, log:Log) {
		this.workspaceFolder = workspaceFolder;
		this.channel = channel;
		this.log = log;

		channel.appendLine('Starting test adapter for ${workspaceFolder.name}');

		testsEmitter = new EventEmitter<TestLoadEvent>();
		testStatesEmitter = new EventEmitter<TestEvent>();
		autorunEmitter = new EventEmitter<Void>();
		retireEmitter = new EventEmitter<RetireEvent>();

		// TODO is there a better way to make getters??
		Object.defineProperty(this, "tests", {
			get: () -> testsEmitter.event
		});
		Object.defineProperty(this, "testStates", {
			get: () -> testStatesEmitter.event
		});
		Object.defineProperty(this, "autorun", {
			get: () -> autorunEmitter.event
		});
		Object.defineProperty(this, "retire", {
			get: () -> retireEmitter.event
		});

		var pattern = new RelativePattern(workspaceFolder, "**/" + TestResults.getRelativeFileName());
		dataWatcher = Vscode.workspace.createFileSystemWatcher(pattern);
		dataWatcher.onDidCreate(onResultFile);
		dataWatcher.onDidChange(onResultFile);

		filter = new TestFilter(workspaceFolder.uri.fsPath);

		Vscode.tasks.onDidEndTask(event -> {
			if (Json.stringify(event.execution.task.definition) == Json.stringify(currentTask.task.definition)) {
				testStatesEmitter.fire({type: Finished});
				channel.appendLine("Running tests finished");
				currentTask = null;
			}
		});
	}

	/**
		Start loading the definitions of tests and test suites.
		Note that the Test Adapter should also watch source files and the configuration for changes and
		automatically reload the test definitions if necessary (without waiting for a call to this method).
		@returns A promise that is resolved when the adapter finished loading the test definitions.
	**/
	public function load():Thenable<Void> {
		loadFrom(workspaceFolder.uri.fsPath);
		return Promise.resolve();
	}

	function onResultFile(uri:Uri) {
		// TODO: combine results if there's multiple .unittest dirs in the workspace?
		var unitTestFolder = Path.directory(uri.fsPath);
		var baseFolder = Path.directory(unitTestFolder);
		loadFrom(baseFolder);
	}

	function loadFrom(baseFolder:String) {
		testsEmitter.fire({type: Started});

		filter = new TestFilter(baseFolder);
		suiteResults = TestResults.load(baseFolder);
		if (suiteResults == null) {
			testsEmitter.fire({type: Finished, suite: null, errorMessage: "invalid test result data"});
			return;
		}

		testsEmitter.fire({type: Finished, suite: parseSuiteData(baseFolder, suiteResults)});
		channel.appendLine("Loaded tests results");
		update(suiteResults);
	}

	function parseSuiteData(baseFolder:String, testSuiteResults:TestSuiteResults):TestSuiteInfo {
		var suiteChilds:Array<TestSuiteInfo> = [];
		var suiteInfo:TestSuiteInfo = {
			type: "suite",
			label: testSuiteResults.name,
			id: testSuiteResults.name,
			children: suiteChilds
		};
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

		function makeFileName(file:String):String {
			var fileName:String = Path.join([baseFolder, file]);
			// it seems Test Explorer UI wants backslashes on Windows
			if (Sys.systemName() == "Windows") {
				fileName = fileName.replace("/", "\\");
			}
			return fileName;
		}

		for (clazz in classes) {
			var classChilds:Array<TestInfo> = [];
			var classInfo:TestSuiteInfo = {
				type: "suite",
				label: clazz.name,
				id: clazz.id,
				children: classChilds
			};
			if (clazz.pos != null && clazz.pos.file != null && clazz.pos.line != 0) {
				classInfo.file = makeFileName(clazz.pos.file);
				classInfo.line = clazz.pos.line;
			}
			ArraySort.sort(clazz.methods, sortByLine);
			for (test in clazz.methods) {
				var testInfo:TestInfo = {
					type: "test",
					id: clazz.id + "." + test.name,
					label: test.name,
				};
				if (clazz.pos != null && clazz.pos.file != null) {
					testInfo.file = makeFileName(clazz.pos.file);
					testInfo.line = test.line;
				}
				classChilds.push(testInfo);
			}
			insertTestSuite(suiteInfo, classInfo);
		}
		return suiteInfo;
	}

	function insertTestSuite(root:TestSuiteInfo, newSuiteInfo:TestSuiteInfo) {
		var pack:Array<String> = newSuiteInfo.label.split(".");

		var id:Null<String> = null;
		var label:Null<String> = pack.pop();
		if (label == null) {
			root.children.push(newSuiteInfo);
			return;
		}
		newSuiteInfo.label = label;
		for (p in pack) {
			var found:Bool = false;
			var children:Array<TestSuiteInfo> = root.children;
			for (child in children) {
				if (child.label == p) {
					root = child;
					found = true;
					break;
				}
			}
			if (id == null) {
				id = p;
			} else {
				id += '.$p';
			}
			if (!found) {
				var suiteInfo:TestSuiteInfo = {
					type: "suite",
					label: p,
					id: id,
					children: []
				};
				root.children.push(suiteInfo);
				root = suiteInfo;
			}
		}
		root.children.push(newSuiteInfo);
	}

	function sortByLine(a:{line:Null<Int>}, b:{line:Null<Int>}) {
		if (a.line == null || b.line == null) {
			return 0;
		}
		return a.line - b.line;
	}

	function update(testSuiteResults:Null<TestSuiteResults>) {
		if (testSuiteResults == null) {
			return;
		}
		for (clazz in testSuiteResults.classes) {
			for (test in clazz.methods) {
				var testState:TestState = switch (test.state) {
					case Success: Passed;
					case Failure: Failed;
					case Error: Errored;
					case Ignore: Skipped;
				}
				var event:TestEvent = {
					type: Test,
					test: clazz.id + "." + test.name,
					state: testState,
					message: test.message
				};
				if (test.message != null) {
					event.message = test.message;
					if (test.errorLine != null) {
						event.decorations = [{
							line: test.errorLine,
							message: event.message
						}];
					}
				}
				testStatesEmitter.fire(event);
			}
		}
	}

	/**
		Run the specified tests.
		@param tests An array of test or suite IDs. For every suite ID, all tests in that suite are run.
		@returns A promise that is resolved when the test run is completed.
	**/
	public function run(tests:Array<String>):Thenable<Void> {
		log.info("run tests " + tests);
		channel.appendLine('Running tests ($tests)');
		filter.set(tests);
		testStatesEmitter.fire({type: Started, tests: tests});

		var vshaxe:Vshaxe = Vscode.extensions.getExtension("nadako.vshaxe").exports;
		var haxeExecutable = vshaxe.haxeExecutable.configuration;

		var testCommand:Array<String> = Vscode.workspace.getConfiguration("haxeTestExplorer").get("testCommand");
		testCommand = testCommand.map(arg -> if (arg == "${haxe}") haxeExecutable.executable else arg);

		var task = new Task({type: "haxe-test-explorer-run"}, workspaceFolder, "Running Tests", "haxe",
			new ProcessExecution(testCommand.shift(), testCommand, {env: haxeExecutable.env}), vshaxe.problemMatchers.get());
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
		}, function(error) {
			testStatesEmitter.fire({type: Finished});
			channel.appendLine('Running tests ($tests) failed with ' + error);
		});
	}

	/**
		Run the specified tests in the debugger.
		@param tests An array of test or suite IDs. For every suite ID, all tests in that suite are run.
		@returns A promise that is resolved when the test run is completed.
	**/
	public function debug(tests:Array<String>):Thenable<Void> {
		log.info("debug tests " + tests);
		channel.appendLine("Debugging tests...");
		filter.set(tests);

		var launchConfig = Vscode.workspace.getConfiguration("haxeTestExplorer").get("launchConfiguration");
		return cast Vscode.debug.startDebugging(workspaceFolder, launchConfig);
	}

	/**
		Stop the current test run.
	**/
	public function cancel() {
		if (currentTask != null) {
			log.info("cancel tests");
			channel.appendLine("Test execution canceled.");
			currentTask.terminate();
		} else {
			channel.append("No Tests to cancel.");
		}
	}
}
