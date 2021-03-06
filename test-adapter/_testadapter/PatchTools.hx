package _testadapter;

#if macro
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import _testadapter.Macro;

class PatchTools {
	public static function patch(field:Field, kind:PatchKind, expr:Expr) {
		switch (field.kind) {
			case FFun(f):
				switch (f.expr.expr) {
					case EBlock(exprs):
						switch (kind) {
							case Start:
								exprs.unshift(expr);
							case End:
								exprs.push(expr);
							case Replace:
								f.expr = expr;
						}
					case _:
				}
			case _:
		}
	}

	public static function addInit(field:Field, ?kind:PatchKind, init:Expr) {
		if (kind == null) {
			kind = End;
		}
		patch(field, kind, macro {
			if (!_testadapter.data.TestFilter.hasFilters($v{Macro.filters})) {
				_testadapter.data.TestResults.clear($v{Sys.getCwd()});
			}
			$init;
		});
	}
}

enum PatchKind {
	Start;
	End;
	Replace;
}
#end
