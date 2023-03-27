@echo off

type NUL && "%CODEQL_EXTRACTOR_LANGUAGE_ROOT%\tools\win64\extractor.exe" autobuild

exit /b %ERRORLEVEL%
