package testadapter.utest;

import haxe.CallStack;
import testadapter.data.TestFilter;
import testadapter.data.TestResultData;
import utest.Assertation;
import utest.Runner;
import utest.ui.common.ClassResult;
import utest.ui.common.FixtureResult;
import utest.ui.common.HeaderDisplayMode;
import utest.ui.common.IReport;
import utest.ui.common.PackageResult;
import utest.ui.common.ResultAggregator;

class Reporter implements IReport<Reporter> {
	public var displaySuccessResults:SuccessResultsDisplayMode;
	public var displayHeader:HeaderDisplayMode;

	var testData:TestResultData;
	var aggregator:ResultAggregator;

	public function new(runner:Runner, ?baseFolder:String) {
		testData = new TestResultData(baseFolder);
		displaySuccessResults = NeverShowSuccessResults;
		displayHeader = NeverShowHeader;
		aggregator = new ResultAggregator(runner, true);
		aggregator.onComplete.add(complete);
	}

	@SuppressWarnings("checkstyle:NestedForDepth")
	function complete(result:PackageResult) {
		for (pname in result.packageNames()) {
			var pack:PackageResult = result.getPackage(pname);
			for (cname in pack.classNames()) {
				var cls:ClassResult = pack.getClass(cname);
				var classSuiteName:String = getClassName(pname, cname);
				for (mname in cls.methodNames()) {
					var fix:FixtureResult = cls.get(mname);
					var testName:String = getTestName(pname, cname, mname);

					if (fix.stats.isOk) {
						if (fix.stats.hasIgnores) {
							testData.addIgnore(classSuiteName, mname, testName);
							continue;
						}
						// TODO execution time
						testData.addPass(classSuiteName, mname, testName, 0);
						continue;
					}

					var details = "";
					for (assertation in fix.iterator()) {
						switch (assertation) {
							case Assertation.Success(_):
							case Assertation.Failure(msg, pos):
								details += "line: " + pos.lineNumber + ", " + msg;
							case Assertation.Error(e, s):
								details += Std.string(e) + dumpStack(s);
							case Assertation.SetupError(e, s):
								details += Std.string(e) + dumpStack(s);
							case Assertation.TeardownError(e, s):
								details += Std.string(e) + dumpStack(s);
							case Assertation.TimeoutError(missedAsyncs, s):
								details += "missed async calls: " + missedAsyncs + dumpStack(s);
							case Assertation.AsyncError(e, s):
								details += Std.string(e) + dumpStack(s);
							case Assertation.Warning(msg):
								details += msg;
							case Assertation.Ignore(reason):
								if (reason != null && reason != "") {
									details += 'With reason: ${reason}';
								}
						}
					}
					testData.addFail(classSuiteName, mname, testName, 0, details);
				}
			}
		}
		TestFilter.clearTestFilter();
	}

	function getClassName(pack:String, className:String):String {
		if (pack == "") {
			return className;
		}
		return '${StringTools.replace(pack, ".", "_")}.${className}';
	}

	function getTestName(pack:String, className:String, methodName:String):String {
		return '${getClassName(pack, className)}#${methodName}';
	}

	function dumpStack(stack:Array<StackItem>):String {
		if (stack.length == 0) {
			return "";
		}
		var parts = CallStack.toString(stack).split("\n");
		var r = [];
		for (part in parts) {
			if (part.indexOf(" utest.") >= 0) {
				continue;
			}
			r.push(part);
		}
		return r.join("\n");
	}

	public function setHandler(handler:Reporter->Void) {}
}
