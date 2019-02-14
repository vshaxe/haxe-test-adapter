import tests.TestCase3;
import buddy.BuddySuite;
import buddy.SuitesRunner;

using buddy.Should;

class Main extends BuddySuite {
	public static function main() {
		new SuitesRunner([new Main(), new TestCase3()]).run();
	}

	public function new() {
		describe("TestCase", {
			it("testSuccess", {
				"A".should.be("A");
			});

			it("testFailure", {
				"A".should.be("B");
			});

			it("testError", {
				throw "error";
			});

			it("testEmpty", {});
		});

		describe("TestCase2", {
			it("testSuccess", {
				"A".should.be("A");
			});
		});
	}
}
