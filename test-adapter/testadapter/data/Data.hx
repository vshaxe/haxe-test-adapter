package testadapter.data;

typedef TestSuiteResults = {
	var name:String;
	var classes:Array<TestClassResults>;
}

typedef TestClassResults = {
	var name:String;
	var tests:Array<TestResults>;
	@:optional var pos:Pos;
}

typedef TestResults = {
	var name:String;
	var state:TestState;
	var message:String;
	var executionTime:Float;
	var timestamp:Float;
	@:optional var line:Int;
	@:optional var errorLine:Int;
}

@:enum abstract TestState(String) {
	var Success = "success";
	var Failure = "failure";
	var Error = "error";
	var Ignore = "ignore";
}

typedef Pos = {
	var file:String;
	var line:Int;
}
