package _testadapter.buddy; #if macro

import haxe.macro.Context; import haxe.macro.Expr; using haxe.macro.ExprTools; using _testadapter.PatchTools; class Injector {

	public static function buildRunner():Array<Field> {
		var coverageEnabled:Null<String> = Context.definedValue("instrument-coverage");
		var baseFolder = haxe.io.Path.join([_testadapter.data.Data.FOLDER]);

		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro {
						adapterReporter = new _testadapter.buddy.Reporter($v{Sys.getCwd()}, reporter);
						this.reporter = adapterReporter;
					});
				case "mapTestSpec" if (coverageEnabled != null):
					field.patch(Start, macro switch (testSpec) {
						case It(description, _, _, pos, _):
							var suiteId:_testadapter.data.Data.SuiteId = SuiteNameAndPos(testSuite.description, pos.fileName, pos.lineNumber);
							adapterReporter.addPosition(suiteId, description, pos.fileName, pos.lineNumber - 1);

							// create shallow copies of both before+after arrays
							// so we don't mess up the data structures outside of our small patch
							beforeEachStack = beforeEachStack.copy();
							beforeEachStack.unshift([Sync(_ -> instrument.coverage.Coverage.resetAttributableCoverage())]);
							afterEachStack = afterEachStack.copy();
							var regEx = ~/[^a-zA-Z0-9_-]/g;
							var testCaseName = regEx.replace('${suiteId}_$description.lcov', "_");
							var path = haxe.io.Path.join([$v{baseFolder}, testCaseName]);
							var lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
							afterEachStack.unshift([
								Sync(_ -> instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]))
							);
						case _:
					});
					switch (field.kind) {
						case FFun(f):
							replaceSpec(f.expr);
						case _:
					}
				case "mapTestSpec":
					field.patch(Start, macro switch (testSpec) {
						case It(description, _, _, pos, _):
							var suiteId:_testadapter.data.Data.SuiteId = SuiteNameAndPos(testSuite.description, pos.fileName, pos.lineNumber);
							adapterReporter.addPosition(suiteId, description, pos.fileName, pos.lineNumber - 1);
						case _:
					});
					switch (field.kind) {
						case FFun(f):
							replaceSpec(f.expr);
						case _:
					}
				case _:
			}
		}

		var extraFields = (macro class {
			var adapterReporter:_testadapter.buddy.Reporter;
		}).fields;
		return fields.concat(extraFields);
	}

	public static function buildSuite():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (field.name == "it" || field.name == "xit") {
				field.patch(Start, macro {
					var prefix:String = fullDescribePath(suite, currentSuite);
					if (prefix == null) {
						prefix = "";
					}
					var suiteId:_testadapter.data.Data.SuiteId = SuiteNameAndFile(prefix + currentSuite.description, pos.fileName);
					if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, suiteId, desc)
						&& !_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, suiteId, desc + _testadapter.buddy.Reporter.PENDING_POSTFIX)) {
						return;
					}
				});
			}
		}

		var extraFields = (macro class {
			function fullDescribePath(root:TestSuite, search:TestSuite):Null<String> {
				for (childSpec in root.specs) {
					switch (childSpec) {
						case Describe(child, _):
							if (child == search) {
								if (root.description.length <= 0) {
									return root.description;
								} else {
									return root.description + ".";
								}
							}
							var path:Null<String> = fullDescribePath(child, search);
							if (path != null) {
								var prefix:String = root.description;
								if (prefix.length > 0) {
									prefix += ".";
								}
								return prefix + path;
							}
						case _:
					}
				}
				return null;
			}
		}).fields;

		return fields.concat(extraFields);
	}

	static function replaceSpec(func:Expr):Expr {
		switch (func.expr) {
			case EBinop(OpAssign, e1, e2):
				switch (e2.expr) {
					case ENew(t, params):
						if (t.name == "Spec") {
							e2.expr = (macro new _testadapter.buddy.Spec(desc, pos)).expr;
						}
					case _:
						func.map(replaceSpec);
				}
				return null;
			case _:
				func.map(replaceSpec);
		}
		return null;
	}
}
#end
