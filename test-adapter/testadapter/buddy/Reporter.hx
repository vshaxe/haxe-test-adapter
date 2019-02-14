package testadapter.buddy;

import testadapter.data.Data.TestState;
import haxe.CallStack;
import testadapter.data.Data;
import testadapter.data.TestResults;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Step;
import buddy.BuddySuite.Suite;

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
		function iterateSteps(suiteName:String, steps:Array<Step>) {
			for (step in steps) {
				switch step {
					case TSpec(spec):
						reportSpec(suiteName, spec);
					case TSuite(s):
						suiteName = s.description;
						iterateSteps(suiteName, s.steps);
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
				testResults.add(suiteName, spec.description, spec.time, Failure, message, lineNumber);
			case Passed:
				testResults.add(suiteName, spec.description, spec.time, Success);
			case Pending:
				testResults.add(suiteName, spec.description, spec.time, Success);
			case Unknown:
				testResults.add(suiteName, spec.description, spec.time, Error);
		}
	}
}
