package testadapter.data;

import haxe.Json;
import haxe.io.Path;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.File;
#end
#if !macro
import json2object.JsonParser;
#end
import testadapter.data.Data;

typedef ClassPosition = {
	tests:Map<String, Pos>,
	pos:Pos
};

typedef Positions = Map<String, ClassPosition>;

class TestPosCache {
	static inline var RESULT_FOLDER:String = ".unittest";
	static inline var POS_FILE:String = "positions.json";
	static var INSTANCE:TestPosCache = new TestPosCache();

	var positions:Positions;
	var loaded:Bool;

	function new() {
		positions = new Positions();
		loadCache();
	}

	public static function addPos(className:String, ?testName:String, pos:Pos) {
		if (testName == null) {
			INSTANCE.positions[className] = {tests: new Map<String, Pos>(), pos: pos};
		} else {
			INSTANCE.positions[className].tests[testName] = pos;
		}
		INSTANCE.saveCache();
	}

	public static function getPos(className:String, testName:String):Pos {
		if (!INSTANCE.loaded) {
			INSTANCE.loadCache();
		}
		var clazz = INSTANCE.positions[className];
		if (testName == null) {
			return clazz.pos;
		}
		return clazz.tests[testName];
	}

	function saveCache() {
		#if (sys || nodejs)
		var fileName:String = getTestPosFileName();
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
		}
		File.saveContent(fileName, Json.stringify(positions, null, "    "));
		#end
	}

	function loadCache() {
		#if (!macro && (sys || nodejs))
		var fileName:String = getTestPosFileName();
		if (!FileSystem.exists(fileName)) {
			return;
		}
		var content:String = File.getContent(fileName);

		var parser = new JsonParser<Positions>();
		positions = parser.fromJson(content, fileName);
		#end
	}

	public static function getTestPosFileName():String {
		return Path.join([RESULT_FOLDER, POS_FILE]);
	}
}
