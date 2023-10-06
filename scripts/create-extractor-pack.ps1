cd extractor
cargo build --release
cd ..

extractor\target\release\kaleidoscope-extractor generate --dbscheme ql/lib/kaleidoscope.dbscheme --library ql/lib/codeql/kaleidoscope/ast/internal/TreeSitter.qll

codeql query format -i ql\lib\codeql\kaleidoscope\ast\internal\TreeSitter.qll

rm -Recurse -Force extractor-pack
mkdir extractor-pack | Out-Null
cp codeql-extractor.yml, ql\lib\kaleidoscope.dbscheme, ql\lib\kaleidoscope.dbscheme.stats extractor-pack
cp -Recurse tools extractor-pack
cp -Recurse downgrades extractor-pack
mkdir extractor-pack\tools\win64 | Out-Null
cp extractor\target\release\kaleidoscope-extractor.exe extractor-pack\tools\win64\kaleidoscope-extractor.exe
