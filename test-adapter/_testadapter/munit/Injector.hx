package _testadapter.munit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (field.name == "new") {
				field.addInit(macro addResultClient(new _testadapter.munit.ResultClient($v{Sys.getCwd()})));
			}
		}
		return fields;
	}

	public static function buildHelper():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "scanForTests":
					field.patch(End, macro if (tests.length <= 0) {
						beforeClass = nullFunc;
						afterClass = nullFunc;
						before = nullFunc;
						after = nullFunc;
					});
				case "addTest":
					field.patch(Start, macro if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, className, field)) {
						return;
					});
				case _:
			}
		}

		return fields;
	}
}
#end
