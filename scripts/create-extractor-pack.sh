#!/bin/bash
set -eux

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  platform="linux64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  platform="osx64"
else
  echo "Unknown OS"
  exit 1
fi

(cd extractor && cargo build --release)

BIN_DIR=extractor/target/release

"$BIN_DIR/kaleidoscope-extractor" generate --dbscheme ql/lib/kaleidoscope.dbscheme --library ql/lib/codeql/kaleidoscope/ast/internal/TreeSitter.qll

codeql query format -i ql/lib/codeql/kaleidoscope/ast/internal/TreeSitter.qll

rm -rf extractor-pack
mkdir -p extractor-pack
cp -r codeql-extractor.yml downgrades tools ql/lib/kaleidoscope.dbscheme ql/lib/kaleidoscope.dbscheme.stats extractor-pack/
mkdir -p extractor-pack/tools/${platform}
cp "$BIN_DIR/kaleidoscope-extractor" extractor-pack/tools/${platform}/kaleidoscope-extractor
