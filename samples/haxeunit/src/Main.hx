class Main {
	static function main() {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestCase());
		runner.run();
	}
}

class TestCase extends haxe.unit.TestCase {
	function testSuccess() {
		assertEquals("A", "A");
	}

	function testFailure() {
		assertEquals("A", "B");
	}
}
