@echo off
echo Compiling Nim files with fixes...

:: Check/install winim
nimble install -y winim

:: Compile with more verbose output for troubleshooting
echo Compiling memtest.nim...
nim c --verbosity:1 memtest.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling api_caller.nim...
nim c --verbosity:1 api_caller.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling memory_only_loader.nim...
nim c --verbosity:1 memory_only_loader.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling process_hollowing_concept.nim...
nim c --verbosity:1 process_hollowing_concept.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo.
echo Compilation completed successfully! You can now run:
echo - memtest.exe
echo - api_caller.exe
echo - memory_only_loader.exe
echo - process_hollowing_concept.exe
goto :end

:error
echo.
echo Error during compilation! Check the errors above.
exit /b 1

:end
pause 