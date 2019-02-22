package _testadapter.data;

import haxe.io.Path;
import haxe.Json;
#if (sys || hxnodejs)
import sys.FileSystem;
import sys.io.File;
#end

class Data {
	public static inline var FOLDER = ".unittest";

	public static function save(path:String, content:Any) {
		#if (sys || hxnodejs)
		var directory = Path.directory(path);
		if (!FileSystem.exists(directory)) {
			FileSystem.createDirectory(directory);
		}
		File.saveContent(path, Json.stringify(content, "\t"));
		#end
	}

	public static function clear(path:String) {
		#if (sys || hxnodejs)
		if (FileSystem.exists(path)) {
			FileSystem.deleteFile(path);
		}
		#end
	}
}

typedef TestSuiteResults = {
	var name:String;
	var classes:Array<TestClassResults>;
}

typedef TestClassResults = {
	var name:String;
	var methods:Array<TestMethodResults>;
	@:optional var pos:Pos;
}

typedef TestMethodResults = {
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
