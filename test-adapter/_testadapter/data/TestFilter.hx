package _testadapter.data;

import haxe.io.Path;

using StringTools;

#if (sys || nodejs)
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
#end

typedef TestFilterList = {
	include:Array<String>,
	exclude:Array<String>
};

class TestFilter {
	var testFilters:TestFilterList;
	var baseFolder:String;
	var loaded:Bool;

	public function new(baseFolder:String) {
		this.baseFolder = baseFolder;
		testFilters = {
			include: [],
			exclude: []
		};
		loaded = false;
	}

	public function set(include:Array<String>, exclude:Array<String>) {
		testFilters.include = [];
		testFilters.exclude = [];
		for (f in include) {
			if (f.startsWith("root:")) {
				testFilters.include = [];
				break;
			}
			testFilters.include.push(f);
		}
		for (f in exclude) {
			testFilters.exclude.push(f);
		}
		save(baseFolder);
	}

	public function get():TestFilterList {
		if (!loaded) {
			load();
		}
		return testFilters;
	}

	public function clear() {
		testFilters.include = [];
		testFilters.exclude = [];
		save();
	}

	function save(?baseFolder:String) {
		#if (sys || nodejs)
		var fileName:String = getFileName(baseFolder);
		if (hasFilters(testFilters)) {
			Data.save(fileName, testFilters);
		} else {
			Data.clear(fileName);
		}
		#end
	}

	function load() {
		testFilters.include = [];
		testFilters.exclude = [];
		#if (sys || nodejs)
		var fileName:String = getFileName();
		if (!FileSystem.exists(fileName)) {
			return;
		}
		var content:String = File.getContent(fileName);
		var filters:TestFilterList = Json.parse(content);
		for (filter in filters.include) {
			var reg:EReg = ~/ <[0-9]+>/;
			filter = reg.replace(filter, "");
			testFilters.include.push(filter);
		}
		for (filter in filters.exclude) {
			var reg:EReg = ~/ <[0-9]+>/;
			filter = reg.replace(filter, "");
			testFilters.exclude.push(filter);
		}
		#end
		loaded = true;
	}

	function getFileName(?baseFolder:String):String {
		return Path.join([baseFolder, Data.FOLDER, "filter.json"]);
	}

	public static function hasFilters(testFilters:TestFilterList):Bool {
		return (testFilters != null) && ((testFilters.include.length + testFilters.exclude.length > 0));
	}

	public static function shouldRunTest(testFilters:TestFilterList, className:String, testName:String):Bool {
		if (!hasFilters(testFilters)) {
			return true;
		}
		var location:String = '$className.$testName';
		for (filter in testFilters.exclude) {
			if (location == filter) {
				return false;
			}
			if (location.startsWith(filter + ".")) {
				return false;
			}
		}
		for (filter in testFilters.include) {
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
