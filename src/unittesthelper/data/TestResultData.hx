package unittesthelper.data;

import haxe.Json;
import haxe.Timer;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import json2object.JsonParser;

class TestResultData {
	public static inline var RESULT_FOLDER:String = ".unittest";
	public static inline var RESULT_FILE:String = "testResults.json";
	public static inline var LAST_RUN_FILE:String = "lastRun.json";

	var suiteData:SuiteTestResultData;
	var fileName:String;

	public function new(?baseFolder:String) {
		fileName = getTestDataFileName(baseFolder);
		init();
	}

	public function addTestResult(className:String, name:String, location:String, executionTime:Float, state:SingleTestResultState, errorText:String,
			file:String, line:Null<Int>) {
		for (data in suiteData.classes) {
			if (data.name == className) {
				for (test in data.tests) {
					if (test.location == location) {
						test.location = location;
						test.executionTime = executionTime;
						test.state = state;
						test.timestamp = Timer.stamp();
						test.errorText = errorText;
						test.file = file;
						test.line = line;
						saveData();
						return;
					}
				}
				data.tests.push({
					name: name,
					location: location,
					executionTime: executionTime,
					state: state,
					errorText: errorText,
					timestamp: Timer.stamp(),
					file: file,
					line: line
				});
				saveData();
				return;
			}
		}
		suiteData.classes.push({
			name: className,
			tests: [
				{
					name: name,
					location: location,
					executionTime: executionTime,
					state: state,
					errorText: errorText,
					timestamp: Timer.stamp(),
					file: file,
					line: line
				}
			]
		});
		saveData();
	}

	function init() {
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
			suiteData = {name: "main", classes: []};
			return;
		}
		var lastRun:String = Path.join([RESULT_FOLDER, LAST_RUN_FILE]);
		FileSystem.rename(fileName, lastRun);
		suiteData = {name: "main", classes: []};
	}

	function saveData() {
		File.saveContent(fileName, Json.stringify(suiteData, null, "    "));
	}

	public static function loadData(?baseFolder:String):SuiteTestResultData {
		var dataFile:String = getTestDataFileName(baseFolder);
		var content:String = File.getContent(dataFile);

		var parser:JsonParser<SuiteTestResultData> = new JsonParser<SuiteTestResultData>();
		var data:SuiteTestResultData = parser.fromJson(content, dataFile);
		return data;
	}

	public static function getTestDataFileName(?baseFolder:String):String {
		return Path.join([baseFolder, RESULT_FOLDER, RESULT_FILE]);
	}
}
