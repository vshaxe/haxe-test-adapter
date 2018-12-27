package vscode.testadapter.util;

import vscode.WorkspaceFolder;

@:jsRequire("vscode-test-adapter-util", "Log")
extern class Log {
	function new(configSection:String, ?workspaceFolder:WorkspaceFolder, outputChannelName:String);
	function debug(msg:String):Void;
	function info(msg:String):Void;
	function warn(msg:String):Void;
	function error(msg:String):Void;
	function dispose():Void;
}
