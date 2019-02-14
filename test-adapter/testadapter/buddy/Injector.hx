package testadapter.buddy;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			var f = switch (field.kind) {
				case FFun(f): f;
				case _: null;
			}
			if (f == null) {
				continue;
			}
			switch (f.expr.expr) {
				case EBlock(exprs):
					switch (field.name) {
						case "new":
							exprs.push(macro {
								if (!testadapter.data.TestFilter.hasFilters($v{Macro.filters})) {
									testadapter.data.TestResults.clear($v{Sys.getCwd()});
								}
								adapterReporter = new testadapter.buddy.Reporter($v{Sys.getCwd()}, reporter);
								this.reporter = adapterReporter;
							});
						case "mapTestSpec":
							exprs.unshift(macro switch (testSpec) {
								case It(description, _, _, pos, _):
									adapterReporter.addPosition(testSuite.description, description, pos.fileName, pos.lineNumber - 1);
								case _:
							});
					}
				case _:
			}
		}
		var extraFields = (macro class {
			var adapterReporter:testadapter.buddy.Reporter;
		}).fields;
		return fields.concat(extraFields);
	}

	public static function buildSuite():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			var f = switch (field.kind) {
				case FFun(f): f;
				case _: null;
			}
			if (f != null && (field.name == "it" || field.name == "xit")) {
				switch (f.expr.expr) {
					case EBlock(exprs):
						exprs.unshift(macro if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, currentSuite.description, desc)) {
							return;
						});
					case _:
				}
			}
		}
		return fields;
	}
}
#end
