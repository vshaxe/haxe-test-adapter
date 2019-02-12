package testadapter.utest;

import testadapter.data.Data.TestState;
import haxe.CallStack;
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

	public function new(runner:Runner, baseFolder:String) {
		testData = new TestResultData(baseFolder);
		displaySuccessResults = NeverShowSuccessResults;
		displayHeader = NeverShowHeader;
		aggregator = new ResultAggregator(runner, true);
		aggregator.onComplete.add(complete);
	}

	@SuppressWarnings("checkstyle:NestedForDepth")
	function complete(result:PackageResult) {
		for (packageName in result.packageNames()) {
			var pack:PackageResult = result.getPackage(packageName);
			for (className in pack.classNames()) {
				var cls:ClassResult = pack.getClass(className);
				for (testName in cls.methodNames()) {
					var fix:FixtureResult = cls.get(testName);
					var message = null;
					var state = TestState.Failure;
					var errorLine:Null<Int> = null;
					for (assertation in fix.iterator()) {
						switch (assertation) {
							case Assertation.Success(_):
								state = Success;
							case Assertation.Failure(msg, pos):
								state = Failure;
								message = msg;
								errorLine = pos.lineNumber - 1;
							case Assertation.Error(e, s), Assertation.SetupError(e, s), Assertation.TeardownError(e, s), Assertation.AsyncError(e, s):
								state = Error;
								message = Std.string(e) + dumpStack(s);
							case Assertation.TimeoutError(missedAsyncs, s):
								state = Error;
								message = "missed async calls: " + missedAsyncs + dumpStack(s);
							case Assertation.Warning(msg):
								state = Failure; // ?
								message = msg;
							case Assertation.Ignore(reason):
								state = Ignore;
								message = reason;
						}
					}
					var dotPath = if (packageName == "") className else '$packageName.$className';
					testData.addTestResult(dotPath, testName, 0, state, message, errorLine);
				}
			}
		}
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
