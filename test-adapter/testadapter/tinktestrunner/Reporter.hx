package testadapter.tinktestrunner;

import testadapter.data.Data;
import testadapter.data.TestResults;

using tink.CoreApi;

class Reporter implements tink.testrunner.Reporter {
	var reporter:tink.testrunner.Reporter;
	var currentSuite:String;
	var currentCase:String;

	public var testResults:TestResults;

	public function new(baseFolder:String, reporter:tink.testrunner.Reporter) {
		testResults = new TestResults(baseFolder);
		if (reporter == null) {
			reporter = new tink.testrunner.Reporter.BasicReporter();
		}
		this.reporter = reporter;
	}

	public function report(type:tink.testrunner.Reporter.ReportType):Future<Noise> {
		switch (type) {
			case BatchStart:
			case BatchFinish(_):
				testResults.save();
			case SuiteStart(info):
				currentSuite = info.name;
			case CaseStart(info):
				currentCase = info.name;
				var clazz:Null<String> = testResults.positions.resolveClassName(info.pos.fileName, info.pos.lineNumber - 1);
				if (clazz != null) {
					currentSuite = clazz;
				}
			case Assertion(assertion):
				switch (assertion.holds) {
					case Success(_):
						testResults.add(currentSuite, currentCase, 0, TestState.Success);
					case Failure(msg):
						if (msg == null) {
							msg = assertion.description;
						}
						testResults.add(currentSuite, currentCase, 0, TestState.Failure, msg, assertion.pos.lineNumber - 1);
				}
			case CaseFinish(results):
				switch (results.results) {
					case Success(_):
					case Failure(msg):
						testResults.add(currentSuite, currentCase, 0, TestState.Error, msg.toString(), results.info.pos.lineNumber);
				}
			case SuiteFinish(_):
		}
		return reporter.report(type);
	}
}
