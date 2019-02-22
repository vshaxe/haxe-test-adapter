package testadapter;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
#if (haxe_ver >= 4)
import haxe.display.Position.Location;
#end
import testadapter.data.TestPositions;
import testadapter.data.TestFilter;

using StringTools;

class Macro {
	#if macro
	static var positions = new TestPositions(Sys.getCwd(), new Positions());
	public static var filters(default, null):Array<String>;

	static function require(lib:String, minVersion:String) {
		var version = Context.definedValue(lib);
		if (version != null) {
			var a = version.split(".").map(Std.parseInt);
			var b = minVersion.split(".").map(Std.parseInt);
			if (a[0] < b[0] || a[1] < b[1] || a[2] < b[2]) {
				Context.fatalError('test-adapter requires $lib $minVersion or newer, found $version', Context.currentPos());
			}
		}
	}

	public static function init() {
		require("munit", "2.3.3");
		require("utest", "1.9.2");
		require("buddy", "2.10.0");
		require("hexunit", "0.35.0");
		require("tink_unittest", "0.6.0");

		Sys.println("test-adapter is recording results...\n");

		// record positions / line numbers
		Compiler.addGlobalMetadata("", "@:build(testadapter.Macro.build())", true, true, false);

		// munit
		Compiler.addMetadata("@:build(testadapter.munit.Injector.buildRunner())", "massive.munit.TestRunner");
		Compiler.addMetadata("@:build(testadapter.munit.Injector.buildHelper())", "massive.munit.TestClassHelper");

		// utest
		Compiler.addMetadata("@:build(testadapter.utest.Injector.build())", "utest.Runner");

		// buddy
		Compiler.addMetadata("@:build(testadapter.buddy.Injector.buildSuite())", "buddy.BuddySuite");
		Compiler.addMetadata("@:build(testadapter.buddy.Injector.buildRunner())", "buddy.SuitesRunner");

		// hexUnit
		Compiler.addMetadata("@:build(testadapter.hexunit.Injector.buildCore())", "hex.unittest.runner.ExMachinaUnitCore");

		// tink_unittest
		Compiler.addMetadata("@:build(testadapter.tinktestrunner.Injector.buildRunner())", "tink.testrunner.Runner");

		// haxe.unit
		Compiler.addMetadata("@:build(testadapter.haxeunit.Injector.buildRunner())", "haxe.unit.TestRunner");
		Compiler.addMetadata("@:autoBuild(testadapter.haxeunit.Injector.buildCase())", "haxe.unit.TestCase");

		var testFilter = new TestFilter(Sys.getCwd());
		filters = testFilter.get();
		testFilter.clear();

		Context.onGenerate(function(_) {
			positions.save();
		});
	}

	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var ref:Ref<ClassType> = Context.getLocalClass();
		if (ref == null) {
			return fields;
		}
		var cls:ClassType = ref.get();
		if (cls.isInterface) {
			return fields;
		}
		if (cls.name == null) {
			return fields;
		}
		var dotPath = cls.pack.join(".");
		var ignoredPackages = ["testadapter", "massive.munit", "utest", "haxe.unit"];
		for (ignoredPackage in ignoredPackages) {
			if (dotPath.startsWith(ignoredPackage)) {
				return fields;
			}
		}
		if (!~/(Test|Tests|TestCase|TestCases)/.match(cls.name)) {
			return fields;
		}
		var className = makeLocation(cls.name);
		if (cls.kind.match(KAbstractImpl(_))) {
			return fields;
		}
		addTestPos(className, cls.pos);
		for (field in fields) {
			if (field.name == "new" || field.name.startsWith("__")) {
				continue;
			}
			addTestPos(className, field.name, field.pos);
		}
		return fields;
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
		if (location.file == "?") {
			return;
		}
		positions.add(className, testName, {
			file: location.file,
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
