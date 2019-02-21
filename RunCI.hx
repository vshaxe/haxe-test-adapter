import sys.io.File;

using StringTools;

class RunCI {
	static function main() {
		var success = true;
		function runCommand(command:String, args:Array<String>) {
			Sys.println(command + " " + args.join(" "));
			if (Sys.command(command, args) != 0) {
				success = false;
			}
		}

		#if haxe4
		runCommand("haxe", ["build.hxml"]);
		#end

		function buildSample(directory:String) {
			Sys.println("Building " + directory);
			var oldCwd = Sys.getCwd();
			Sys.setCwd(directory);
			File.saveContent("test.hxml", File.getContent("test.hxml").replace("-x Main", "-lib test-adapter"));
			runCommand("haxe", ["test.hxml"]);
			Sys.setCwd(oldCwd);
		}

		buildSample("samples/munit");
		buildSample("samples/utest");
		buildSample("samples/haxeunit");
		buildSample("samples/buddy");
		buildSample("samples/hexunit");

		Sys.exit(success ? 0 : 1);
	}
}
