import tests.TestCase3;
import tink.testrunner.Runner;
import tink.unit.*;
import tink.unit.Assert;

class Main {
	static function main() {
		Runner.run(TestBatch.make([new TestCase(), new TestCase2(), new tests.TestCase(), new TestCase3()])).handle(Runner.exit);
	}
}

@:asserts
class TestCase {
	public function new() {}

	public function testSuccess() {
		Sys.sleep(Math.random());
		return Assert.assert(true);
	}

	public function testFailure() {
		Sys.sleep(Math.random());
		return Assert.assert("A" == "B");
	}

	public function testError() {
		Sys.sleep(Math.random());
		return new tink.core.Error("failure");
	}

	public function testEmpty() {
		Sys.sleep(Math.random());
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
