import tests.TestCase3;
import tests.pack.TestCase4;
import utest.Assert;

class Main {
	static function main() {
		utest.UTest.run([
			new TestCase(),
			new TestCase2(),
			new tests.TestCase(),
			new TestCase3(),
			new TestCase4()
		]);
	}
}

class TestCase extends utest.Test {
	function testSuccess() {
		Sys.sleep(Math.random());
		Assert.isTrue(true);
	}

	function testFailure() {
		Sys.sleep(Math.random());
		Assert.equals("A", "B");
		Assert.isTrue(true);
	}

	function testError() {
		Sys.sleep(Math.random());
		throw "failure";
	}

	function testEmpty() {
		Sys.sleep(Math.random());
	}

	@Ignored("Description") // utest 1.x
	@:ignore("Description") // utest 2.x
	function testIgnore() {}
}

class TestCase2 extends utest.Test {
	function testSuccess() {
		Assert.isTrue(true);
	}
}
