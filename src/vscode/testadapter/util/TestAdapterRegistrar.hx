package vscode.testadapter.util;

import vscode.WorkspaceFolder;
import vscode.testadapter.api.TestHub;

@:jsRequire("vscode-test-adapter-util", "TestAdapterRegistrar")
extern class TestAdapterRegistrar<T> {
	function new(testHub:TestHub, adapterFactory:(workspaceFolder:WorkspaceFolder) -> T, ?log:Log);
	function dispose():Void;
}
