import sys.io.File;
using StringTools;

class RunCICoverage {
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
			File.saveContent("test.hxml", File.getContent("test.hxml").replace("-x Test", "-x Test\n-lib test-adapter"));
			runCommand("npx", ["haxe", "test.hxml"]);
			Sys.setCwd(oldCwd);
		}

		function buildSampleWithCoverage(directory:String) {
			Sys.println("Building " + directory + " with coverage");
			var oldCwd = Sys.getCwd();
			Sys.setCwd(directory);
			File.saveContent("testCoverage.hxml", File.getContent("testCoverage.hxml").replace("-x Test", "-x Test\n-lib test-adapter"));
			runCommand("npx", ["haxe", "testCoverage.hxml"]);
			Sys.setCwd(oldCwd);
		}

		
		buildSample("samples/munit-instrument");
		buildSample("samples/munit-mcover");
		buildSample("samples/utest-instrument");
		buildSample("samples/buddy-instrument");
		buildSample("samples/tink_unittest-instrument");

		buildSampleWithCoverage("samples/munit-instrument");
		buildSampleWithCoverage("samples/munit-mcover");
		buildSampleWithCoverage("samples/utest-instrument");
		buildSampleWithCoverage("samples/buddy-instrument");
		buildSampleWithCoverage("samples/tink_unittest-instrument");

		Sys.exit(success ? 0 : 1);
	}
}
