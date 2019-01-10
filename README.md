# Haxe Test Adapter for VSCode

A test adapter for VSCode using `hbenl.vscode-test-explorer`
![VSCode Test Adapter for Haxe](resources/haxe-test-adapter.gif)

## Features

* Records munit, utest and haxe.unit test results as json files
* Shows latest test results in VSCode using Test Explorer UI extension
* Supports filtering / running individual tests directly from VSCode
* currently only works for nodejs and sys targets

## Installation

* Install `haxelib git munit https://github.com/AlexHaxe/MassiveUnit.git add_test_filter src` 
* Install `hbenl.vscode-test-explorer` VSCode extension
* Install `haxe-test-adapter` VSCode extension (should auto-install `haxe-test-adapter` haxelib)

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

## Usage

After running your tests you should see a folder named `.unittest` in your project root, containing test results, test positions and filters.

### munit

* Add `-lib haxe-test-adapter` to your `buildTest.hxml` / build configuration
* Replace `TestRunner` with `unittesthelper.munit.TestAdapterRunner`
* Run your unittests

### utest

* Add `-lib haxe-test-adapter` to your `buildTest.hxml` / build configuration
* Replace `Runner` with `unittesthelper.utest.TestAdapterRunner`
* Run your unittests

### haxe.unit

* Add `-lib haxe-test-adapter` to your `buildTest.hxml` / build configuration
* Replace `TestRunner` with `unittesthelper.haxeunit.TestAdapterRunner`
* Run your unittests

**Note:** Filtering tests does not work for haxe.unit.

## TODO

* ~~add file name and line numbers for all test functions~~
* add ~~file name and~~ line numbers for all test functions for Haxe 3 builds
* ~~running of tests~~
* ~~filter tests when running~~
* implement filtering for haxe.unit
* add support for additional unittest frameworks