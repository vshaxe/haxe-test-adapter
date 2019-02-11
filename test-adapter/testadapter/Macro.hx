package testadapter;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
#if (haxe_ver >= 4)
import haxe.display.Position.Location;
#end
import testadapter.data.TestPosCache;

using StringTools;

class Macro {
	#if macro
	public static function init() {
		Compiler.addGlobalMetadata("", "@:build(testadapter.Macro.build())", true, true, false);
		Compiler.addMetadata("@:build(testadapter.munit.Injector.buildRunner())", "massive.munit.TestRunner");
		Compiler.addMetadata("@:build(testadapter.munit.Injector.buildHelper())", "massive.munit.TestClassHelper");
		Compiler.addMetadata("@:build(testadapter.utest.Injector.build())", "utest.Runner");
		Compiler.addMetadata("@:build(testadapter.haxeunit.Injector.build())", "haxe.unit.TestRunner");
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
		TestPosCache.addPos(className, testName, {
			file: location.file,
			line: location.range.start.line - 1
		});
		#else
		var posInfo = Context.getPosInfos(pos);
		if (posInfo.file == "?") {
			return;
		}
		// TODO line numbers for Haxe 3 compile
		TestPosCache.addPos({
			location: name,
			file: posInfo.file,
			line: null
		});
		#end
	}
	#end
}
