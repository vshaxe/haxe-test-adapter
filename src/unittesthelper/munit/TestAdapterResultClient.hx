package unittesthelper.munit;

import massive.munit.ITestResultClient;
import massive.munit.TestResult;
import unittesthelper.data.TestPos;
import unittesthelper.data.TestPosCache;
import unittesthelper.data.TestResultData;
import unittesthelper.data.SingleTestResultState;

class TestAdapterResultClient implements IAdvancedTestResultClient implements ICoverageTestResultClient {
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

	function addTestResult(result:TestResult, state:SingleTestResultState, pos:TestPos, errorText:String) {
		testData.addTestResult(result.className, result.name, result.location, result.executionTime, state, errorText, pos);
	}

	public function addPass(result:TestResult) {
		addTestResult(result, Success, TestPosCache.getPos(result.location), null);
	}

	public function addFail(result:TestResult) {
		var errorText:String = "unknown";

		if (result.failure != null) {
			errorText = result.failure.message;
		}
		addTestResult(result, Failure, TestPosCache.getPos(result.location), errorText);
	}

	public function addError(result:TestResult) {
		addTestResult(result, Error, TestPosCache.getPos(result.location), '${result.error}');
	}

	public function addIgnore(result:TestResult) {
		addTestResult(result, Ignore, TestPosCache.getPos(result.location), null);
	}

	@SuppressWarnings("checkstyle:Dynamic")
	public function reportFinalStatistics(testCount:Int, passCount:Int, failCount:Int, errorCount:Int, ignoreCount:Int, time:Float):Dynamic {
		if (completionHandler != null) {
			completionHandler(this);
		}
		return null;
	}

	public function setCurrentTestClass(className:String) {}

	public function setCurrentTestClassCoverage(result:CoverageResult) {}

	public function reportFinalCoverage(?percent:Float = 0, missingCoverageResults:Array<CoverageResult>, summary:String, ?classBreakdown:String = null,
		?packageBreakdown:String = null, ?executionFrequency:String = null) {}
}
