package _testadapter.utest;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro new _testadapter.utest.Reporter(this, $v{Sys.getCwd()}));
				case "addITest":
					field.patch(Replace, macro {
						if (iTestFixtures.exists(testCase)) {
							throw "Cannot add the same test twice.";
						}
						var fixtures = [];
						var init:utest.TestData.InitializeUtest = (cast testCase : utest.TestData.Initializer).__initializeUtest__();
						for (test in init.tests) {
							if (!isTestFixtureName(test.name, ["test", "spec"], pattern, globalPattern)) {
								continue;
							}
							var cls:_testadapter.data.Data.SuiteId = ClassName(Type.getClassName(Type.getClass(testCase)));
							if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, cls, test.name)) {
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
					});
			}
		}
		return fields;
	}
}
#end
