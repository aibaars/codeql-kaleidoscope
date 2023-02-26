#!/bin/bash
set -eux
CARGO=cargo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  platform="linux64"
  if which cross; then
    CARGO=cross
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  platform="osx64"
else
  echo "Unknown OS"
  exit 1
fi

"$CARGO" build --release

"$CARGO" run --release -p kaleidoscope-generator -- --dbscheme ql/lib/kaleidoscope.dbscheme --library ql/lib/codeql/kaleidoscope/ast/internal/TreeSitter.qll
codeql query format -i ql/lib/codeql/kaleidoscope/ast/internal/TreeSitter.qll

rm -rf extractor-pack
mkdir -p extractor-pack
cp -r codeql-extractor.yml downgrades tools ql/lib/kaleidoscope.dbscheme ql/lib/kaleidoscope.dbscheme.stats extractor-pack/
mkdir -p extractor-pack/tools/${platform}
cp target/release/kaleidoscope-extractor extractor-pack/tools/${platform}/extractor
cp target/release/kaleidoscope-autobuilder extractor-pack/tools/${platform}/autobuilder