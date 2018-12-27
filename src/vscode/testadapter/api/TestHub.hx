package vscode.testadapter.api;

@:jsRequire("vscode-test-adapter-api", "TestHub")
interface TestHub {
	function registerTestAdapter(adapter:TestAdapter):Void;
	function unregisterTestAdapter(adapter:TestAdapter):Void;
	function registerTestController(controller:TestController):Void;
	function unregisterTestController(controller:TestController):Void;
}
