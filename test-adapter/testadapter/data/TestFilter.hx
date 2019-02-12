package testadapter.data;

import haxe.io.Path;
#if (sys || nodejs)
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

typedef TestFilterList = Array<String>;

class TestFilter {
	static inline var RESULT_FOLDER:String = ".unittest";
	static inline var FILTER_FILE:String = "filter.json";

	var testFilters:TestFilterList;
	var baseFolder:String;
	var loaded:Bool;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		testFilters = [];
		loaded = false;
	}

	public function set(filter:Array<String>) {
		testFilters = [];
		for (f in filter) {
			if (f == "root") {
				testFilters = [];
				break;
			}
			testFilters.push(f);
		}
		save(baseFolder);
	}

	public function get():Array<String> {
		if (!loaded) {
			load();
		}
		return testFilters;
	}

	public function clear() {
		testFilters = [];
		save();
	}

	function save(?baseFolder:String) {
		#if (sys || nodejs)
		var fileName:String = getFileName(baseFolder);
		if (!FileSystem.exists(fileName)) {
			FileSystem.createDirectory(Path.join([baseFolder, RESULT_FOLDER]));
		}
		if (testFilters.length == 0) {
			if (FileSystem.exists(fileName)) {
				FileSystem.deleteFile(fileName);
			}
		} else {
			File.saveContent(fileName, Json.stringify(testFilters, null, "\t"));
		}
		#end
	}

	function load() {
		testFilters = [];
		#if (sys || nodejs)
		var fileName:String = getFileName();
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

	function getFileName(?baseFolder:String):String {
		return Path.join([baseFolder, RESULT_FOLDER, FILTER_FILE]);
	}

	public static function shouldRunTest(testFilters:TestFilterList, className:String, testName:String):Bool {
		if (testFilters == null || testFilters.length <= 0) {
			return true;
		}
		var location:String = '$className.$testName';
		for (filter in testFilters) {
			if (location == filter) {
				return true;
			}
			if (location.startsWith(filter + ".")) {
				return true;
			}
		}
		return false;
	}
}
