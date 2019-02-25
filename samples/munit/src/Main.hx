import tests.TestSuite2;
import massive.munit.client.RichPrintClient;
import massive.munit.TestRunner;
import massive.munit.Assert;

class Main {
	static function main() {
		var client = new RichPrintClient();
		var runner = new TestRunner(client);
		runner.run([TestSuite, TestSuite2]);
	}
}

class TestSuite extends massive.munit.TestSuite {
	public function new() {
		super();
		add(TestCase);
		add(TestCase2);
	}
}

class TestCase {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}

	@Test
	function testFailure() {
		Assert.areEqual("A", "B");
	}

	@Test
	function testError() {
		throw "error";
	}

	@Test
	function testEmpty() {}

	@Test @Ignore("Description")
	function testIgnore() {}
}

class TestCase2 {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}
}
