package testadapter.data;

import haxe.Timer;
import haxe.io.Path;
#if (sys || nodejs)
import haxe.Json;
import json2object.JsonParser;
import sys.FileSystem;
import sys.io.File;
#end
import testadapter.data.Data;

class TestResultData {
	static inline var RESULT_FOLDER:String = ".unittest";
	static inline var RESULT_FILE:String = "results.json";
	static inline var ROOT_SUITE_NAME:String = "root";

	var suiteResults:TestSuiteResults;
	var fileName:String;
	var baseFolder:String;

	public function new(?baseFolder:String) {
		this.baseFolder = baseFolder;
		fileName = getTestDataFileName(baseFolder);
		init();
	}

	public function addTestResult(className:String, name:String, executionTime:Float = 0, state:TestState, ?message:String, ?errorLine:Int) {
		var pos = TestPosCache.getPos(className, name);
		var line:Null<Int> = null;
		if (pos != null) {
			line = pos.line;
		}
		function makeTest():TestResults {
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
				data.tests = data.tests.filter(results -> results.name != name);
				data.tests.push(makeTest());
				saveData();
				return;
			}
		}
		suiteResults.classes.push({
			name: className,
			tests: [makeTest()],
			pos: TestPosCache.getPos(className, null)
		});
		saveData();
	}

	function init() {
		#if (nodejs || sys)
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
			suiteResults = {name: ROOT_SUITE_NAME, classes: []};
			return;
		}
		#end
		if (!TestFilter.hasFilter()) {
			suiteResults = {name: ROOT_SUITE_NAME, classes: []};
		} else {
			suiteResults = loadData(baseFolder);
		}
	}

	function saveData() {
		#if (sys || nodejs)
		File.saveContent(fileName, Json.stringify(suiteResults, null, "    "));
		#end
	}

	public static function loadData(?baseFolder:String):TestSuiteResults {
		#if (sys || nodejs)
		var dataFile:String = getTestDataFileName(baseFolder);
		if (!FileSystem.exists(dataFile)) {
			return {name: ROOT_SUITE_NAME, classes: []};
		}
		var content:String = File.getContent(dataFile);

		var parser = new JsonParser<TestSuiteResults>();
		return parser.fromJson(content, dataFile);
		#end
		return {name: ROOT_SUITE_NAME, classes: []};
	}

	public static function getTestDataFileName(?baseFolder:String):String {
		return Path.join([baseFolder, RESULT_FOLDER, RESULT_FILE]);
	}
}
