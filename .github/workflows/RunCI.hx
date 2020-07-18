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
		runCommand("npx", ["haxe", "build.hxml"]);
		#end

		function buildSample(directory:String) {
			Sys.println("Building " + directory);
			var oldCwd = Sys.getCwd();
			Sys.setCwd(directory);
			File.saveContent("test.hxml", File.getContent("test.hxml").replace("-x Main", "-lib test-adapter"));
			runCommand("npx", ["haxe", "test.hxml"]);
			Sys.setCwd(oldCwd);
		}

		buildSample("samples/munit");
		#if (haxe_ver >= 4.1)
		buildSample("samples/utest");
		#end
		buildSample("samples/buddy");
		buildSample("samples/hexunit");
		buildSample("samples/tink_unittest");
		buildSample("samples/haxeunit");

		Sys.exit(success ? 0 : 1);
	}
}
