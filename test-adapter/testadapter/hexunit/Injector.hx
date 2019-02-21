package testadapter.hexunit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using testadapter.PatchTools;

class Injector {
	public static function buildCore():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro {
						addListener(new testadapter.hexunit.Notifier($v{Sys.getCwd()}));
					});
				case _:
			}
		}
		return fields;
	}

	public static function buildRunner():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "run":
					field.name = "__run";
				case _:
			}
		}

		var extraFields = (macro class {
			public function run():Void {
				// TODO workaround to get class name, since classDescriptor is not available
				var className = Type.getClassName(_classType);
				if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, className, _methodDescriptor.methodName)) {
					// TODO framework does not continue without a trigger
					this._trigger.onIgnore(0);
					return;
				}
				__run();
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
