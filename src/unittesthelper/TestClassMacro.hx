package unittesthelper;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
#if (haxe_ver >= 4)
import haxe.display.Position.Location;
#end
import unittesthelper.data.TestPosCache;

class TestClassMacro {
	#if macro
	public static function global() {
		Compiler.addGlobalMetadata("", "@:build(unittesthelper.TestClassMacro.build())", true, true, false);
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
		if (!~/(Test|Tests|TestCase|TestCases)$/.match(cls.name)) {
			return fields;
		}
		addTestPos(Context.getLocalModule(), Context.currentPos());
		for (field in fields) {
			var name:String = Context.getLocalModule() + "#" + field.name;
			addTestPos(name, field.pos);
		}
		return fields;
	}

	static function addTestPos(name:String, pos:Position) {
		#if (haxe_ver >= 4)
		var location:Location = PositionTools.toLocation(pos);
		if (location.file == "?") {
			return;
		}
		TestPosCache.addPos({
			location: name,
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
