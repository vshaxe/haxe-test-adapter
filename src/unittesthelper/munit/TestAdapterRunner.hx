package unittesthelper.munit;

import massive.munit.TestClassHelper;
import massive.munit.TestRunner;
import massive.munit.ITestResultClient;

class TestAdapterRunner extends TestRunner {
	public function new(resultClient:ITestResultClient) {
		super(resultClient);
		addResultClient(new TestAdapterResultClient());
	}

	@SuppressWarnings("checkstyle:Dynamic")
	override function createTestClassHelper(testClass:Class<Dynamic>):TestClassHelper
		return new TestAdapterClassHelper(testClass, isDebug);
}
