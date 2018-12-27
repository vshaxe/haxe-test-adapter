package vscode.testadapter.api.event;

import vscode.testadapter.api.data.TestSuiteInfo;

/**
	This event is sent by a Test Adapter when it starts or finished loading the test definitions.
**/
typedef TestLoadEvent = {
	var type:TestLoadEventType;

	/** 
		The test definitions that have just been loaded
	**/
	@:optional var suite:TestSuiteInfo;

	/** 
		If loading the tests failed, this should contain the reason for the failure
	**/
	@:optional var errorMessage:String;
}

@:enum abstract TestLoadEventType(String) {
	var Started = "started";
	var Finished = "finished";
}
