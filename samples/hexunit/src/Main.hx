import hex.unittest.assertion.Assert;
import hex.unittest.notifier.TraceNotifier;
import hex.unittest.runner.ExMachinaUnitCore;
import tests.TestCase3;

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
		Sys.sleep(Math.random());
		Assert.isTrue(true);
	}

	@Test
	function testFailure() {
		Sys.sleep(Math.random());
		Assert.equals("A", "B");
	}

	@Test
	function testError() {
		Sys.sleep(Math.random());
		throw "failure";
	}

	@Test
	function testEmpty() {
		Sys.sleep(Math.random());
	}

	@Ignore
	function testIgnore() {}
}

class TestCase2 {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}
}
