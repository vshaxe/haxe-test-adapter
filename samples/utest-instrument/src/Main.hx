class Main {
	public function new() {
		doNothing();
	}

	public function doSomething(condition:Bool) {
		if (condition) {
			doNothing();
			return false;
		} else {
			doNothing();
		}
		doNothing();
		return true;
	}

	public function doSomethingFullCoverage(condition:Bool) {
		if (condition) {
			doNothing();
			return false;
		} else {
			doNothing();
		}
		doNothing();
		return true;
	}

	public function doNothing() {
		return true;
	}

	public function doMoreNothing() {
		return true;
	}

	static function main() {
		new Main();
	}
}
