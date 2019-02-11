package testadapter.utest;

import testadapter.data.Data.TestState;
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

using StringTools;

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
					var details = null;
					var state = TestState.Failure;
					var errorLine = null;
					for (assertation in fix.iterator()) {
						switch (assertation) {
							case Assertation.Success(_):
								state = Success;
							case Assertation.Failure(msg, pos):
								state = Failure;
								details = msg;
								errorLine = pos.lineNumber - 1;
							case Assertation.Error(e, s), Assertation.SetupError(e, s), Assertation.TeardownError(e, s), Assertation.AsyncError(e, s):
								state = Error;
								details = Std.string(e) + dumpStack(s);
							case Assertation.TimeoutError(missedAsyncs, s):
								state = Error;
								details = "missed async calls: " + missedAsyncs + dumpStack(s);
							case Assertation.Warning(msg):
								state = Failure; // ?
								details = msg;
							case Assertation.Ignore(reason):
								state = Ignore;
								details = reason;
						}
					}
					testData.addTestResult(classSuiteName, mname, 0, state, details, errorLine);
				}
			}
		}
		TestFilter.clearTestFilter();
	}

	function getClassName(pack:String, className:String):String {
		if (pack == "") {
			return className;
		}
		return '${pack.replace(".", "_")}.${className}';
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
