package unittesthelper.haxeunit;

import haxe.macro.Expr;
import haxe.macro.Context;

class Injector {
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
			switch (field.name) {
				case "new":
					switch (f.expr.expr) {
						case EBlock(exprs):
							exprs.push(macro testData = new unittesthelper.data.TestResultData());
						case _:
					}
				case "run":
					field.name = "__run";
			}
		}

		var extraFields = (macro class {
			var testData:unittesthelper.data.TestResultData;

			public function run():Bool {
				var filteredCases:List<TestCase> = new List<TestCase>();
				for (c in cases) {
					var cl = Type.getClass(c);
					if (unittesthelper.data.TestFilter.shouldRunTest(Type.getClassName(cl), "")) {
						filteredCases.push(c);
					}
				}
				cases = filteredCases;
				var success:Bool = __run();

				publishAdapterResults();
				unittesthelper.data.TestFilter.clearTestFilter();
				return success;
			}

			@:access(haxe.unit.TestResult)
			function publishAdapterResults() {
				for (r in result.m_tests) {
					var location:String = r.classname + "#" + r.method + "'";
					var state:unittesthelper.data.SingleTestResultState = Failure;
					if (r.success) {
						state = Success;
					}
					testData.addTestResult(r.classname, r.method, location, 0, state, r.error, unittesthelper.data.TestPosCache.getPos(location));
				}
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
