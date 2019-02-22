package _testadapter.munit;

import massive.munit.ITestResultClient;
import massive.munit.TestResult;
import _testadapter.data.TestResults;

class ResultClient implements IAdvancedTestResultClient implements ICoverageTestResultClient {
	var testResults:TestResults;

	@:isVar public var completionHandler(get, set):ITestResultClient->Void;
	public var id(default, null):String;

	public function new(baseFolder) {
		testResults = new TestResults(baseFolder);
	}

	function get_completionHandler():ITestResultClient->Void {
		return completionHandler;
	}

	function set_completionHandler(value:ITestResultClient->Void):ITestResultClient->Void {
		return completionHandler = value;
	}

	public function addPass(result:TestResult) {
		testResults.add(result.className, result.name, result.executionTime, Success);
	}

	public function addFail(result:TestResult) {
		var message:String = null;
		var lineNumber:Null<Int> = null;
		if (result.failure != null) {
			message = result.failure.message;
			lineNumber = result.failure.info.lineNumber - 1;
		}
		testResults.add(result.className, result.name, result.executionTime, Failure, message, lineNumber);
	}

	public function addError(result:TestResult) {
		testResults.add(result.className, result.name, result.executionTime, Error, Std.string(result.error));
	}

	public function addIgnore(result:TestResult) {
		testResults.add(result.className, result.name, result.executionTime, Ignore, result.description);
	}

	public function reportFinalStatistics(testCount:Int, passCount:Int, failCount:Int, errorCount:Int, ignoreCount:Int, time:Float):Dynamic {
		if (completionHandler != null) {
			completionHandler(this);
		}
		testResults.save();
		return null;
	}

	public function setCurrentTestClass(className:String) {}

	public function setCurrentTestClassCoverage(result:CoverageResult) {}

	public function reportFinalCoverage(?percent:Float = 0, missingCoverageResults:Array<CoverageResult>, summary:String, ?classBreakdown:String = null,
		?packageBreakdown:String = null, ?executionFrequency:String = null) {}
}
