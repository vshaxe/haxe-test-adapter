import vscode.testadapter.util.Log;
import vscode.ExtensionContext;
import vscode.testadapter.api.TestHub;
import vscode.testadapter.util.TestAdapterRegistrar;

class Main {
	final context:ExtensionContext;
	final testHub:TestHub;

	function new(context:ExtensionContext) {
		this.context = context;

		var channel = Vscode.window.createOutputChannel('Haxe Tests');
		testHub = Vscode.extensions.getExtension("hbenl.vscode-test-explorer").exports;

		var log = new Log("haxeTestAdapter", Vscode.workspace.workspaceFolders[0], "Haxe Test Adapter");
		context.subscriptions.push(log);
		log.info("Starting Haxe Test Adapter");

		context.subscriptions.push(new TestAdapterRegistrar<HaxeTestAdapter>(testHub, (folder) -> new HaxeTestAdapter(folder, channel, log), log));

		updateHaxelib();
	}

	function updateHaxelib() {
		Vscode.commands.registerCommand("haxe-test-adapter.setup", function() {
			var terminal = Vscode.window.createTerminal();
			terminal.sendText("haxelib dev test-adapter " + context.extensionPath + " test-adapter");
			terminal.show();
			context.globalState.update("previousExtensionPath", context.extensionPath);
		});

		if (isExtensionPathChanged(context)) {
			Vscode.commands.executeCommand("haxe-test-adapter.setup");
		}
	}

	function isExtensionPathChanged(context:ExtensionContext):Bool {
		var previousPath = context.globalState.get("previousExtensionPath");
		return (context.extensionPath != previousPath);
	}

	@:expose("activate")
	static function main(context:ExtensionContext) {
		new Main(context);
	}
}
