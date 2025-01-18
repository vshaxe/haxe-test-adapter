import massive.munit.Assert;
import massive.munit.TestRunner;
import massive.munit.client.RichPrintClient;
import mcover.coverage.munit.client.MCoverPrintClient;

class Test {
	static function main() {
		// var client = new RichPrintClient();
		var client:MCoverPrintClient = new MCoverPrintClient();
		mcover.coverage.MCoverage.getLogger().addClient(new mcover.coverage.client.LcovPrintClient("mcover unittests"));

		var runner = new TestRunner(client);
		runner.run([TestSuite]);
	}
}

class TestSuite extends massive.munit.TestSuite {
	public function new() {
		super();
		add(TestMain);
	}
}

class TestMain {
	@Test
	function testDoNothing() {
		var main = new Main();

		Assert.isTrue(main.doNothing());
	}

	@Test
	function testDoSomething() {
		var main = new Main();

		Assert.isTrue(main.doSomething(false));
	}

	@Test
	function testDoSomethingFullCoverage() {
		var main = new Main();

		Assert.isTrue(main.doSomethingFullCoverage(false));
		Assert.isFalse(main.doSomethingFullCoverage(true));
	}
}
