package unittesthelper.munit;

import massive.munit.ITestResultClient;
import massive.munit.TestResult;
import unittesthelper.data.TestResultData;
import unittesthelper.data.SingleTestResultState;

class MunitTestResultClient implements IAdvancedTestResultClient implements ICoverageTestResultClient {
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

	function addTestResult(result:TestResult, state:SingleTestResultState, file:String, line:Null<Int>, errorText:String) {
		testData.addTestResult(result.className, result.name, result.location, result.executionTime, state, errorText, file, line);
	}

	public function addPass(result:TestResult) {
		// TODO get file and line number info
		addTestResult(result, Success, null, null, null);
	}

	public function addFail(result:TestResult) {
		var errorText:String = "unknown";
		Sys.println('${haxe.CallStack.callStack()}');

		var file:String = null;
		var line:Null<Int> = null;
		if (result.failure != null) {
			errorText = result.failure.message;
			file = result.failure.info.fileName;
			line = result.failure.info.lineNumber - 1;
		}
		addTestResult(result, Failure, file, line, errorText);
	}

	public function addError(result:TestResult) {
		// TODO get file and line number info
		addTestResult(result, Error, null, null, '${result.error}');
	}

	public function addIgnore(result:TestResult) {
		// TODO get file and line number info
		addTestResult(result, Ignore, null, null, null);
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
