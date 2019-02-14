import tests.TestCase3;
import buddy.BuddySuite;

using buddy.Should;

import buddy.reporting.ConsoleReporter;

class Main extends BuddySuite {
	public static function main() {
		var reporter = new ConsoleReporter();
		var runner = new buddy.SuitesRunner([new Main(), new TestCase3()], reporter);
		runner.run();
	}

	public function new() {
		describe("TestCase", {
			beforeEach({});

			it("should succeed", {
				"A".should.be("A");
			});

			it("should fail", {
				"A".should.be("B");
			});

			it("should throw", {
				throw "error";
			});

			it("should also succeed", {});

			afterEach({});
		});
	}
}
