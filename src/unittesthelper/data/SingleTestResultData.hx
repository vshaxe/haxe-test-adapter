package unittesthelper.data;

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
