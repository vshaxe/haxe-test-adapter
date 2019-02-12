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
		if (testFilters.length == 0) {
			if (FileSystem.exists(fileName)) {
				FileSystem.deleteFile(fileName);
			}
		} else {
			Data.save(fileName, testFilters);
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
		return Path.join([baseFolder, Data.FOLDER, "filter.json"]);
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
