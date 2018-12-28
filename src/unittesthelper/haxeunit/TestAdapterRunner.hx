package unittesthelper.haxeunit;

import haxe.unit.TestCase;
import haxe.unit.TestResult;
import haxe.unit.TestRunner;
import haxe.unit.TestStatus;
import unittesthelper.data.TestPos;
import unittesthelper.data.TestFilter;
import unittesthelper.data.TestPosCache;
import unittesthelper.data.TestResultData;
import unittesthelper.data.SingleTestResultState;

class TestAdapterRunner extends TestRunner {
	var testData:TestResultData;

	public function new(?baseFolder:String) {
		super();
		testData = new TestResultData(baseFolder);
	}

	override public function run():Bool {
		var filteredCases:List<TestCase> = new List<TestCase>();
		for (c in cases) {
			var cl = Type.getClass(c);
			if (TestFilter.shouldRunTest(Type.getClassName(cl), "")) {
				filteredCases.push(c);
			}
		}
		cases = filteredCases;
		var success:Bool = super.run();

		publishAdapterResults();
		return success;
	}

	@:access(haxe.unit.TestResult)
	function publishAdapterResults() {
		for (r in result.m_tests) {
			var location:String = '${r.classname}#${r.method}';
			var state:SingleTestResultState = Failure;
			if (r.success) {
				state = Success;
			}
			testData.addTestResult(r.classname, r.method, location, 0, state, r.error, TestPosCache.getPos(location));
		}
	}
}
