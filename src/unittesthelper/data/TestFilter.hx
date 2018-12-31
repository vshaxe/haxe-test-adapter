package unittesthelper.data;

import haxe.io.Path;
#if sys
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
#end

typedef TestFilterList = Array<String>;

class TestFilter {
	public static inline var RESULT_FOLDER:String = ".unittest";
	public static inline var FILTER_FILE:String = "testFilter.json";
	static var INSTANCE:TestFilter = new TestFilter();

	var testFilters:TestFilterList;
	var loaded:Bool;

	function new() {
		testFilters = [];
		loaded = false;
	}

	public static function setTestFilter(?baseFolder:String, filter:Array<String>) {
		INSTANCE.testFilters = [];
		for (f in filter) {
			if (f == "root") {
				INSTANCE.testFilters = [];
				break;
			}
			INSTANCE.testFilters.push(f);
		}
		INSTANCE.saveFilters(baseFolder);
	}

	public static function clearTestFilter() {
		INSTANCE.testFilters = [];
		INSTANCE.saveFilters();
	}

	public static function hasFilter():Bool {
		if (!INSTANCE.loaded) {
			INSTANCE.loadFilters();
		}
		if ((INSTANCE.testFilters == null) || (INSTANCE.testFilters.length <= 0)) {
			return false;
		}
		return true;
	}

	public static function shouldRunTest(className:String, testName:String):Bool {
		if (!INSTANCE.loaded) {
			INSTANCE.loadFilters();
		}
		if ((INSTANCE.testFilters == null) || (INSTANCE.testFilters.length <= 0)) {
			return true;
		}
		var location:String = '$className.$testName';
		for (filter in INSTANCE.testFilters) {
			if (location == filter) {
				return true;
			}
			if (StringTools.startsWith(location, filter)) {
				return true;
			}
		}
		return false;
	}

	function saveFilters(?baseFolder:String) {
		#if sys
		var fileName:String = getTestFilterFileName(baseFolder);
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(RESULT_FOLDER);
		}
		File.saveContent(fileName, Json.stringify(testFilters, null, "    "));
		#end
	}

	function loadFilters() {
		testFilters = [];
		#if sys
		var fileName:String = getTestFilterFileName();
		if (!FileSystem.exists(fileName)) {
			return;
		}
		var content:String = File.getContent(fileName);
		var filters:TestFilterList = Json.parse(content);
		for (filter in filters) {
			testFilters.push(filter);
		}
		#end
		loaded = true;
	}

	public static function getTestFilterFileName(?baseFolder:String):String {
		return Path.join([baseFolder, RESULT_FOLDER, FILTER_FILE]);
	}
}
