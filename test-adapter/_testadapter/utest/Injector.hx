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
				#if (utest >= version("2.0.0-alpha"))
				case "addCase": // utest 2.x support
					field.patch(Replace, macro {
						var className = Type.getClassName(Type.getClass(testCase));
						if (fixtures.exists(className)) {
							throw new UTestException('Cannot add the same test twice.');
						}
						var newFixtures = [];
						var init:utest.TestData.InitializeUtest = (cast testCase : utest.TestData.Initializer).__initializeUtest__();
						var cls:_testadapter.data.Data.SuiteId = ClassName(className);
						for (test in init.tests) {
							if (!isTestFixtureName(className, test.name, ['test', 'spec'], pattern, globalPattern)) {
								continue;
							}
							if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, cls, test.name)) {
								continue;
							}
							newFixtures.push(new utest.TestFixture(testCase, test, init.accessories));
						}
						if (newFixtures.length > 0) {
							fixtures.set(className, {
								caseInstance: testCase,
								setupClass: init.accessories.getSetupClass(),
								dependencies: #if UTEST_IGNORE_DEPENDS [] #else init.dependencies #end,
								fixtures: newFixtures,
								teardownClass: init.accessories.getTeardownClass()
							});
							length += newFixtures.length;
						}
					});
				#else
				case "addITest": // utest 1.x support
					field.patch(Replace, macro {
						var className = Type.getClassName(Type.getClass(testCase));
						if (iTestFixtures.exists(className)) {
							throw "Cannot add the same test twice.";
						}
						var fixtures = [];
						var init:utest.TestData.InitializeUtest = (cast testCase : utest.TestData.Initializer).__initializeUtest__();
						var cls:_testadapter.data.Data.SuiteId = ClassName(className);
						for (test in init.tests) {
							if (!isTestFixtureName(cls, test.name, ["test", "spec"], pattern, globalPattern)) {
								continue;
							}
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
						iTestFixtures.set(className, {
							caseInstance: testCase,
							setupClass: init.accessories.getSetupClass(),
							dependencies: init.dependencies,
							fixtures: fixtures,
							teardownClass: init.accessories.getTeardownClass()
						});
					});
				#end
			}
		}
		return fields;
	}
}
#end
