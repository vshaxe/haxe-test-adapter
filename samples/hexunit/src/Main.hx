import tests.TestCase3;
import hex.unittest.assertion.Assert;
import hex.unittest.runner.ExMachinaUnitCore;
import hex.unittest.notifier.TraceNotifier;

class Main {
	static function main() {
		var emu = new ExMachinaUnitCore();

		emu.addListener(new TraceNotifier());
		emu.addTest(TestCase);
		emu.addTest(TestCase2);
		tests.TestCase.addSelf(emu);
		emu.addTest(TestCase3);
		emu.run();
	}
}

class TestCase {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}

	@Test
	function testFailure() {
		Assert.equals("A", "B");
	}

	@Test
	function testError() {
		throw "failure";
	}

	@Test
	function testEmpty() {}

	@Ignore
	function testIgnore() {}
}

class TestCase2 {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}
}
