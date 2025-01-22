package _testadapter.tink_unittest;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		var coverageEnabled:Null<String> = Context.definedValue("instrument-coverage");
		for (field in fields) {
			switch (field.name) {
				case "run":
					if (coverageEnabled != null) {
						field.addInit(Start, macro reporter = new _testadapter.tink_unittest.AttributableReporter($v{Sys.getCwd()}, reporter));
					} else {
						field.addInit(Start, macro reporter = new _testadapter.tink_unittest.Reporter($v{Sys.getCwd()}, reporter));
					}
				case "runCase":
					field.patch(Start, macro {
						var suiteId:_testadapter.data.Data.SuiteId = SuiteNameAndPos(suite.info.name, suite.info.pos.fileName, suite.info.pos.lineNumber - 1);
						if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, suiteId, caze.info.name)) {
							return Future.async(function(cb) {
								cb({
									info: caze.info,
									result: tink.testrunner.CaseResultType.Succeeded([])
								});
							});
						}
					});
				case _:
			}
		}
		return fields;
	}
}
#end
