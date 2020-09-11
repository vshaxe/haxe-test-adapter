package _testadapter.data;

import haxe.io.Path;

using StringTools;

#if (sys || nodejs)
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
#end

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
		if (hasFilters(testFilters)) {
			Data.save(fileName, testFilters);
		} else {
			Data.clear(fileName);
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

	public static function hasFilters(testFilters:TestFilterList):Bool {
		return (testFilters != null) && (testFilters.length > 0);
	}

	public static function shouldRunTest(testFilters:TestFilterList, className:String, testName:String):Bool {
		if (!hasFilters(testFilters)) {
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

	public static function shouldRunTestBuddy(testFilters:TestFilterList, className:String, testName:String):Bool {
		if (!hasFilters(testFilters)) {
			return true;
		}
		var location:String = '$className.$testName';
		var parts:Array<String> = location.split(" ");
		if (parts.length < 2) {
			return true;
		}
		for (filter in testFilters) {
			var reg:EReg = ~/<[0-9]+> /;
			filter = reg.replace(filter, "");
			if (location == filter) {
				return true;
			}
			var filterParts:Array<String> = filter.split(" ");
			if (filterParts.length < 2) {
				return true;
			}
			if (filterParts[1].indexOf("].") >= 0) {
				if (parts[1] != filterParts[1]) {
					continue;
				}
			} else {
				if (!parts[1].startsWith(filterParts[1])) {
					continue;
				}
			}
			if (parts[0] == filterParts[0]) {
				return true;
			}
			if (parts[0].startsWith(filterParts[0] + ".")) {
				return true;
			}
		}
		return false;
	}
}
