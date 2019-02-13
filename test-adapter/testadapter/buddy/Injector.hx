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
			switch (field.name) {
				case "new", "mapTestSpec":
					field.name = "__" + field.name;
				case _:
			}
		}
		var extraFields = (macro class {
			var adapterReporter:testadapter.buddy.Reporter;
			public function new(buddySuites:Iterable<BuddySuite>, ?reporter:Reporter) {
				adapterReporter = new testadapter.buddy.Reporter($v{Sys.getCwd()}, reporter);
				__new(buddySuites, adapterReporter);
			}

			private function mapTestSpec(buddySuite:BuddySuite, testSuite:TestSuite, beforeEachStack:Array<Array<TestFunc>>,
					afterEachStack:Array<Array<TestFunc>>, testSpec:TestSpec, done:Dynamic->Step->Void):Null<SyncTestResult> {
				switch (testSpec) {
					case Describe(_):
					case It(description, _, _, pos, _):
						adapterReporter.addPosition(pos.fileName, description, pos.lineNumber - 1);
						if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, pos.fileName, description)) {
							return null;
						}
				}
				return __mapTestSpec(buddySuite, testSuite, beforeEachStack, afterEachStack, testSpec, done);
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
