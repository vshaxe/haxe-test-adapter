package tests;

class TestSuite2 extends massive.munit.TestSuite {
	public function new() {
		super();
		add(TestCase);
		add(TestCase3);
	}
}
