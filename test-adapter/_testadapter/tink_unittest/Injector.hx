package _testadapter.tink_unittest;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "run":
					field.addInit(Start, macro reporter = new _testadapter.tink_unittest.Reporter($v{Sys.getCwd()}, reporter));
				case "runCase":
					field.patch(Start, macro {
						var adapterReporter:_testadapter.tink_unittest.Reporter = cast reporter;
						var clazz:Null<String> = adapterReporter.testResults.positions.resolveClassName(caze.pos.fileName, caze.pos.lineNumber - 1);
						if (clazz == null) {
							clazz = suite.info.name;
						}
						if (!_testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, clazz, caze.info.name)) {
							return Future.async(function(cb) {
								cb({
									info: caze.info,
									result: Succeeded([])
								});
							});
						}
					});
				case _:
			}
		}
		return fields;
	}
}
#end
