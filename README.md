# Haxe Test Adapter for VSCode

A test adapter for VSCode using the [Test Explorer UI](https://marketplace.visualstudio.com/items?itemName=hbenl.vscode-test-explorer) extension.

![VSCode Test Adapter for Haxe](resources/haxe-test-adapter.gif)

## Features

* Records [munit](https://github.com/massiveinteractive/MassiveUnit), [utest](https://github.com/haxe-utest/utest) and [`haxe.unit`](https://api.haxe.org/haxe/unit/TestRunner.html) test results as JSON files
* Shows latest test results in VSCode using the Test Explorer UI extension
* Supports filtering / running individual tests directly from VSCode
* Currently only works for Node.js and sys targets

## Usage

* Add `-lib haxe-test-adapter` to your `buildTest.hxml` / build configuration

Test adapter is only active when `#if haxe_test_adapter_enabled` is defined. To enable test adapter for IDE builds you have to either

* make sure `haxe buildTest.hxml -D haxe_test_adapter_enabled` works or
* you need to use a separate `buildTestVSCode.hxml` that adds `-D haxe_test_adapter_enabled` - you will also need to add `"haxetestadapter.runTestsCmd": "haxe buildTestVSCode.hxml"` to your VSCode settings.json.

After running your tests you should see a folder named `.unittest` in your project root, containing test results, test positions and filters.

### munit

For munit, a fork is currently needed. It can be installed like this:

```
haxelib git munit https://github.com/AlexHaxe/MassiveUnit.git add_test_filter src
```

After that:

* Replace `TestRunner` with `unittesthelper.munit.TestAdapterRunner`
* Run your unittests either manually or by using `Run all tests` from Test Explorer UI

### utest

* Replace `Runner` with `unittesthelper.utest.TestAdapterRunner`
* Run your unittests either manually or by using `Run all tests` from Test Explorer UI

### haxe.unit

* Replace `TestRunner` with `unittesthelper.haxeunit.TestAdapterRunner`
* Run your unittests either manually or by using `Run all tests` from Test Explorer UI

**Note:** Filtering tests does not work for `haxe.unit`.

## Build from sources

(Linux)

```bash
cd /home/github
git clone https://github.com/vshaxe/haxe-test-adapter
haxelib git munit https://github.com/AlexHaxe/MassiveUnit.git add_test_filter src
cd haxe-test-adapter
npm install
haxe build.hxml
ln -s `pwd` ~/.vscode/extensions
haxelib dev haxe-test-adapter `pwd`
```

## TODO

* ~~add file name and line numbers for all test functions~~
* add ~~file name and~~ line numbers for all test functions for Haxe 3 builds
* ~~running of tests~~
* ~~filter tests when running~~
* implement filtering for haxe.unit
* add support for additional unittest frameworks