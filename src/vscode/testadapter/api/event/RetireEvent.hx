package vscode.testadapter.api.event;

typedef RetireEvent = {
	/** 
		An array of test or suite IDs. For every suite ID, all tests in that suite will be retired.
		If this isn't defined then all tests will be retired.
	**/
	var ?tests:Array<String>;
}
