package testadapter.data;

import haxe.Timer;
import haxe.io.Path;
#if (sys || nodejs)
import json2object.JsonParser;
import sys.FileSystem;
import sys.io.File;
#end
import testadapter.data.Data;

class TestResults {
	var baseFolder:String;
	var suiteResults:TestSuiteResults;

	public var positions:TestPositions;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		positions = TestPositions.load(baseFolder);
		suiteResults = load(baseFolder);
	}

	public function add(className:String, name:String, executionTime:Float = 0, state:TestState, ?message:String, ?errorLine:Int) {
		var pos = positions.get(className, name);
		var line:Null<Int> = null;
		if (pos != null) {
			line = pos.line;
		}
		function makeTest():TestMethodResults {
			return {
				name: name,
				executionTime: executionTime,
				state: state,
				message: message,
				timestamp: Timer.stamp(),
				line: line,
				errorLine: errorLine
			}
		}
		for (data in suiteResults.classes) {
			if (data.name == className) {
				data.methods = data.methods.filter(function(results) return results.name != name);
				data.methods.push(makeTest());
				return;
			}
		}
		suiteResults.classes.push({
			name: className,
			methods: [makeTest()],
			pos: positions.get(className, null)
		});
	}

	public function save() {
		#if (sys || nodejs)
		Data.save(getFileName(baseFolder), suiteResults);
		#end
	}

	public static function load(?baseFolder:String):TestSuiteResults {
		function emptySuite() {
			return {name: "root", classes: []};
		}

		#if (sys || nodejs)
		var dataFile:String = getFileName(baseFolder);
		if (!FileSystem.exists(dataFile)) {
			return emptySuite();
		}
		var content:String = File.getContent(dataFile);

		var parser = new JsonParser<TestSuiteResults>();
		return parser.fromJson(content, dataFile);
		#else
		return emptySuite();
		#end
	}

	static function getFileName(?baseFolder:String):String {
		return Path.join([baseFolder, getRelativeFileName()]);
	}

	public static function getRelativeFileName():String {
		return Path.join([Data.FOLDER, "results.json"]);
	}
}
