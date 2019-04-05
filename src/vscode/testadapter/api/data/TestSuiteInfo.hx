package vscode.testadapter.api.data;

import haxe.extern.EitherType;

/**
	Information about a test suite.
**/
typedef TestSuiteInfo = {
	var type:String;
	var id:String;

	/** 
		The label to be displayed by the Test Explorer for this suite.
	**/
	var label:String;

	/** 
		The description to be displayed next to the label.
	**/
	var ?description:String;

	/**
		The file containing this suite (if known).
		This can either be an absolute path (if it is a local file) or a URI.
		Note that this should never contain a `file://` URI.
	**/
	var ?file:String;

	/** 
		The line within the specified file where the suite definition starts (if known).
	**/
	var ?line:Int;
	var children:Array<EitherType<TestSuiteInfo, TestInfo>>;
}
