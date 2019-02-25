package tests;

import hex.unittest.runner.ExMachinaUnitCore;
import hex.unittest.assertion.Assert;

class TestCase {
	@Test
	function testSuccess() {
		Assert.isTrue(true);
	}

	public static function addSelf(emu:ExMachinaUnitCore) {
		emu.addTest(TestCase);
	}
}
