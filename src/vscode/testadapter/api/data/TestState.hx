package vscode.testadapter.api.data;

@:enum abstract TestState(String) {
	var Running = "running";
	var Passed = "passed";
	var Failed = "failed";
	var Skipped = "skipped";
}
