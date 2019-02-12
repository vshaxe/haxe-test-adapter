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
	tests:Map<String, {line:Int}>,
	pos:Pos
};

typedef Positions = Map<String, ClassPosition>;

class TestPosCache {
	static inline var RESULT_FOLDER:String = ".unittest";
	static inline var POS_FILE:String = "positions.json";

	var baseFolder:String;
	var positions:Positions;
	var loaded:Bool;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		positions = new Positions();
		load();
	}

	public function add(className:String, ?testName:String, pos:Pos) {
		if (testName == null) {
			positions[className] = {tests: new Map<String, {line:Int}>(), pos: pos};
		} else {
			positions[className].tests[testName] = {line: pos.line};
		}
		save();
	}

	public function get(className:String, testName:String):Pos {
		if (!loaded) {
			load();
		}
		var clazz = positions[className];
		if ((clazz == null) || (clazz.pos == null) || (clazz.tests == null)) {
			return null;
		}
		if (testName == null) {
			return clazz.pos;
		}
		if (clazz.tests[testName] == null) {
			return clazz.pos;
		}
		return {
			file: clazz.pos.file,
			line: clazz.tests[testName].line
		};
	}

	function save() {
		#if (sys || nodejs)
		var fileName:String = getFileName();
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
		}
		File.saveContent(fileName, Json.stringify(positions, null, "\t"));
		#end
	}

	function load() {
		#if (!macro && (sys || nodejs))
		var fileName:String = getFileName();
		if (!FileSystem.exists(fileName)) {
			return;
		}
		var content:String = File.getContent(fileName);

		var parser = new JsonParser<Positions>();
		positions = parser.fromJson(content, fileName);
		#end
	}

	function getFileName():String {
		return Path.join([baseFolder, RESULT_FOLDER, POS_FILE]);
	}
}
