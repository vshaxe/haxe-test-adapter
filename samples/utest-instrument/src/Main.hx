class Main {
	public function new() {
		doNothing();
	}

	public function doSomething(condition:Bool) {
		switch (condition) {
			case true:
				doNothing();
			case false:
				doNothing();
			default:
				doNothing();
		}

		switch (condition) {
			case true:
			case false:
				doNothing();
			default:
		}

		if (condition) {
			doNothing();
		}
		// test

		doNothing();

		if (!condition) {
			doNothing();
		}
		doNothing();

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
		// test
		return true;
	}

	static function main() {
		new Main();
	}
}
