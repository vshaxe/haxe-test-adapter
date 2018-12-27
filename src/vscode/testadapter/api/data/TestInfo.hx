package vscode.testadapter.api.data;

/**
	Information about a test.
**/
typedef TestInfo = {
	var type:String;
	var id:String;

	/** 
		The label to be displayed by the Test Explorer for this test.
	**/
	var label:String;

	/**
		The file containing this test (if known).
		This can either be an absolute path (if it is a local file) or a URI.
		Note that this should never contain a `file://` URI.
	**/
	@:optional var file:String;

	/** 
		The line within the specified file where the test definition starts (if known).
	**/
	@:optional var line:Int;

	/** 
		Indicates whether this test will be skipped during test runs
	**/
	@:optional var skipped:Bool;
}
