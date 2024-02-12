package _testadapter;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
import _testadapter.data.TestFilter;
import _testadapter.data.TestPositions;

using Lambda;
using StringTools;

#if (haxe_ver >= 4)
import haxe.display.Position.Location;
#end

class Macro {
	#if macro
	static var positions = new TestPositions(Sys.getCwd(), new Positions());
	public static var filters(default, null):TestFilterList;

	static function require(lib:String, minVersion:String) {
		var version = Context.definedValue(lib);
		if (version == null) {
			return;
		}
		var a = version.split(".").map(Std.parseInt);
		var b = minVersion.split(".").map(Std.parseInt);
		if (a[0] > b[0]) {
			return;
		}
		if (a[0] == b[0]) {
			if (a[1] > b[1]) {
				return;
			}
			if ((a[1] == b[1]) && (a[2] >= b[2])) {
				return;
			}
		}
		Context.fatalError('test-adapter requires $lib $minVersion or newer, found $version', Context.currentPos());
	}

	public static function init() {
		if (Context.defined("display")) {
			return;
		}

		require("munit", "2.3.2");
		require("utest", "1.13.0");
		require("buddy", "2.10.0");
		require("hexunit", "0.35.0");
		require("tink_testrunner", "0.8.0");

		setupHooks();

		var testFilter = new TestFilter(Sys.getCwd());
		filters = {
			include: testFilter.get().include,
			exclude: testFilter.get().exclude
		};
		testFilter.clear();

		Context.onGenerate(function(_) {
			// no side effects for caching, only actual builds
			if (Sys.args().indexOf("--no-output") == -1) {
				Sys.println("test-adapter is recording results...\n");
				positions.save();
			}
		});
	}

	static function setupHooks() {
		inline function build(func:String, target:String) {
			Compiler.addGlobalMetadata(target, '@:build(_testadapter.$func)', false);
		}
		inline function autoBuild(func:String, target:String) {
			Compiler.addGlobalMetadata(target, '@:autoBuild(_testadapter.$func)', false);
		}

		// record positions / line numbers
		#if (munit || hexunit || tink_testrunner)
		Compiler.addGlobalMetadata("", "@:build(_testadapter.Macro.recordPositions(true))", true, true, false);
		#end

		// munit
		build("munit.Injector.buildRunner()", "massive.munit.TestRunner");
		build("munit.Injector.buildHelper()", "massive.munit.TestClassHelper");

		// utest
		autoBuild("Macro.recordPositions(false)", "utest.ITest");
		build("utest.Injector.build()", "utest.Runner");

		// buddy
		autoBuild("Macro.recordPositions(false)", "buddy.BuddySuite");
		build("buddy.Injector.buildSuite()", "buddy.BuddySuite");
		build("buddy.Injector.buildRunner()", "buddy.SuitesRunner");

		// hexUnit
		build("hexunit.Injector.buildCore()", "hex.unittest.runner.ExMachinaUnitCore");

		// tink_unittest
		build("tink_unittest.Injector.buildRunner()", "tink.testrunner.Runner");

		// haxe.unit
		autoBuild("Macro.recordPositions(false)", "haxe.unit.TestCase");
		autoBuild("haxeunit.Injector.buildCase()", "haxe.unit.TestCase");
		build("haxeunit.Injector.buildRunner()", "haxe.unit.TestRunner");
	}

	public static function recordPositions(applyClassNameFilter:Bool):Null<Array<Field>> {
		var ref:Ref<ClassType> = Context.getLocalClass();
		if (ref == null) {
			return null;
		}
		var cls:ClassType = ref.get();
		if (cls.isInterface || cls.name == null || cls.kind.match(KAbstractImpl(_))) {
			return null;
		}

		var dotPath = cls.pack.join(".");
		var ignoredPackages = [
			"_testadapter",
			"massive.munit",
			"utest",
			"buddy",
			"hex.unittest",
			"haxe.unit",
			"tink.unit"
		];
		for (ignoredPackage in ignoredPackages) {
			if (dotPath.startsWith(ignoredPackage)) {
				return null;
			}
		}

		if (applyClassNameFilter) {
			var filter = Context.definedValue("test-adapter-filter");
			var regex = if (filter == null) ~/Test/ else new EReg(filter, "");

			var hierarchyNames = [];
			function loop(c:ClassType) {
				hierarchyNames.push(c.name);
				c.interfaces.iter(function(r) loop(r.t.get()));
				if (c.superClass != null) {
					loop(c.superClass.t.get());
				}
			}
			loop(cls);
			if (!hierarchyNames.exists(regex.match)) {
				return null;
			}
		}

		var className = makeLocation(cls.name);
		addTestPos(className, cls.pos);
		for (field in Context.getBuildFields()) {
			if (field.name == "new" || field.name.startsWith("__")) {
				continue;
			}
			addTestPos(className, field.name, field.pos);
		}
		return null;
	}

	static function makeLocation(clazz:String):String {
		var location:String = Context.getLocalModule();
		if (location == clazz) {
			return location;
		}
		if (location.endsWith('.$clazz')) {
			return location;
		}
		var parts:Array<String> = location.split(".");
		parts.pop();
		parts.push(clazz);
		return parts.join(".");
	}

	static function addTestPos(className:String, ?testName:String, pos:Position) {
		#if (haxe_ver >= 4)
		var location:Location = PositionTools.toLocation(pos);
		var fileName:String = cast location.file;
		if (fileName == "?") {
			return;
		}
		positions.add(className, testName, {
			file: fileName,
			line: location.range.start.line - 1
		});
		#else
		var posInfo = Context.getPosInfos(pos);
		if (posInfo.file == "?") {
			return;
		}
		// TODO line numbers for Haxe 3 compile
		positions.add(className, testName, {
			file: posInfo.file,
			line: null
		});
		#end
	}
	#end
}
