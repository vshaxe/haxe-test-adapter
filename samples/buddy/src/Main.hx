import buddy.BuddySuite;
import buddy.SuitesRunner;
import tests.TestCase3;

using buddy.Should;

class Main extends BuddySuite {
	public static function main() {
		new SuitesRunner([new Main(), new TestCase3()]).run();
	}

	public function new() {
		describe("TestCase", {
			it("testSuccess", {
				Sys.sleep(Math.random());
				"A".should.be("A");
			});

			it("testFailure", {
				Sys.sleep(Math.random());
				"A".should.be("B");
			});

			it("testError", {
				Sys.sleep(Math.random());
				throw "error";
			});

			it("testEmpty", {
				Sys.sleep(Math.random());
			});
		});

		describe("TestCase2", {
			it("testSuccess", {
				"A".should.be("A");
			});
		});
	}
}
