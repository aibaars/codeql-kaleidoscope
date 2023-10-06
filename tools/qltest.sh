#!/bin/sh

set -eu

exec "${CODEQL_DIST}/codeql" database index-files \
    --prune="**/*.testproj" \
    --include-extension=.kd \
    --size-limit=5m \
    --language=kaleidoscope \
    --working-dir=.\
    "$CODEQL_EXTRACTOR_KALEIDOSCOPE_WIP_DATABASE"
