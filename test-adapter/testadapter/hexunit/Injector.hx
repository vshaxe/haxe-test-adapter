package testadapter.hexunit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using testadapter.PatchTools;

class Injector {
	public static function buildCore():Array<Field> {
		var fields = Context.getBuildFields();
		var isFiltered = (Macro.filters.length != 0);
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro {
						addListener(new testadapter.hexunit.Notifier($v{Sys.getCwd()}));
					});
					if (isFiltered) {
						for (filter in Macro.filters) {
							var parts = filter.split(".");
							var lastPart = parts.pop();
							var className = "";
							if (~/^[A-Z]/.match(lastPart)) {
								className = filter;
								trace(className);
								field.patch(End, macro {
									var c = Type.resolveClass($v{className});
									// __addTest(c);
								});
							} else {
								className = parts.join(".");
								field.patch(End, macro {
									__addTestMethod(Type.resolveClass($v{className}), $v{lastPart});
								});
							}
						}
					}
				case "addTestMethod", "addDescriptor":
					if (isFiltered) {
						field.name = "__" + field.name;
					}
				case _:
			}
		}
		if (isFiltered) {
			var extraFields = (macro class {
				public function addTestMethod(testableClass:Class<Dynamic>, methodName:String):Void {}
				public function addDescriptor(classDescriptor:ClassDescriptor):Void {}
				// public function __addTest(testableClass:Class<Dynamic>) {
				// 	var descriptor = ClassDescriptorGenerator.doGeneration(testableClass);
				// 	return __addDescriptor(descriptor);
				// }
			}).fields;
			return fields.concat(extraFields);
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
