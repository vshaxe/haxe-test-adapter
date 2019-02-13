package tests;

using buddy.Should;

class TestCase3 extends buddy.SingleSuite {
	public function new() {
		// A test suite:
		describe("TestCase3", {
			it("should succeed", {
				"A".should.be("A");
			});
		});
	}
}
