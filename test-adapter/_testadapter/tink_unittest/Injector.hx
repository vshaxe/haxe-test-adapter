package _testadapter.tink_unittest;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildCase():Array<Field> {
		var fields = Context.getBuildFields();

		for (field in fields) {
			switch (field.name) {
				case "shouldRun":
					field.patch(Start, macro if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, this.suite.info.name, this.info.name))
						return false);
			}
		}

		return fields;
	}

	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "run":
					field.addInit(Start, macro reporter = new _testadapter.tink_unittest.Reporter($v{Sys.getCwd()}, reporter));
			}
		}
		return fields;
	}
}
#end
