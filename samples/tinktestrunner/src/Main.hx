import tests.TestCase3;
import tink.unit.*;
import tink.unit.Assert;
import tink.testrunner.Runner;

class Main {
	static function main() {
		Runner.run(TestBatch.make([new TestCase(), new TestCase2(), new TestCase3()])).handle(Runner.exit);
	}
}

@:asserts
class TestCase {
	public function new() {}

	public function testSuccess() {
		return Assert.assert(true);
	}

	public function testFailure() {
		return Assert.assert("A" == "B");
	}

	public function testError() {
		return new tink.core.Error("failure");
	}

	public function testEmpty() {
		return asserts.done();
	}

	@:exclude
	public function testIgnore() {}
}

class TestCase2 {
	public function new() {}

	public function testSuccess() {
		return Assert.assert(true);
	}
}
