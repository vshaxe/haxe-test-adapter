class Main {
	static function main() {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestCase());
		runner.add(new TestCase2());
		runner.run();
	}
}

class TestCase extends haxe.unit.TestCase {
	function testSuccess() {
		assertTrue(true);
	}
}

class TestCase2 extends haxe.unit.TestCase {
	function testSuccess() {
		assertTrue(true);
	}

	function testFailure() {
		assertTrue(false);
	}
}
