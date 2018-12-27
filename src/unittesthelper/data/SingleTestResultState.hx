package unittesthelper.data;

@:enum abstract SingleTestResultState(String) {
	var Success = "OK";
	var Failure = "FAIL";
	var Error = "ERROR";
	var Ignore = "IGNORE";
}
