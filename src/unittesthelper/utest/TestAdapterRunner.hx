package unittesthelper.utest;

import utest.ITest;
import utest.Runner;
import utest.TestFixture;
import unittesthelper.data.TestFilter;

using utest.utils.AccessoriesUtils;

class TestAdapterRunner extends Runner {
	#if haxe_test_adapter_enabled
	public function new() {
		super();
		new TestAdapterReporter(this);
	}

	override function addITest(testCase:ITest, pattern:Null<EReg>) {
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
			if (!TestFilter.shouldRunTest(cls, test.name)) {
				continue;
			}
			var fixture = TestFixture.ofData(testCase, test, init.accessories);
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
	}
	#end
}
