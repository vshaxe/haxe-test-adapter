#!/bin/bash -e

npm install
npx lix download
npx lix use haxe 4.2.5

npx haxe build.hxml

rm -f test-adapter.zip
(cd test-adapter; zip -9 -r -q ../test-adapter.zip .)
zip -9 -r -q test-adapter.zip images README.md LICENSE.md CHANGELOG.md