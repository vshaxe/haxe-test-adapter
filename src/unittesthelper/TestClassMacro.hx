package unittesthelper;

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
	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var cls:ClassType = Context.getLocalClass().get();
		if (cls.isInterface) {
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
		TestPosCache.addPos({
			location: name,
			file: location.file,
			line: location.range.start.line - 1
		});
		#else
		var posInfo:PosInfos = Context.getPosInfos(pos);
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
