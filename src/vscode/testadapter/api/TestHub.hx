package vscode.testadapter.api;

typedef TestHub = {
	function registerTestAdapter(adapter:TestAdapter):Void;
	function unregisterTestAdapter(adapter:TestAdapter):Void;
	function registerTestController(controller:TestController):Void;
	function unregisterTestController(controller:TestController):Void;
}
