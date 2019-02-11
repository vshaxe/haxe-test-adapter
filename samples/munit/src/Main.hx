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
	}
}

class TestCase {
	@Test
	function testSuccess() {}
}

class TestCase2 {
	@Test
	function testSuccess() {}

	@Test
	function testFailure() {
		Assert.fail("failure");
	}
}
