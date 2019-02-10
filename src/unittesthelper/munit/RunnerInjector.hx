package unittesthelper.munit;

import haxe.macro.Expr;
import haxe.macro.Context;

class RunnerInjector {
	public static function build():Array<Field> {
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
							exprs.push(macro addResultClient(new unittesthelper.munit.TestAdapterResultClient()));
						case "createTestClassHelper":
							exprs.push(macro return new unittesthelper.munit.TestAdapterClassHelper(testClass, isDebug));
						case _:
					}
				case _:
			}
		}
		return fields;
	}
}
