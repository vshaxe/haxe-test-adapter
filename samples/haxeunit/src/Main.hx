import tests.TestCase3;

class Main {
	static function main() {
		var runner = new haxe.unit.TestRunner();
		runner.add(new TestCase());
		runner.add(new TestCase2());
		runner.add(new tests.TestCase());
		runner.add(new TestCase3());
		runner.run();
	}
}

class TestCase extends haxe.unit.TestCase {
	function testSuccess() {
		Sys.sleep(Math.random());
		assertTrue(true);
	}

	function testFailure() {
		Sys.sleep(Math.random());
		assertEquals("A", "B");
	}

	function testError() {
		Sys.sleep(Math.random());
		throw "error";
	}

	function testEmpty() {
		Sys.sleep(Math.random());
	}
}

class TestCase2 extends haxe.unit.TestCase {
	function testSuccess() {
		assertTrue(true);
	}
}
