package _testadapter.instrument;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildCoverage():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (field.name == "endCoverage") {
				field.patch(End, macro {
					var reporter = new instrument.coverage.reporter.LcovCoverageReporter(haxe.io.Path.join([_testadapter.data.Data.FOLDER, "lcov.info"]));
					endCustomCoverage([reporter]);
				});
			}
		}
		return fields;
	}
}
#end
