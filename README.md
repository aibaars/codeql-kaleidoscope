# codeql-kaleidoscope
CodeQL for LLVM Kaleidoscope.

## Setup 

- Install Rust (rustup.rs)
- Install CodeQL CLI (codeql.github.com/docs/codeql-cli/installing-codeql-cli/)
- Run `scripts/create-extractor-pack.sh`
  - [optional] Update `codeql` to `gh codeql`
- Install lib packs
  - `cd ql/lib && gh codeql pack install`

**Create Database:**

```bash
gh codeql database create \
    --language=kaleidoscope --overwrite \
    --search-path $PWD/extractor-pack \
    --source-root ./testing/source \
    ./testing/database
```

**Run Query:**

```
gh codeql query run \
    -d ./testing/database/ \
    query.ql
```