package _testadapter.buddy;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro {
						adapterReporter = new _testadapter.buddy.Reporter($v{Sys.getCwd()}, reporter);
						this.reporter = adapterReporter;
					});
				case "mapTestSpec":
					field.patch(Start, macro switch (testSpec) {
						case It(description, _, _, pos, _):
							adapterReporter.addPosition(testSuite.description, description, pos.fileName, pos.lineNumber - 1);
						case _:
					});
				case _:
			}
		}

		var extraFields = (macro class {
			var adapterReporter:_testadapter.buddy.Reporter;
		}).fields;
		return fields.concat(extraFields);
	}

	public static function buildSuite():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			if (field.name == "it" || field.name == "xit") {
				field.patch(Start, macro if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, currentSuite.description, desc)) {
					return;
				});
			}
		}
		return fields;
	}
}
#end
