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

typedef TestPositions = Map<String, Pos>;

class TestPosCache {
	static inline var RESULT_FOLDER:String = ".unittest";
	static inline var POS_FILE:String = "positions.json";
	static var INSTANCE = new TestPosCache();

	var testPositions:TestPositions;
	var loaded:Bool;

	function new() {
		testPositions = new TestPositions();
		loadCache();
	}

	public static function addPos(pos:Pos) {
		INSTANCE.testPositions.set(pos.location, pos);
		INSTANCE.saveCache();
	}

	public static function getPos(location:String):Pos {
		if (!INSTANCE.loaded) {
			INSTANCE.loadCache();
		}
		return INSTANCE.testPositions.get(location);
	}

	function saveCache() {
		#if (sys || nodejs)
		var fileName:String = getTestPosFileName();
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
		}
		File.saveContent(fileName, Json.stringify(testPositions, null, "    "));
		#end
	}

	function loadCache() {
		#if (!macro && (sys || nodejs))
		var fileName:String = getTestPosFileName();
		if (!FileSystem.exists(fileName)) {
			return;
		}
		var content:String = File.getContent(fileName);

		var parser:JsonParser<TestPositions> = new JsonParser<TestPositions>();
		testPositions = parser.fromJson(content, fileName);
		#end
	}

	public static function getTestPosFileName():String {
		return Path.join([RESULT_FOLDER, POS_FILE]);
	}
}
