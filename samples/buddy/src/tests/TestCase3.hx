package tests;

using buddy.Should;

class TestCase3 extends buddy.SingleSuite {
	public function new() {
		describe("TestCase3", {
			it("testSuccess", {
				"A".should.be("A");
			});
		});
	}
}
