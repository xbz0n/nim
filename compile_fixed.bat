@echo off
echo Compiling Nim files with static linking...

:: Check/install winim
nimble install -y winim

:: Create a temporary config file to force static compilation
echo "cc = gcc" > temp_nim.cfg
echo "passC = \"-static\"" >> temp_nim.cfg
echo "passL = \"-static\"" >> temp_nim.cfg

:: Compile with more verbose output for troubleshooting
echo Compiling memtest.nim...
nim c --verbosity:1 --config:temp_nim.cfg --cpu:amd64 --os:windows --opt:speed memtest.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling api_caller.nim...
nim c --verbosity:1 --config:temp_nim.cfg --cpu:amd64 --os:windows --opt:speed api_caller.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling memory_only_loader.nim...
nim c --verbosity:1 --config:temp_nim.cfg --cpu:amd64 --os:windows --opt:speed memory_only_loader.nim
if %ERRORLEVEL% NEQ 0 goto :error

echo Compiling process_hollowing_concept.nim...
nim c --verbosity:1 --config:temp_nim.cfg --cpu:amd64 --os:windows --opt:speed process_hollowing_concept.nim
if %ERRORLEVEL% NEQ 0 goto :error

:: Clean up
del temp_nim.cfg

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