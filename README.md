# Haxe Test Adapter for VSCode

A test adapter for VSCode using `hbenl.vscode-test-explorer`
![VSCode Test Adapter for Haxe](resources/haxe-test-adapter.gif)

## Features

* Shows munit test results in test explorer

## Installation

Install `haxelib install haxe-test-adapter`
Install `haxelib git munit https://github.com/AlexHaxe/MassiveUnit.git add_test_filter src` 
Install `hbenl.vscode-test-explorer` VSCode extension
Install `haxe-test-adapter` VSCode extension


## Build from sources

(Linux)

```bash
cd /home/github
git clone https://github.com/AlexHaxe/haxe-test-adapter
haxelib git munit https://github.com/AlexHaxe/MassiveUnit.git add_test_filter src
cd haxe-test-adapter
haxe build.hxml
ln -s `pwd` ~/.vscode/extensions
haxelib dev haxe-test-adapter `pwd`
```

## Usage

### Munit

* Add `-lib haxe-test-adapter` to your `buildTest.hxml` / build configuration
* Add `implements unittesthelper.ITestClass` to your test classes - helps record test positions (file name and line numbers)
* Replace `TestRunner` with `TestAdapterRunner`
* Run your unittests

You should see a folder named `.unittest` in your project root. 

## TODO

* ~~add file name and line numbers for all test functions~~
* add ~~file name and~~ line numbers for all test functions for Haxe 3 builds
* ~~running of tests~~
* ~~filter tests when running~~
* support other unittest frameworks