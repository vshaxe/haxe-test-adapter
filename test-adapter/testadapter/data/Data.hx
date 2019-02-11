package testadapter.data;

typedef TestPos = {
	var location:String;
	var file:String;
	var line:Int;
}

typedef ClassTestResultData = {
	var name:String;
	var tests:Array<SingleTestResultData>;
	@:optional var pos:TestPos;
}

typedef SingleTestResultData = {
	var name:String;
	var location:String;
	var state:SingleTestResultState;
	var errorText:String;
	var executionTime:Float;
	var timestamp:Float;
	@:optional var line:Int;
	@:optional var file:String;
}

typedef SuiteTestResultData = {
	var name:String;
	var classes:Array<ClassTestResultData>;
}

@:enum abstract SingleTestResultState(String) {
	var Success = "OK";
	var Failure = "FAIL";
	var Error = "ERROR";
	var Ignore = "IGNORE";
}
