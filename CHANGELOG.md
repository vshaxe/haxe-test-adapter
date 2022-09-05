# CHANGELOG

## 2.0.4 (September 5, 2022)

- compiled extension with Haxe nightly

## 2.0.3 (September 5, 2022)

- changed scope of configuration settings to resource level to support different settings per workspace folder in a multiroot workspace scenario

## 2.0.2 (August 24, 2022)

- fixed compatibility issue with vshaxe 2.24.x

## 2.0.1 (February 17, 2022)

- fixed auto collapse of test cases
- fixed error positions in different file
- fixed multiline diff detection

## 2.0.0 (January 27, 2022)

- added support for VSCode testing API
- added test execution time (in ms) for buddy, munit, hexunit and utest
- dropped test explorer ui extension dependency

## 1.2.10 (October 11, 2020)

- added support for nested describe calls in buddy tests

## 1.2.9 (August 15, 2020)

- fixed utest injection after implementation detail changed in version 1.13.0
- changed required version for utest to 1.13.0

## 1.2.8 (May 1, 2020)

- fixed tink_testrunner injection to restore compatibility with version 0.8.0

## 1.2.7 (April 11, 2020)

- fixed state of "Run all tests" button not being restored anymore since VSCode 1.44

## 1.2.6 (November 13, 2019)

- added support for hierarchical display of tests based on their package
- fixed utest reporting with multiple asserts ([#17](https://github.com/vshaxe/haxe-test-adapter/issues/17))

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
