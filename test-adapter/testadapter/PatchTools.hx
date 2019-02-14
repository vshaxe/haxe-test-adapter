package testadapter;

#if macro
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import testadapter.Macro;

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

	public static function addInit(field:Field, init:Expr) {
		patch(field, End, macro {
			if (!testadapter.data.TestFilter.hasFilters($v{Macro.filters})) {
				testadapter.data.TestResults.clear($v{Sys.getCwd()});
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
