import sys.io.File;

using StringTools;

class RunCI {
	static function main() {
		#if haxe4
		Sys.command("haxe", ["build.hxml"]);
		#end

		function buildSample(directory:String) {
			Sys.println("Building " + directory);
			var oldCwd = Sys.getCwd();
			Sys.setCwd(directory);
			File.saveContent("test.hxml", File.getContent("test.hxml").replace("-x Main", ""));
			Sys.command("haxe", ["test.hxml"]);
			Sys.setCwd(oldCwd);
		}

		buildSample("samples/munit");
		buildSample("samples/utest");
		buildSample("samples/haxeunit");
	}
}
