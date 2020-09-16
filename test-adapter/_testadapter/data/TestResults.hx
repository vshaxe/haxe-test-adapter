package _testadapter.data;

import haxe.Timer;
import haxe.io.Path;
import _testadapter.data.Data;
#if (sys || nodejs)
import sys.FileSystem;
import sys.io.File;
import json2object.JsonParser;
#end

class TestResults {
	var baseFolder:String;
	var suiteResults:TestSuiteResults;

	public var positions:TestPositions;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		positions = TestPositions.load(baseFolder);
		suiteResults = load(baseFolder);
	}

	public function add(suiteId:SuiteId, testId:TestIdentifier, executionTime:Float = 0, state:TestState, ?message:String, ?errorLine:Int) {
		var line:Null<Int> = null;
		var className:String;
		var suitePos:Pos;
		switch (suiteId) {
			case ClassName(name):
				className = name;
				suitePos = positions.get(className, null);
			case SuiteNameAndPos(name, fileName, lineNumber):
				className = name;
				suitePos = {file: fileName, line: lineNumber};
			case SuiteNameAndFile(name, fileName):
				className = name;
				suitePos = {file: fileName, line: 0};
		}
		var testName:String;
		switch (testId) {
			case TestName(name):
				testName = name;
				var pos = positions.get(suiteId, name);
				if (pos != null) {
					line = pos.line;
				}
			case TestNameAndPos(name, _, lineNumber):
				testName = name;
				line = lineNumber;
		}

		function makeTest():TestMethodResults {
			return {
				name: testName,
				executionTime: executionTime,
				state: state,
				message: message,
				timestamp: Timer.stamp(),
				line: line,
				errorLine: errorLine
			}
		}
		for (data in suiteResults.classes) {
			if (data.id == suiteId) {
				data.methods = data.methods.filter(function(results) return results.name != testName);
				data.methods.push(makeTest());
				return;
			}
		}
		suiteResults.classes.push({
			id: suiteId,
			name: className,
			methods: [makeTest()],
			pos: suitePos
		});
	}

	public function save() {
		#if (sys || nodejs)
		suiteResults.classes.sort(sortClasses);
		Data.save(getFileName(baseFolder), suiteResults);
		#end
	}

	function sortClasses(a:TestClassResults, b:TestClassResults):Int {
		if (a.id < b.id) {
			return -1;
		}
		if (a.id > b.id) {
			return 1;
		}
		return 0;
	}

	public static function clear(baseFolder:String) {
		#if (sys || nodejs)
		Data.clear(getFileName(baseFolder));
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
