cargo build --release

cargo run --release -p kaleidoscope-generator -- --dbscheme ql/src/kaleidoscope.dbscheme --library ql/src/kaleidoscope/ast/internal/TreeSitter.qll
codeql query format -i ql\src\kaleidoscope\ast\internal\TreeSitter.qll

if (Test-Path -Path extractor-pack) {
	rm -Recurse -Force extractor-pack
}
mkdir extractor-pack | Out-Null
cp codeql-extractor.yml, ql\src\kaleidoscope.dbscheme, ql\src\kaleidoscope.dbscheme.stats extractor-pack
cp -Recurse tools extractor-pack
mkdir extractor-pack\tools\win64 | Out-Null
cp target\release\kaleidoscope-extractor.exe extractor-pack\tools\win64\extractor.exe
cp target\release\kaleidoscope-autobuilder.exe extractor-pack\tools\win64\autobuilder.exe
