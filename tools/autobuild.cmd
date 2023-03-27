@echo off

type NUL && "%CODEQL_EXTRACTOR_LANGUAGE_ROOT%\tools\%CODEQL_PLATFORM%\autobuilder"

exit /b %ERRORLEVEL%
