# Haxe Test Explorer for Visual Studio Code

[![CI](https://img.shields.io/github/workflow/status/vshaxe/haxe-test-adapter/CI.svg?logo=github)](https://github.com/vshaxe/haxe-test-adapter/actions?query=workflow%3ACI) [![Version](https://vsmarketplacebadge.apphb.com/version-short/vshaxe.haxe-test-adapter.svg)](https://marketplace.visualstudio.com/items?itemName=vshaxe.haxe-test-adapter) [![Installs](https://vsmarketplacebadge.apphb.com/installs-short/vshaxe.haxe-test-adapter.svg)](https://marketplace.visualstudio.com/items?itemName=vshaxe.haxe-test-adapter)

A VSCode test controller for Haxe.

![VSCode test controller for Haxe](images/demo.gif)

## Features

* Records [munit](https://github.com/massiveinteractive/MassiveUnit), [utest](https://github.com/haxe-utest/utest), [buddy](https://github.com/ciscoheat/buddy), [hexUnit](https://github.com/DoclerLabs/hexUnit), [tink_unittest](https://github.com/haxetink/tink_unittest) and [haxe.unit](https://api.haxe.org/haxe/unit/TestRunner.html) test results as JSON files
* Shows latest test results in VSCode
* Supports filtering / running individual tests directly from VSCode
* Supports Haxe 3.4.7 and 4+ (detection of test function line numbers only works with Haxe 4)
* Supports multi-root workspaces
* Currently only works for Node.js and sys targets

## Usage

A small sample project for each supported framework can be found in the [samples](https://github.com/vshaxe/haxe-test-adapter/tree/master/samples) directory.

You can run your tests by clicking the button in the "Test" tab of the activity bar. The command that it runs can be configured via `settings.json`:

```json
"haxeTestExplorer.testCommand": [
 "${haxe}",
 "test.hxml",
 "-lib",
 "test-adapter"
]
```

As you can see, by default it assumes the presence of a `test.hxml` that compiles and runs the tests. Additionally, the `test-adapter` library is injected. It adds hooks to the different testing frameworks to record the test results in a `.unittest` folder in your workspace.

While the `test-adapter` library itself ships with the extension and is set up automatically, you still need to install a dependency:

```hxml
haxelib install json2object
```

`.unittest` should be added to your `.gitignore`. You might also want to hide it from VSCode's file explorer by adding this to your global settings:

```json
"files.exclude": {
 "**/.unittest": true
}
```

### Debugging

It's also possible to debug tests using a launch configuration from `launch.json`. Which one should be used can be configured with this setting:

```json
"haxeTestExplorer.launchConfiguration": "Debug"
```

Unlike with `testCommand` for _running_ tests, `-lib test-adapter` can't be injected automatically for _debugging_. Add `-lib test-adapter` directly to your HXML file if you want results to be recorded / filtering to work while debugging.

### Detection of test positions

Note that for `munit`, `hexUnit` and `tink_unittest`, the test-adapter library relies on a class name filter to detect the positions of tests. This simply defaults to `~/Test/` and is checked against the names of classes and implemented interfaces anywhere in the hierarchy of a class.

You can customize the filter with `-D test-adapter-filter=<filter>`. Check `.unittest/positions.json` to see what positions were recorded.

For `utest`, test detection only works when `utest.ITest` is implemented / `utest.TestCase` is extended. If this is not the case, utest will print a warning.

### Coverage

to enable coverage runs `haxeTestExplorer.enableCoverageUI` needs to be set to `true` (default). Haxe test explorer will show a "Run Tests with Coverage" button, which will then try to run the command configured through `"haxeTestExplorer.coverageCommand"`. it defaults to:

```json
"haxeTestExplorer.coverageCommand": [
 "${haxe}",
 "testCoverage.hxml",
 "-lib",
 "test-adapter"
]
```

make sure your coverage run produces an LCOV file, you can configure the file name through `haxeTestExplorer.lcovPath` setting. it defaults to `lcov.info` in your project root.

if you are using instrument library for coverage you don't need to set `haxeTestExplorer.lcovPath`, because it auto-configures (requires at least instrument 1.3.0).

once your coverage run completes, VSCode should enable and show "TEST COVERAGE" view and also show file coverage in your "EXPLORER" view, as well as coloured line numbers in covered files.

in case there is a delay between generating test results and writing your LCOV file you can set a wait time in milliseconds via `haxeTestExplorer.waitForCoverage` setting (default: `2000` ms). test explorer will delay showing test and coverage results to ensure both of them are ready when updating UI.

### Attributable Coverage

when running Coverage with instrument library (1.3.0 and higher) test-adapter will automatically collect and generate coverage results per testcase. which means you can filter and view indiviual coverage results and see which testcase generated what coverage for your source files. you can also view unfiltered coverage results produced by all tests included in your most recent coverage run.

you can disable attributable coverage filters by setting `haxeTestExplorer.enableAttributableCoverage` to `false` (default: `true`). instrument and test-adapter will still generate attributable coverage results, but it won't show filtering UI and you won't be able to dive into individual coverage generated by each testcase.

use `-D disable-attributable-coverage` to disable attributable coverage data collection when using test-adapter library in combination with instrument library.

## Build from sources

```bash
cd ~/.vscode/extensions
git clone https://github.com/vshaxe/haxe-test-adapter
cd haxe-test-adapter
npm install
npx haxe build.hxml

haxelib dev test-adapter test-adapter
```

If you open the project in VSCode, the default `display.hxml` assumes you have all supported test frameworks installed. If you just want code completion for the sources of the extension itself, or the non-framework-specific parts of `test-adapter`, you can select `build.hxml` as your active Haxe configuration instead.
