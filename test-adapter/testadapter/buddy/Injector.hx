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
							exprs.push(macro adapterReporter = new testadapter.buddy.Reporter($v{Sys.getCwd()}, reporter));
							exprs.push(macro this.reporter = adapterReporter);
						case _:
					}
				case _:
			}
			switch (field.name) {
				case "mapTestSpec":
					field.name = "__" + field.name;
				case _:
			}
		}
		var extraFields = (macro class {
			var adapterReporter:testadapter.buddy.Reporter;

			private function mapTestSpec(buddySuite:BuddySuite, testSuite:TestSuite, beforeEachStack:Array<Array<TestFunc>>,
					afterEachStack:Array<Array<TestFunc>>, testSpec:TestSpec, done:Dynamic->Step->Void):Null<SyncTestResult> {
				switch (testSpec) {
					case Describe(_):
					case It(description, _, _, pos, _):
						adapterReporter.addPosition(testSuite.description, description, pos.fileName, pos.lineNumber - 1);
				}
				return __mapTestSpec(buddySuite, testSuite, beforeEachStack, afterEachStack, testSpec, done);
			}
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
			if (f == null) {
				continue;
			}
			switch (field.name) {
				case "it":
					field.name = "__" + field.name;
				case _:
			}
		}
		var extraFields = (macro class {
			private function it(desc:String, ?spec:TestFunc, _hasInclude = false, ?pos:PosInfos, time:Float = 0):Void {
				if (!testadapter.data.TestFilter.shouldRunTest($v{Macro.filters}, currentSuite.description, desc)) {
					return;
				}
				__it(desc, spec, _hasInclude, pos, time);
			}
		}).fields;
		return fields.concat(extraFields);
	}
}
#end
