import tink.testrunner.Runner;
import tink.unit.*;
import tink.unit.Assert;

class Test {
	static function main() {
		Runner.run(TestBatch.make([new TestCase()])).handle(function(result) {
			#if instrument
			instrument.coverage.Coverage.endCoverage();
			#end
			Runner.exit(result);
		});
	}
}

@:asserts
class TestCase {
	public function new() {}

	public function testDoNothing() {
		var main = new Main();

		return Assert.assert(main.doNothing());
	}

	public function testDoSomething() {
		var main = new Main();

		return Assert.assert(main.doSomething(false));
	}

	public function testDoSomethingFullCoverage() {
		var main = new Main();

		return [
			Assert.assert(main.doSomethingFullCoverage(false)),
			Assert.assert(main.doSomethingFullCoverage(true) == false)
		];
	}
}
