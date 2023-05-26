@echo off

type NUL && "%CODEQL_EXTRACTOR_KALEIDOSCOPE_ROOT%\tools\%CODEQL_PLATFORM%\kaleidoscope-extractor" autobuild

exit /b %ERRORLEVEL%
