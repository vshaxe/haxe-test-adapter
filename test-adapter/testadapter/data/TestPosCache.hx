package testadapter.data;

import haxe.Json;
import haxe.io.Path;
#if (sys || nodejs)
import sys.io.File;
import sys.FileSystem;
#end
#if !macro
import json2object.JsonParser;
#end

typedef TestPositions = Map<String, TestPos>;

class TestPosCache {
	public static inline var RESULT_FOLDER:String = ".unittest";
	public static inline var POS_FILE:String = "testPositions.json";
	static var INSTANCE:TestPosCache = new TestPosCache();

	var testPositions:TestPositions;
	var loaded:Bool;

	function new() {
		testPositions = new TestPositions();
		loadCache();
	}

	public static function addPos(testPos:TestPos) {
		INSTANCE.testPositions.set(testPos.location, testPos);
		INSTANCE.saveCache();
	}

	public static function getPos(location:String):TestPos {
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
