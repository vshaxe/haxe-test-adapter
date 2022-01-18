package _testadapter.buddy;

import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Step;
import buddy.BuddySuite.Suite;
import buddy.reporting.ConsoleReporter;
import _testadapter.data.Data;
import _testadapter.data.TestResults;

class Reporter implements buddy.reporting.Reporter {
	var testResults:TestResults;
	var baseReporter:buddy.reporting.Reporter;

	public function new(baseFolder:String, baseReporter:buddy.reporting.Reporter) {
		testResults = new TestResults(baseFolder);
		if (baseReporter == null) {
			baseReporter = new ConsoleReporter();
		}
		this.baseReporter = baseReporter;
	}

	public function addPosition(suiteName, description:String, fileName:String, lineNumber:Int) {
		var pos:Pos = {file: fileName, line: lineNumber};
		testResults.positions.add(suiteName, description, pos);
	}

	public function start() {
		return baseReporter.start();
	}

	public function progress(spec:Spec) {
		return baseReporter.progress(spec);
	}

	public function done(suites:Iterable<Suite>, status:Bool) {
		var duplicateNames:Map<String, Int> = new Map<String, Int>();
		function uniqueSuiteName(suiteName:String):String {
			if (duplicateNames.exists(suiteName)) {
				var count:Int = duplicateNames.get(suiteName);
				count++;
				duplicateNames.set(suiteName, count);
				suiteName = '$suiteName <$count>';
			} else {
				duplicateNames.set(suiteName, 1);
			}
			return suiteName;
		}

		function iterateSteps(suiteName:String, steps:Array<Step>) {
			for (step in steps) {
				switch step {
					case TSpec(spec):
						reportSpec(suiteName, spec);
					case TSuite(s):
						if (suiteName == "") {
							iterateSteps(uniqueSuiteName(s.description), s.steps);
						} else {
							iterateSteps(uniqueSuiteName(suiteName + "." + s.description), s.steps);
						}
				}
			}
		}
		for (suite in suites) {
			iterateSteps("", suite.steps);
		}

		testResults.save();
		return baseReporter.done(suites, status);
	}

	function reportSpec(suiteName:String, spec:Spec) {
		var testSpec:_testadapter.buddy.Spec = cast spec;
		var suiteId:SuiteId = SuiteNameAndFile(suiteName, spec.fileName);
		var testId:TestIdentifier = TestNameAndPos(spec.description, spec.fileName, testSpec.pos.lineNumber - 1);
		switch (spec.status) {
			case Failed:
				var message:String = "";
				var lineNumber:Null<Int> = null;
				for (failure in spec.failures) {
					message = failure.error;
					for (s in failure.stack) {
						switch (s) {
							case FilePos(_, _, line):
								if (lineNumber == null) {
									lineNumber = line - 1;
								}
								if (line < lineNumber) {
									lineNumber = line - 1;
								}
							case(_):
						}
					}
				}
				testResults.add(suiteId, testId, spec.time * 1000, Failure, message, lineNumber);
			case Passed:
				testResults.add(suiteId, testId, spec.time * 1000, Success);
			case Pending:
				testResults.add(suiteId, testId, spec.time * 1000, Success);
			case Unknown:
				testResults.add(suiteId, testId, spec.time * 1000, Error);
		}
	}
}
