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

"$BIN_DIR/generator" --dbscheme ql/lib/language.dbscheme --library ql/lib/codeql/language/ast/internal/TreeSitter.qll

codeql query format -i ql/lib/codeql/language/ast/internal/TreeSitter.qll

rm -rf extractor-pack
mkdir -p extractor-pack
cp -r codeql-extractor.yml downgrades tools ql/lib/language.dbscheme ql/lib/language.dbscheme.stats extractor-pack/
mkdir -p extractor-pack/tools/${platform}
cp "$BIN_DIR/language-extractor" extractor-pack/tools/${platform}/extractor
