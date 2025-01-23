package _testadapter.data;

import haxe.Json;
import haxe.io.Path;
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
	var id:String;
	var name:String;
	var methods:Array<TestMethodResults>;
	@:optional var pos:Pos;
}

typedef TestMethodResults = {
	var name:String;
	var state:TestState;
	var message:String;
	var timestamp:Float;
	@:optional var executionTime:Null<Float>;
	@:optional var line:Int;
	@:optional var errorPos:Pos;
}

#if haxe4
enum abstract TestState(String) {
	var Success = "success";
	var Failure = "failure";
	var Error = "error";
	var Ignore = "ignore";
}
#else
@:enum abstract TestState(String) {
	var Success = "success";
	var Failure = "failure";
	var Error = "error";
	var Ignore = "ignore";
}
#end

typedef Pos = {
	var file:String;
	var line:Int;
}

enum SuiteIdentifier {
	ClassName(className:String);
	SuiteNameAndPos(name:String, fileName:String, lineNumber:Int);
	SuiteNameAndFile(name:String, fileName:String);
}

enum TestIdentifier {
	TestName(name:String);
	TestNameAndPos(name:String, fileName:String, lineNumber:Int);
}

abstract SuiteId(SuiteIdentifier) from SuiteIdentifier to SuiteIdentifier {
	@:to
	public function toString():String {
		#if buddy
		// buddy test hierarchies do not span multiple files, so they shouldn't be merged
		// putting file first makes sure filtering of buddy tests work for nested describe calls
		return switch (this) {
			case ClassName(className):
				className;
			case SuiteNameAndPos(name, fileName, lineNumber):
				'[$fileName:$lineNumber] $name';
			case SuiteNameAndFile(name, fileName):
				'[$fileName] $name';
		}
		#else
		return switch (this) {
			case ClassName(className):
				className;
			case SuiteNameAndPos(name, fileName, lineNumber):
				'$name [$fileName:$lineNumber]';
			case SuiteNameAndFile(name, fileName):
				'$name [$fileName]';
		}
		#end
	}
}

abstract LCOVFileName(String) from String {
	@:to
	public function toString():String {
		var regEx = ~/[^a-zA-Z0-9_.-]/g;
		return regEx.replace('${this}', "_");
	}
}
