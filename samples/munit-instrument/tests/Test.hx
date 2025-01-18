import massive.munit.Assert;
import massive.munit.TestRunner;
import massive.munit.client.RichPrintClient;

class Test {
	static function main() {
		var client = new RichPrintClient();
		var runner = new TestRunner(client);
		runner.run([TestSuite]);

		#if instrument
		instrument.coverage.Coverage.endCoverage();
		#end
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
