import tests.TestCase3;
import hex.unittest.runner.ExMachinaUnitCore;
import hex.unittest.assertion.Assert;
import hex.unittest.notifier.ConsoleNotifier;

class Main {
	static function main() {
		var emu = new ExMachinaUnitCore();

		emu.addListener(new ConsoleNotifier());
		emu.addTest(TestCase);
		emu.addTest(TestCase2);
		emu.addTest(TestCase3);
		emu.run();
	}
}

class TestCase {
	@Test("Description")
	function testSuccess() {
		Assert.isTrue(true);
	}

	@Test("Description")
	function testFailure() {
		Assert.equals("A", "B");
	}

	@Test("Description")
	function testError() {
		throw "failure";
	}

	@Test("Description")
	function testEmpty() {}

	@Ignore("Description")
	function testIgnore() {}
}

class TestCase2 {
	@Test("Description")
	function testSuccess() {
		Assert.isTrue(true);
	}
}
