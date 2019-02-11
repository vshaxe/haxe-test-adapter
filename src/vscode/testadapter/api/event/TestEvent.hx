package vscode.testadapter.api.event;

import haxe.extern.EitherType;
import vscode.testadapter.api.data.TestDecoration;
import vscode.testadapter.api.data.TestInfo;
import vscode.testadapter.api.data.TestState;
import vscode.testadapter.api.data.TestSuiteInfo;
import vscode.testadapter.api.data.TestSuiteState;

/**
	Information about a test being started, completed or skipped during a test run.
**/
typedef TestEvent = {
	var type:TestEventType;

	/**
		The test(s) that will be run, this should be the same as the `tests` argument from the call
		to `run(tests)` or `debug(tests)` that started the test run.
	**/
	var ?tests:Array<String>;

	/**
		The test that is being started, completed or skipped. This field usually contains
		the ID of the test, but it may also contain the full information about a test that is
		started if that test had not been sent to the Test Explorer yet.
	**/
	var ?test:EitherType<String, TestInfo>;
	var ?state:EitherType<TestState, TestSuiteState>;
	var ?suite:EitherType<String, TestSuiteInfo>;

	/**
		This message will be displayed by the Test Explorer when the user selects the test.
		It is usually used for information about why a test has failed.
	**/
	var ?message:String;

	/**
		These messages will be shown as decorations for the given lines in the editor.
		They are usually used to show information about a test failure at the location of that failure.
	**/
	var ?decorations:Array<TestDecoration>;
}

enum abstract TestEventType(String) {
	var Started = "started";
	var Finished = "finished";
	var Suite = "suite";
	var Test = "test";
}
