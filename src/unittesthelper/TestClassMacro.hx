package unittesthelper;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Type;
import haxe.display.Position.Location;
import unittesthelper.data.TestPosCache;

class TestClassMacro {
	#if macro
	public static function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		var cls:ClassType = Context.getLocalClass().get();
		if (cls.isInterface) {
			return fields;
		}
		var location:Location = PositionTools.toLocation(Context.currentPos());
		TestPosCache.addPos({
			location: Context.getLocalModule(),
			file: location.file,
			line: location.range.start.line - 1
		});
		for (field in fields) {
			location = PositionTools.toLocation(field.pos);
			var name:String = Context.getLocalModule() + "#" + field.name;
			TestPosCache.addPos({
				location: name,
				file: location.file,
				line: location.range.start.line - 1
			});
		}
		return fields;
	}
	#end
}
