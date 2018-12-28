package unittesthelper.munit;

import haxe.Constraints.Function;
import massive.munit.TestClassHelper;
import unittesthelper.data.TestFilter;

@SuppressWarnings("checkstyle:Dynamic")
class TestAdapterClassHelper extends TestClassHelper {
	override function scanForTests(fieldMeta:Dynamic) {
		super.scanForTests(fieldMeta);
		if (tests.length <= 0) {
			beforeClass = TestClassHelper.nullFunc;
			afterClass = TestClassHelper.nullFunc;
			before = TestClassHelper.nullFunc;
			after = TestClassHelper.nullFunc;
			return;
		}
	}

	override function addTest(field:String, testFunction:Function, testInstance:Dynamic, isAsync:Bool, isIgnored:Bool, description:String) {
		if (!TestFilter.shouldRunTest(className, field)) {
			return;
		}
		super.addTest(field, testFunction, testInstance, isAsync, isIgnored, description);
	}
}
