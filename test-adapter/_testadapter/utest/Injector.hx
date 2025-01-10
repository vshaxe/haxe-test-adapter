package _testadapter.utest;

import haxe.macro.Compiler;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		final coverageEnabled:Null<String> = Context.definedValue("instrument-coverage");
		final baseFolder = haxe.io.Path.join([_testadapter.data.Data.FOLDER]);
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro new _testadapter.utest.Reporter(this, $v{Sys.getCwd()}));
				case "addCase": // utest 2.x support
					#if haxe4
					#if (utest >= version("2.0.0-alpha"))
					field.patch(Replace, macro {
						var className = Type.getClassName(Type.getClass(testCase));
						if (fixtures.exists(className)) {
							throw new UTestException('Cannot add the same test twice.');
						}
						var newFixtures = [];
						var init:utest.TestData.InitializeUtest = (cast testCase : utest.TestData.Initializer).__initializeUtest__();
						init.accessories.setup = clearCoverageForSetup(init.accessories.setup);
						var teardown = init.accessories.teardown;
						var cls:_testadapter.data.Data.SuiteId = ClassName(className);
						for (test in init.tests) {
							if (!isTestFixtureName(className, test.name, ['test', 'spec'], pattern, globalPattern)) {
								continue;
							}
							if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, cls, test.name)) {
								continue;
							}
							init.accessories.teardown = attributeCoverageInTeardown(teardown, cls, test.name);
							newFixtures.push(new utest.TestFixture(testCase, test, init.accessories));
						}
						if (newFixtures.length > 0) {
							fixtures.set(className, {
								caseInstance: testCase,
								setupClass: init.accessories.getSetupClass(),
								dependencies: #if UTEST_IGNORE_DEPENDS [] #else init.dependencies #end,
								fixtures: newFixtures,
								teardownClass: init.accessories.getTeardownClass()
							});
							length += newFixtures.length;
						}
					});
					#end
					#end
				case "addITest": // utest 1.x support
					field.patch(Replace, macro {
						var className = Type.getClassName(Type.getClass(testCase));
						if (iTestFixtures.exists(className)) {
							throw "Cannot add the same test twice.";
						}
						var fixtures = [];
						var init:utest.TestData.InitializeUtest = (cast testCase : utest.TestData.Initializer).__initializeUtest__();
						init.accessories.setup = clearCoverageForSetup(init.accessories.setup);
						var teardown = init.accessories.teardown;
						var cls:_testadapter.data.Data.SuiteId = ClassName(className);
						for (test in init.tests) {
							if (!isTestFixtureName(cls, test.name, ["test", "spec"], pattern, globalPattern)) {
								continue;
							}
							if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, cls, test.name)) {
								continue;
							}
							init.accessories.teardown = attributeCoverageInTeardown(teardown, cls, test.name);
							var fixture = utest.TestFixture.ofData(testCase, test, init.accessories);
							addFixture(fixture);
							fixtures.push(fixture);
						}
						if (fixtures.length <= 0) {
							return;
						}
						iTestFixtures.set(className, {
							caseInstance: testCase,
							setupClass: init.accessories.getSetupClass(),
							dependencies: init.dependencies,
							fixtures: fixtures,
							teardownClass: init.accessories.getTeardownClass()
						});
					});
			}
		}
		if (coverageEnabled != null) {
			var extraFields = (macro class {
				function clearCoverageForSetup(oldSetup:Null<() -> utest.Async>):() -> utest.Async {
					if (oldSetup == null) {
						return function() {
							instrument.coverage.Coverage.resetAttributableCoverage();
							return Async.getResolved();
						}
					}
					return function() {
						instrument.coverage.Coverage.resetAttributableCoverage();
						return oldSetup();
					}
				}

				function attributeCoverageInTeardown(oldTeardown:Null<() -> utest.Async>, className:String, testName:String):() -> utest.Async {
					final testCaseName = '$className.$testName.lcov';
					if (oldTeardown == null) {
						return function() {
							final path = haxe.io.Path.join([$v{baseFolder}, testCaseName]);
							final lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
							instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]);
							return Async.getResolved();
						}
					}
					return function() {
						final path = haxe.io.Path.join([$v{baseFolder}, testCaseName]);
						final lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
						instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]);
						return oldTeardown();
					}
				}
			}).fields;
			fields = fields.concat(extraFields);
		} else {
			var extraFields = (macro class {
				inline function clearCoverageForSetup(oldSetup:Null<() -> utest.Async>):Null<() -> utest.Async> {
					return oldSetup;
				}

				inline function attributeCoverageInTeardown(oldTeardown:Null<() -> utest.Async>, className:String, testName:String):Null<() -> utest.Async> {
					return oldTeardown;
				}
			}).fields;
			fields = fields.concat(extraFields);
		}
		return fields;
	}
}
#end
