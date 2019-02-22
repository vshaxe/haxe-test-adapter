package testadapter.data;

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
	methods:Map<String, {line:Int}>,
	pos:Pos
};

typedef Positions = Map<String, ClassPosition>;

class TestPositions {
	var baseFolder:String;
	var positions:Positions;

	public function new(baseFolder:String, positions:Positions) {
		this.baseFolder = baseFolder;
		this.positions = positions;
	}

	public function add(className:String, ?testName:String, pos:Pos) {
		if (testName == null) {
			positions[className] = {methods: new Map<String, {line:Int}>(), pos: pos};
		} else {
			if (positions[className] == null) {
				positions[className] = {methods: new Map<String, {line:Int}>(), pos: pos};
			}
			positions[className].methods[testName] = {line: pos.line};
		}
	}

	public function get(className:String, testName:String):Pos {
		var clazz = positions[className];
		if ((clazz == null) || (clazz.pos == null) || (clazz.methods == null)) {
			return null;
		}
		if (testName == null) {
			return clazz.pos;
		}
		if (clazz.methods[testName] == null) {
			return clazz.pos;
		}
		return {
			file: clazz.pos.file,
			line: clazz.methods[testName].line
		};
	}

	public function resolveClassName(fileName:String, lineNumber:Int):Null<String> {
		for (clazz in positions.keys()) {
			var classPositions = positions.get(clazz);
			if (classPositions.pos.file != fileName) {
				continue;
			}
			if (classPositions.pos.line == lineNumber) {
				return clazz;
			}
			for (method in classPositions.methods.keys()) {
				var methodPos = classPositions.methods.get(method);
				if (methodPos.line == lineNumber) {
					return clazz;
				}
			}
		}
		return null;
	}

	public function save() {
		#if (sys || nodejs)
		Data.save(getFileName(baseFolder), positions);
		#end
	}

	public static function load(baseFolder:String):Null<TestPositions> {
		#if (!macro && (sys || nodejs))
		var fileName:String = getFileName(baseFolder);
		if (!FileSystem.exists(fileName)) {
			return null;
		}
		var content:String = File.getContent(fileName);

		var parser = new JsonParser<Positions>();
		var positions = parser.fromJson(content, fileName);
		return new TestPositions(baseFolder, positions);
		#else
		return new TestPositions(baseFolder, new Positions());
		#end
	}

	static function getFileName(baseFolder:String):String {
		return Path.join([baseFolder, Data.FOLDER, "positions.json"]);
	}
}
