@echo off

type NUL && "%CODEQL_EXTRACTOR_KALEIDOSCOPE_ROOT%\tools\win64\extractor.exe" ^
        --file-list "%1" ^
        --source-archive-dir "%CODEQL_EXTRACTOR_KALEIDOSCOPE_SOURCE_ARCHIVE_DIR%" ^
        --output-dir "%CODEQL_EXTRACTOR_KALEIDOSCOPE_TRAP_DIR%"

exit /b %ERRORLEVEL%
