package testadapterhook;

#if test_adapter
import testadapter.Macro;
import testadapter.data.Data.TestState;
import testadapter.data.TestFilter;
import testadapter.data.TestResults;
#end

class AdapterHook {
	#if test_adapter
	var testResults:TestResults;

	public function new() {
		testResults = new TestResults($v{Sys.getCwd()});
	}

	public function reportPass(className:String, name:String, executionTime:Float = 0, ?message:String, ?errorLine:Int) {
		testResults.add(className, name, executionTime, Success);
	}

	public function reportFail(className:String, name:String, executionTime:Float = 0, message:String, errorLine:Int) {
		testResults.add(className, name, executionTime, Failure, message, errorLine);
	}

	public function reportError(className:String, name:String, executionTime:Float = 0, message:String) {
		testResults.add(className, name, executionTime, Error, message);
	}

	public function reportIgnore(className:String, name:String, executionTime:Float = 0, ?message:String) {
		testResults.add(className, name, executionTime, Ignore, message);
	}

	public function finishReport() {
		testResults.save();
	}

	public function shouldRunTest(className:String, testName:String):Bool {
		return TestFilter.shouldRunTest(Macro.filters, className, testName);
	}
	#else
	public function new() {}

	public function reportPass(className:String, name:String, executionTime:Float = 0, ?message:String, ?errorLine:Int) {}

	public function reportFail(className:String, name:String, executionTime:Float = 0, message:String, errorLine:Int) {}

	public function reportError(className:String, name:String, executionTime:Float = 0, message:String) {}

	public function reportIgnore(className:String, name:String, executionTime:Float = 0, ?message:String) {}

	public function finishReport() {}

	public function shouldRunTest(className:String, testName:String):Bool {
		return true;
	}
	#end
}
