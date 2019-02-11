import haxe.ds.ArraySort;
import haxe.io.Path;
import js.Object;
import js.Promise;
import testadapter.data.Data;
import testadapter.data.TestFilter;
import testadapter.data.TestResultData;
import vscode.EventEmitter;
import vscode.FileSystemWatcher;
import vscode.OutputChannel;
import vscode.ProcessExecution;
import vscode.Task;
import vscode.TaskExecution;
import vscode.WorkspaceFolder;
import vscode.testadapter.api.data.TestInfo;
import vscode.testadapter.api.data.TestState;
import vscode.testadapter.api.data.TestSuiteInfo;
import vscode.testadapter.api.event.TestLoadEvent;
import vscode.testadapter.api.event.TestEvent;
import vscode.testadapter.util.Log;

using StringTools;

class HaxeTestAdapter {
	public final workspaceFolder:WorkspaceFolder;

	final testsEmitter:EventEmitter<TestLoadEvent>;
	final testStatesEmitter:EventEmitter<TestEvent>;
	final autorunEmitter:EventEmitter<Void>;
	final channel:OutputChannel;
	final log:Log;
	final dataWatcher:FileSystemWatcher;
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

		var fileName:String = TestResultData.getTestDataFileName(workspaceFolder.uri.fsPath);
		dataWatcher = Vscode.workspace.createFileSystemWatcher(fileName, false, false, true);
		dataWatcher.onDidCreate(_ -> load());
		dataWatcher.onDidChange(_ -> load());

		Vscode.tasks.onDidEndTask(event -> {
			if (event.execution == currentTask) {
				testStatesEmitter.fire({type: Finished});
				TestFilter.clearTestFilter();
				channel.appendLine('Running tests finished');
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
		testsEmitter.fire({type: Started});
		suiteResults = TestResultData.loadData(workspaceFolder.uri.fsPath);
		if (suiteResults == null) {
			testsEmitter.fire({type: Finished, suite: null, errorMessage: "invalid test result data"});
			return null;
		}
		testsEmitter.fire({type: Finished, suite: parseSuiteData(suiteResults)});
		channel.appendLine("Loaded tests results");
		update(suiteResults);
		return Promise.resolve();
	}

	function parseSuiteData(testSuiteResults:TestSuiteResults):TestSuiteInfo {
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
		for (clazz in classes) {
			var classChilds:Array<TestInfo> = [];
			var classInfo:TestSuiteInfo = {
				type: "suite",
				label: clazz.name,
				id: clazz.name,
				children: classChilds
			};
			ArraySort.sort(clazz.tests, sortByLine);
			for (test in clazz.tests) {
				var testInfo:TestInfo = {
					type: "test",
					id: clazz.name + "." + test.name,
					label: test.name,
				};
				if (clazz.pos != null && clazz.pos.file != null) {
					testInfo.file = Path.join([workspaceFolder.uri.fsPath, clazz.pos.file]);
					// it seems Test Explorer UI wants backslashes on Windows
					if (Sys.systemName() == "Windows") {
						testInfo.file = testInfo.file.replace("/", "\\");
					}
					testInfo.line = test.line;
				}
				classChilds.push(testInfo);
			}
			suiteChilds.push(classInfo);
		}
		return suiteInfo;
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
			for (test in clazz.tests) {
				var testState:TestState = switch (test.state) {
					case Success: Passed;
					case Failure: Failed;
					case Error: Errored;
					case Ignore: Skipped;
				}
				var event:TestEvent = {
					type: Test,
					test: clazz.name + "." + test.name,
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
		TestFilter.setTestFilter(workspaceFolder.uri.fsPath, tests);
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
			TestFilter.clearTestFilter();
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
		channel.appendLine('Debugging tests...');
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
