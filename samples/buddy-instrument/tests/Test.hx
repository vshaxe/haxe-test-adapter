import buddy.BuddySuite;
import buddy.SuitesRunner;

using buddy.Should;

class Test extends BuddySuite {
	public static function main() {
		new SuitesRunner([new Test()]).run().then(function(runner) {
			#if instrument
			instrument.coverage.Coverage.endCoverage();
			#end
		});
	}

	public function new() {
		describe("TestMain", {
			it("should do nothing", {
				var main = new Main();

				main.doNothing().should.be(true);
			});
			it("should do something", {
				var main = new Main();

				main.doSomething(false).should.be(true);
			});

			it("should do something with full coverage", {
				var main = new Main();

				main.doSomethingFullCoverage(false).should.be(true);
				main.doSomethingFullCoverage(true).should.be(false);
			});
		});
	}
}
