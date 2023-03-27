#!/bin/sh

set -eu

exec "${CODEQL_DIST}/codeql" database index-files \
    --prune="**/*.testproj" \
    --include-extension=.lang \
    --size-limit=5m \
    --language=language \
    --working-dir=.\
    "$CODEQL_EXTRACTOR_LANGUAGE_WIP_DATABASE"
