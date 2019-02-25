package _testadapter.hexunit;

import _testadapter.data.TestResults;
import hex.unittest.description.ClassDescriptor;
import hex.unittest.error.AssertException;
import hex.unittest.event.ITestClassResultListener;

using hex.unittest.description.ClassDescriptorUtil;

class Notifier implements ITestClassResultListener {
	var testResults:TestResults;

	public function new(baseFolder:String) {
		testResults = new TestResults(baseFolder);
	}

	public function onStartRun(descriptor:ClassDescriptor):Void {}

	public function onEndRun(descriptor:ClassDescriptor):Void {
		testResults.save();
	}

	public function onSuiteClassStartRun(descriptor:ClassDescriptor):Void {}

	public function onSuiteClassEndRun(descriptor:ClassDescriptor):Void {}

	public function onTestClassStartRun(descriptor:ClassDescriptor):Void {}

	public function onTestClassEndRun(descriptor:ClassDescriptor):Void {}

	public function onSuccess(descriptor:ClassDescriptor, timeElapsed:Float):Void {
		var methodDescriptor = descriptor.currentMethodDescriptor();
		testResults.add(ClassName(descriptor.className), TestName(methodDescriptor.methodName), timeElapsed, Success);
	}

	public function onFail(descriptor:ClassDescriptor, timeElapsed:Float, error:hex.error.Exception):Void {
		var methodDescriptor = descriptor.currentMethodDescriptor();
		var message = error.toString();
		testResults.add(ClassName(descriptor.className), TestName(methodDescriptor.methodName), timeElapsed, Failure, message, getLineNumber(error));
	}

	public function onTimeout(descriptor:ClassDescriptor, timeElapsed:Float, error:hex.error.Exception):Void {
		var methodDescriptor = descriptor.currentMethodDescriptor();
		var message = error.toString();
		testResults.add(ClassName(descriptor.className), TestName(methodDescriptor.methodName), timeElapsed, Error, message, getLineNumber(error));
	}

	public function onIgnore(descriptor:ClassDescriptor):Void {
		var methodDescriptor = descriptor.currentMethodDescriptor();
		testResults.add(ClassName(descriptor.className), TestName(methodDescriptor.methodName), 0, Ignore);
	}

	function getLineNumber(error:hex.error.Exception):Null<Int> {
		if (Std.is(error, AssertException)) {
			return (cast error : AssertException).posInfos.lineNumber - 1;
		}
		return null;
	}
}
