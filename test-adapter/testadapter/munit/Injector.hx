package testadapter.munit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			var f = switch (field.kind) {
				case FFun(f): f;
				case _: null;
			}
			if (f == null) {
				continue;
			}
			switch (f.expr.expr) {
				case EBlock(exprs):
					switch (field.name) {
						case "new":
							exprs.push(macro addResultClient(new testadapter.munit.ResultClient($v{Sys.getCwd()})));
						case _:
					}
				case _:
			}
		}
		return fields;
	}

	public static function buildHelper():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "addTest", "scanForTests":
					field.name = "__" + field.name;
				case _:
			}
		}

		var extraFields = (macro class {
			function scanForTests(fieldMeta:Dynamic) {
				__scanForTests(fieldMeta);
				if (tests.length <= 0) {
					beforeClass = nullFunc;
					afterClass = nullFunc;
					before = nullFunc;
					after = nullFunc;
					return;
				}
			}

			function addTest(field:String, testFunction:Function, testInstance:Dynamic, isAsync:Bool, isIgnored:Bool, description:String) {
				if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, className, field)) {
					return;
				}
				__addTest(field, testFunction, testInstance, isAsync, isIgnored, description);
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
