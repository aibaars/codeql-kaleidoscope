@echo off

type NUL && "%CODEQL_DIST%\codeql.exe" database index-files ^
    --prune=**/*.testproj ^
    --include-extension=.kd ^
    --size-limit=5m ^
    --language=kaleidoscope ^
    --working-dir=. ^
    "%CODEQL_EXTRACTOR_QL_WIP_DATABASE%"

exit /b %ERRORLEVEL%
