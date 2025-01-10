package _testadapter.utest;

import haxe.CallStack;
import utest.Assertation;
import utest.Runner;
import utest.ui.common.ClassResult;
import utest.ui.common.FixtureResult;
import utest.ui.common.HeaderDisplayMode;
import utest.ui.common.IReport;
import utest.ui.common.PackageResult;
import utest.ui.common.ResultAggregator;
import _testadapter.data.Data.Pos;
import _testadapter.data.Data.TestState;
import _testadapter.data.TestResults;

class Reporter implements IReport<Reporter> {
	public var displaySuccessResults:SuccessResultsDisplayMode;
	public var displayHeader:HeaderDisplayMode;

	var testResults:TestResults;
	var aggregator:ResultAggregator;

	public function new(runner:Runner, baseFolder:String) {
		testResults = new TestResults(baseFolder);
		displaySuccessResults = NeverShowSuccessResults;
		displayHeader = NeverShowHeader;
		aggregator = new ResultAggregator(runner, true);
		aggregator.onComplete.add(complete);
	}

	function complete(result:PackageResult) {
		for (packageName in result.packageNames()) {
			var pack:PackageResult = result.getPackage(packageName);
			for (className in pack.classNames()) {
				var cls:ClassResult = pack.getClass(className);
				for (testName in cls.methodNames()) {
					var fix:FixtureResult = cls.get(testName);
					var message = null;
					var state:TestState = Failure;
					var errorPos:Null<Pos> = null;
					for (assertation in fix.iterator()) {
						switch (assertation) {
							case Assertation.Success(_):
								state = Success;
							case Assertation.Failure(msg, pos):
								state = Failure;
								message = msg;
								errorPos = {line: pos.lineNumber - 1, file: pos.fileName};
								break;
							case Assertation.Error(e, s), Assertation.SetupError(e, s), Assertation.TeardownError(e, s), Assertation.AsyncError(e, s):
								state = Error;
								message = Std.string(e) + dumpStack(s);
								break;
							case Assertation.TimeoutError(missedAsyncs, s):
								state = Error;
								message = "missed async calls: " + missedAsyncs + dumpStack(s);
								break;
							case Assertation.Warning(msg):
								state = Failure; // ?
								message = msg;
								break;
							case Assertation.Ignore(reason):
								state = Ignore;
								message = reason;
						}
					}
					var dotPath = if (packageName == "") className else '$packageName.$className';
					var executionTime:Null<Float> = null;
					if (Reflect.hasField(fix, "executionTime")) {
						executionTime = Reflect.field(fix, "executionTime");
					}
					testResults.add(ClassName(dotPath), TestName(testName), executionTime, state, message, errorPos);
				}
			}
		}
		testResults.save();
	}

	function dumpStack(stack:Stack):String {
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

#if haxe4
#if (utest >= version("2.0.0-alpha"))
typedef Stack = CallStack;
#else
typedef Stack = Array<StackItem>;
#end
#else
typedef Stack = Array<StackItem>;
#end
