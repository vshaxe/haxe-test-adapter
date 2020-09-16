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
			describe("TestCase", {
				it("testSuccess", {
					"A".should.be("A");
				});
			});
			it("testSuccess", {
				"A".should.be("A");
			});
			describe("innerTestCase3", {
				it("testSuccess", {
					"A".should.be("A");
				});
				it("testSuccess2", {
					"A".should.be("A");
				});
			});
		});
	}
}
