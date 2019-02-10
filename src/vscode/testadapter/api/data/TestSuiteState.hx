package vscode.testadapter.api.data;

enum abstract TestSuiteState(String) {
	var Running = "running";
	var Completed = "completed";
}
