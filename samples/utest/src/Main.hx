import utest.Assert;

class Main {
	static function main() {
		utest.UTest.run([new TestCase()]);
	}
}

class TestCase extends utest.Test {
	function testSuccess() {
		Assert.equals("A", "A");
	}

	function testFailure() {
		Assert.equals("A", "B");
	}
}
