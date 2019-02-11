import tests.TestCase3;
import utest.Assert;

class Main {
	static function main() {
		utest.UTest.run([new TestCase(), new TestCase2(), new TestCase3()]);
	}
}

class TestCase extends utest.Test {
	function testSuccess() {
		Assert.isTrue(true);
	}

	function testFailure() {
		Assert.fail();
	}

	function testError() {
		throw "failure";
	}

	@Ignored("Description")
	function testIgnore() {}
}

class TestCase2 extends utest.Test {
	function testSuccess() {
		Assert.isTrue(true);
	}
}
