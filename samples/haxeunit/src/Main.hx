import tests.TestCase3;

class Main {
	static function main() {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestCase());
		runner.add(new TestCase2());
		runner.add(new TestCase3());
		runner.run();
	}
}

class TestCase extends haxe.unit.TestCase {
	function testSuccess() {
		assertTrue(true);
	}

	function testFailure() {
		assertEquals("A", "B");
	}

	function testError() {
		throw "error";
	}

	function testEmpty() {}
}

class TestCase2 extends haxe.unit.TestCase {
	function testSuccess() {
		assertTrue(true);
	}
}
