import utest.Assert;
import utest.ITest;
import utest.Runner;
import utest.ui.text.DiagnosticsReport;

class Test {
	static function main() {
		var tests:Array<ITest> = [new TestMain(),];
		var runner:Runner = new Runner();

		#if instrument
		runner.onComplete.add(_ -> {
			instrument.coverage.Coverage.endCoverage();
		});
		#end

		new DiagnosticsReport(runner);
		for (test in tests) {
			runner.addCase(test);
		}
		runner.run();
	}
}

class TestMain implements ITest {
	public function new() {}

	function testDoNothing() {
		var main = new Main();

		Assert.isTrue(main.doNothing());
	}

	function testDoSomething() {
		var main = new Main();

		Assert.isTrue(main.doSomething(false));
	}

	function testDoSomethingFullCoverage() {
		var main = new Main();

		Assert.isTrue(main.doSomethingFullCoverage(false));
		Assert.isFalse(main.doSomethingFullCoverage(true));
	}
}
