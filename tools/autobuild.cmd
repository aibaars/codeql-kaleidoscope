@echo off

type NUL && "%CODEQL_EXTRACTOR_KALEIDOSCOPE_ROOT%\tools\%CODEQL_PLATFORM%\autobuilder"

exit /b %ERRORLEVEL%
