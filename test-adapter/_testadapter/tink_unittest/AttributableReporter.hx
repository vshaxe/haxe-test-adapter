package _testadapter.tink_unittest;

import haxe.macro.Context;
import _testadapter.data.Data;
import _testadapter.data.TestResults;

using tink.CoreApi;

class AttributableReporter implements tink.testrunner.Reporter {
	var reporter:tink.testrunner.Reporter;
	var currentSuiteId:SuiteId;
	var currentCaseId:TestIdentifier;
	var baseFolder:String;

	public var testResults:TestResults;

	public function new(baseFolder:String, reporter:tink.testrunner.Reporter) {
		testResults = new TestResults(baseFolder);
		if (reporter == null) {
			reporter = new tink.testrunner.Reporter.BasicReporter();
		}
		this.reporter = reporter;
		this.baseFolder = _testadapter.data.Data.FOLDER;
	}

	public function report(type:tink.testrunner.Reporter.ReportType):Future<Noise> {
		switch (type) {
			case BatchStart:
			case BatchFinish(_):
				testResults.save();
			case SuiteStart(info, _):
				currentSuiteId = SuiteNameAndPos(info.name, info.pos.fileName, info.pos.lineNumber - 1);
			case CaseStart(info, _):
				currentCaseId = TestNameAndPos(info.name, info.pos.fileName, info.pos.lineNumber - 1);
				instrument.coverage.Coverage.resetAttributableCoverage();
			case Assertion(assertion):
				switch (assertion.holds) {
					case Success(_):
						testResults.add(currentSuiteId, currentCaseId, null, TestState.Success);
					case Failure(msg):
						if (msg == null) {
							msg = assertion.description;
						}
						testResults.add(currentSuiteId, currentCaseId, null, TestState.Failure, msg,
							{line: assertion.pos.lineNumber - 1, file: assertion.pos.fileName});
				}
			case CaseFinish(result):
				var name = switch (currentCaseId) {
					case TestName(name): name;
					case TestNameAndPos(name, fileName, lineNumber): name;
				}

				var testCaseName:LCOVFileName = '${currentSuiteId}.$name.lcov';
				var path = haxe.io.Path.join([baseFolder, testCaseName]);
				var lcovReporter = new instrument.coverage.reporter.LcovCoverageReporter(path);
				instrument.coverage.Coverage.reportAttributableCoverage([lcovReporter]);

				switch (result.result) {
					case Failed(msg):
						testResults.add(currentSuiteId, currentCaseId, null, TestState.Error, msg.toString(),
							{line: msg.pos.lineNumber - 1, file: msg.pos.fileName});
					case Succeeded(asserts):
						if ((asserts == null) || (asserts.length <= 0)) {
							testResults.add(currentSuiteId, currentCaseId, null, TestState.Success);
						}
					case Excluded:
						testResults.add(currentSuiteId, currentCaseId, null, TestState.Ignore);
				}
			case SuiteFinish(_):
		}
		return reporter.report(type);
	}
}
