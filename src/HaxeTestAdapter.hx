import vscode.ShellExecution;
import vscode.TaskExecution;
import vscode.Task;
import haxe.io.Path;
import js.Object;
import js.Promise;
import testadapter.data.SuiteTestResultData;
import testadapter.data.TestFilter;
import testadapter.data.TestResultData;
import vscode.EventEmitter;
import vscode.Event;
import vscode.FileSystemWatcher;
import vscode.OutputChannel;
import vscode.Uri;
import vscode.WorkspaceFolder;
import vscode.testadapter.api.data.TestInfo;
import vscode.testadapter.api.data.TestState;
import vscode.testadapter.api.data.TestSuiteInfo;
import vscode.testadapter.api.event.TestLoadEvent;
import vscode.testadapter.api.event.TestEvent;
import vscode.testadapter.util.Log;

class HaxeTestAdapter {
	public final workspaceFolder:WorkspaceFolder;

	final testsEmitter:EventEmitter<TestLoadEvent>;
	final testStatesEmitter:EventEmitter<TestEvent>;
	final autorunEmitter:EventEmitter<Void>;
	final channel:OutputChannel;
	final log:Log;
	final dataWatcher:FileSystemWatcher;
	var suiteData:SuiteTestResultData;
	var partialSuiteData:SuiteTestResultData;
	var partialDataWatcher:FileSystemWatcher;

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
			get: function() {
				return testsEmitter.event;
			}
		});
		Object.defineProperty(this, "testStates", {
			get: function() {
				return testStatesEmitter.event;
			}
		});
		Object.defineProperty(this, "autorun", {
			get: function() {
				return autorunEmitter.event;
			}
		});

		var fileName:String = TestResultData.getTestDataFileName(workspaceFolder.uri.fsPath);
		dataWatcher = Vscode.workspace.createFileSystemWatcher(fileName, false, false, true);
		dataWatcher.onDidChange(function(uri:Uri) {
			load();
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
		suiteData = TestResultData.loadData(workspaceFolder.uri.fsPath);
		if (suiteData == null) {
			testsEmitter.fire({type: Finished, suite: null, errorMessage: "invalid test result data"});
			return null;
		}
		testsEmitter.fire({type: Finished, suite: parseSuiteData(suiteData)});
		channel.appendLine("Loaded tests results");
		update(suiteData);
		return Promise.resolve();
	}

	function parseSuiteData(suiteTestResultData:SuiteTestResultData):TestSuiteInfo {
		var suiteChilds:Array<TestSuiteInfo> = [];
		var suiteInfo:TestSuiteInfo = {
			type: "suite",
			label: suiteTestResultData.name,
			id: suiteTestResultData.name,
			children: suiteChilds
		};
		for (clazz in suiteTestResultData.classes) {
			var classChilds:Array<TestInfo> = [];
			var classInfo:TestSuiteInfo = {
				type: "suite",
				label: clazz.name,
				id: clazz.name,
				children: classChilds
			};
			for (test in clazz.tests) {
				var testInfo:TestInfo = {
					type: "test",
					id: clazz.name + "." + test.name,
					label: test.name,
				};
				if (test.file != null) {
					testInfo.file = Path.join([workspaceFolder.uri.fsPath, test.file]);
					testInfo.line = test.line;
				}
				classChilds.push(testInfo);
			}
			suiteChilds.push(classInfo);
		}
		return suiteInfo;
	}

	function update(suiteTestResultData:SuiteTestResultData) {
		if (suiteTestResultData == null) {
			return;
		}
		for (clazz in suiteTestResultData.classes) {
			for (test in clazz.tests) {
				var testState:TestState;
				switch (test.state) {
					case Success:
						testState = Passed;
					case Failure:
						testState = Failed;
					case Error:
						testState = Failed;
					case Ignore:
						testState = Skipped;
				}
				testStatesEmitter.fire({
					type: Test,
					test: clazz.name + "." + test.name,
					state: testState,
					message: test.errorText
				});
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

		var testArguments:Array<String> = Vscode.workspace.getConfiguration("haxetestadapter").get("testArguments");
		var command = [haxeExecutable.executable].concat(testArguments).concat(["-lib", "test-adapter"]);

		var task = new Task({type: "haxe-test-adapter-run"}, workspaceFolder, "Running Tests", "haxe",
			new ShellExecution(command.join(" "), {env: haxeExecutable.env}), vshaxe.problemMatchers.get());
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
		// TODO clear Filters after run
		return thenable.then(function(taskExecution:TaskExecution) {
			testStatesEmitter.fire({type: Finished});
			// TestFilter.clearTestFilter();
			channel.appendLine('Running tests ($tests) finished');
		}, function(error) {
			testStatesEmitter.fire({type: Finished});
			// TestFilter.clearTestFilter();
			channel.appendLine('Running tests ($tests) failed');
		});
	}

	/**
		Run the specified tests in the debugger.
		@param tests An array of test or suite IDs. For every suite ID, all tests in that suite are run.
		@returns A promise that is resolved when the test run is completed.
	**/
	public function debug(tests:Array<String>):Thenable<Void> {
		log.info("debug tests " + tests);
		channel.appendLine('Debug tests ($tests): not implemented!');
		return null;
	}

	/**
		Stop the current test run.
	**/
	public function cancel() {
		log.info("cancel tests");
		channel.appendLine("Cancel tests: not implemented!");
	}

	// TODO replace with getter
	public function tests():Event<TestLoadEvent> {
		return testsEmitter.event;
	}

	// TODO replace with getter
	public function testStates():Event<TestEvent> {
		return testStatesEmitter.event;
	}

	// TODO replace with getter
	public function autorun():Event<Void> {
		return autorunEmitter.event;
	}
}
