package _testadapter.hexunit;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using _testadapter.PatchTools;

class Injector {
	public static function buildCore():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) {
			switch (field.name) {
				case "new":
					field.addInit(macro addListener(new _testadapter.hexunit.Notifier($v{Sys.getCwd()})));
				case "run":
					field.patch(Start, macro {
						var filterInclude = $v{Macro.filters.include};
						var filterExclude = $v{Macro.filters.exclude};
						if (filterInclude.length + filterExclude.length > 0) {
							var filteredClassDescriptors:Array<hex.unittest.description.ClassDescriptor> = [];

							for (desc in _classDescriptors) {
								if (filterExclude.indexOf(desc.className) >= 0) {
									continue;
								}
								if (filterInclude.indexOf(desc.className) >= 0) {
									filteredClassDescriptors.push(desc);
									continue;
								}
								var filteredMethodDescriptors:Array<hex.unittest.description.MethodDescriptor> = [];
								for (method in desc.methodDescriptors) {
									var name = desc.className + "." + method.methodName;
									if (filterExclude.indexOf(name) >= 0) {
										continue;
									}
									if (filterInclude.indexOf(name) >= 0) {
										filteredMethodDescriptors.push(method);
									}
								}
								if (filteredMethodDescriptors.length > 0) {
									desc.methodDescriptors = filteredMethodDescriptors;
									filteredClassDescriptors.push(desc);
								}
							}
							_classDescriptors = filteredClassDescriptors;
						}
					});
				case _:
			}
		}
		return fields;
	}
}
#end
