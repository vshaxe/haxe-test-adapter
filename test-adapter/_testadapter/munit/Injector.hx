package _testadapter.munit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		var coverageEnabled:Null<String> = Context.definedValue("instrument-coverage");
		var baseFolder = haxe.io.Path.join([_testadapter.data.Data.FOLDER]);
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro addResultClient(new _testadapter.munit.ResultClient($v{Sys.getCwd()})));
				case "executeTestCases":
					field.patch(Replace, macro {
						#if (haxe_ver > 4.10)
						var isOfType = Std.isOfType;
						#else
						var isOfType = Std.is;
						#end
						for (c in clients) {
							if (isOfType(c, IAdvancedTestResultClient) && activeHelper.hasNext()) {
								var cl:IAdvancedTestResultClient = cast c;
								cl.setCurrentTestClass(activeHelper.className);
							}
						}
						activeHelper.before = clearCoverageForBefore(activeHelper.before);
						var afterFunc = activeHelper.after;
						for (testCaseData in activeHelper) {
							if (testCaseData.result.ignore) {
								ignoreCount++;
								for (c in clients)
									c.addIgnore(cast testCaseData.result);
							} else {
								activeHelper.after = attributeCoverageInAfter(afterFunc, activeHelper.className, testCaseData.result.name);
								testCount++; // note we don't include ignored in final test count
								tryCallMethod(activeHelper.test, activeHelper.before, emptyParams);
								testStartTime = Timer.stamp();
								executeTestCase(testCaseData, testCaseData.result.async);
								if (!asyncPending)
									tryCallMethod(activeHelper.test, activeHelper.after, emptyParams);
								else
									break;
							}
						}
					});
			}
		}
		if (coverageEnabled != null) {
			var extraFields = (macro class {
				function clearCoverageForBefore(oldBefore:Null<haxe.Constraints.Function>):haxe.Constraints.Function {
					if (oldBefore == null) {
						return function() {
							instrument.coverage.Coverage.resetAttributableCoverage();
						}
					}
					return function() {
						instrument.coverage.Coverage.resetAttributableCoverage();
						oldBefore();
					}
				}

				function attributeCoverageInAfter(oldAfter:haxe.Constraints.Function, className:String, testName:String):haxe.Constraints.Function {
					var testCaseName = '$className.$testName.lcov';
					if (oldAfter == null) {
						return function() {
							var path = haxe.io.Path.join([$v{baseFolder}, testCaseName]);
							var lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
							instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]);
						}
					}
					return function() {
						var path = haxe.io.Path.join([$v{baseFolder}, testCaseName]);
						var lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
						instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]);
						oldAfter();
					}
				}
			}).fields;
			fields = fields.concat(extraFields);
		} else {
			var extraFields = (macro class {
				inline function clearCoverageForBefore(oldBefore:Null<haxe.Constraints.Function>):Null<haxe.Constraints.Function> {
					return oldBefore;
				}

				inline function attributeCoverageInAfter(oldAfter:Null<haxe.Constraints.Function>, className:String,
						testName:String):Null<haxe.Constraints.Function> {
					return oldAfter;
				}
			}).fields;
			fields = fields.concat(extraFields);
		}
		return fields;
	}

	public static function buildHelper():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "scanForTests":
					field.patch(End, macro if (tests.length <= 0) {
						beforeClass = nullFunc;
						afterClass = nullFunc;
						before = nullFunc;
						after = nullFunc;
					});
				case "addTest":
					field.patch(Start, macro {
						var suiteId:_testadapter.data.Data.SuiteId = ClassName(className);
						if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, suiteId, field)) {
							return;
						}
					});
				case "after" | "before":
					switch (field.kind) {
						case FVar(t, e):
						case FFun(f):
						case FProp(get, set, t, e):
							field.kind = FVar(t, e);
					}
				case _:
			}
		}

		return fields;
	}
}
#end
