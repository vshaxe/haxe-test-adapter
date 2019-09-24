## 1.2.5 (September 24, 2019)

- fixed version check and compatibility with utest 1.10.0

## 1.2.4 (September 4, 2019)

- fixed compatibility with Haxe 4.0.0-rc.4

## 1.2.3 (April 5, 2019)

- fixed tests being grayed out with Test Explorer UI 2.9.0+

## 1.2.2 (March 4, 2019)

- fixed all tests being executed when debugging individual tests ([#13](https://github.com/vshaxe/haxe-test-adapter/pull/13))

## 1.2.1 (February 28, 2019)

- added `-D test-adapter-filter` for custom name matching
- extended name matching for position recording to parent types ([#12](https://github.com/vshaxe/haxe-test-adapter/pull/12))
- improved position recording to no longer rely on name matching for utest, buddy and haxe.unit
- improved handling of test suites with identical names where possible ([#9](https://github.com/vshaxe/haxe-test-adapter/pull/9))

## 1.2.0 (February 23, 2019)

- added support for the [hexUnit](https://github.com/DoclerLabs/hexUnit) test framework
- added support for the [tink_unittest](https://github.com/haxetink/tink_unittest) test framework
- fixed test-adapter setup with spaces in username
- improved behavior during code completion

## 1.1.0 (February 14, 2019)

- added support for the [buddy](https://github.com/ciscoheat/buddy) test framework
- fixed results + decorations of removed tests sticking around

## 1.0.1 (February 13, 2019)

- fixed compatibility with utest 1.9.2

## 1.0.0 (February 12, 2019)

- initial release
