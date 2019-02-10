package unittesthelper.utest;

import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;

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
			switch (field.name) {
				case "new":
					switch (f.expr.expr) {
						case EBlock(exprs):
							exprs.push(macro new unittesthelper.utest.TestAdapterReporter(this));
						case _:
					}
				case "addITest":
					f.expr = macro {
						if (iTestFixtures.exists(testCase)) {
							throw "Cannot add the same test twice.";
						}
						var fixtures = [];
						var init:utest.TestData.InitializeUtest = (testCase : Dynamic).__initializeUtest__();
						for (test in init.tests) {
							if (!isTestFixtureName(test.name, ["test", "spec"], pattern, globalPattern)) {
								continue;
							}
							var cls:String = Type.getClassName(Type.getClass(testCase));
							if (!unittesthelper.data.TestFilter.shouldRunTest(cls, test.name)) {
								continue;
							}
							var fixture = utest.TestFixture.ofData(testCase, test, init.accessories);
							addFixture(fixture);
							fixtures.push(fixture);
						}
						if (fixtures.length <= 0) {
							return;
						}
						iTestFixtures.set(testCase, {
							setupClass: init.accessories.getSetupClass(),
							fixtures: fixtures,
							teardownClass: init.accessories.getTeardownClass()
						});
					};
			}
		}
		return fields;
	}
}
