import utest.Assert;

class Main {
	static function main() {
		utest.UTest.run([new TestCase(), new TestCase2()]);
	}
}

class TestCase extends utest.Test {
	function testSuccess() {
		Assert.isTrue(true);
	}
}

class TestCase2 extends utest.Test {
	function testSuccess() {
		Assert.isTrue(true);
	}

	function testFailure() {
		Assert.fail();
	}
}
