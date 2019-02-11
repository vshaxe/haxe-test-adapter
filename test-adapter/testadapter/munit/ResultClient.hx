package testadapter.munit;

import massive.munit.ITestResultClient;
import massive.munit.TestResult;
import testadapter.data.TestFilter;
import testadapter.data.TestResultData;

class ResultClient implements IAdvancedTestResultClient implements ICoverageTestResultClient {
	var testData:TestResultData;

	@:isVar public var completionHandler(get, set):ITestResultClient->Void;
	public var id(default, null):String;

	public function new(?baseFolder:String) {
		testData = new TestResultData(baseFolder);
	}

	function get_completionHandler():ITestResultClient->Void {
		return completionHandler;
	}

	function set_completionHandler(value:ITestResultClient->Void):ITestResultClient->Void {
		completionHandler = value;
		return completionHandler;
	}

	public function addPass(result:TestResult) {
		testData.addTestResult(result.className, result.name, result.executionTime, Success);
	}

	public function addFail(result:TestResult) {
		var message:String = null;
		var lineNumber:Null<Int> = null;
		if (result.failure != null) {
			message = result.failure.message;
			lineNumber = result.failure.info.lineNumber - 1;
		}
		testData.addTestResult(result.className, result.name, result.executionTime, Failure, message, lineNumber);
	}

	public function addError(result:TestResult) {
		testData.addTestResult(result.className, result.name, result.executionTime, Error, Std.string(result.error));
	}

	public function addIgnore(result:TestResult) {
		testData.addTestResult(result.className, result.name, result.executionTime, Ignore, result.description);
	}

	@SuppressWarnings("checkstyle:Dynamic")
	public function reportFinalStatistics(testCount:Int, passCount:Int, failCount:Int, errorCount:Int, ignoreCount:Int, time:Float):Dynamic {
		if (completionHandler != null) {
			completionHandler(this);
		}
		TestFilter.clearTestFilter();
		return null;
	}

	public function setCurrentTestClass(className:String) {}

	public function setCurrentTestClassCoverage(result:CoverageResult) {}

	public function reportFinalCoverage(?percent:Float = 0, missingCoverageResults:Array<CoverageResult>, summary:String, ?classBreakdown:String = null,
		?packageBreakdown:String = null, ?executionFrequency:String = null) {}
}
