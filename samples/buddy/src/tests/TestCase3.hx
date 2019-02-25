package tests;

using buddy.Should;

class TestCase3 extends buddy.SingleSuite {
	public function new() {
		describe("TestCase", {
			it("testSuccess", {
				"A".should.be("A");
			});
		});
		describe("TestCase3", {
			it("testSuccess", {
				"A".should.be("A");
			});
		});
	}
}
