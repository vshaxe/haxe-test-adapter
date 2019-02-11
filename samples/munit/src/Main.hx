import tests.TestCase3;
import massive.munit.client.RichPrintClient;
import massive.munit.TestRunner;
import massive.munit.Assert;

class Main {
	static function main() {
		var client = new RichPrintClient();
		var runner = new TestRunner(client);
		runner.run([TestSuite]);
	}
}

class TestSuite extends massive.munit.TestSuite {
	public function new() {
		super();
		add(TestCase);
		add(TestCase2);
		add(TestCase3);
	}
}

class TestCase {
	@Test
	function testSuccess() {}

	@Test
	function testFailure() {
		Assert.areEqual("A", "B");
	}

	@Test
	function testError() {
		throw "error";
	}

	@Test @Ignore("Description")
	function testIgnore() {}
}

class TestCase2 {
	@Test
	function testSuccess() {}
}
