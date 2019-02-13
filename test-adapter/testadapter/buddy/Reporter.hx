package testadapter.buddy;

import testadapter.data.Data.TestState;
import haxe.CallStack;
import testadapter.data.Data;
import testadapter.data.TestResults;
import buddy.reporting.ConsoleReporter;
import buddy.BuddySuite.Spec;
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

	public function addPosition(fileName:String, description:String, lineNumber:Int) {
		var pos:Pos = {file: fileName, line: lineNumber};
		testResults.positions.add(fileName, description, pos);
	}

	public function start() {
		return baseReporter.start();
	}

	public function progress(spec:Spec) {
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
				testResults.add(spec.fileName, spec.description, spec.time, Failure, message, lineNumber);
			case Passed:
				testResults.add(spec.fileName, spec.description, spec.time, Success);
			case Pending:
			case Unknown:
				testResults.add(spec.fileName, spec.description, spec.time, Error);
		}
		return baseReporter.progress(spec);
	}

	public function done(suites:Iterable<Suite>, status:Bool) {
		testResults.save();
		return baseReporter.done(suites, status);
	}
}
