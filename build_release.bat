@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%"

set "AU3=Idle Runner.au3"
set "VERSION=3.5.7.1"
set "RELEASE_DIR=%SCRIPT_DIR%\Release\%VERSION%"
set "ZIP_NAME=Idle.Runner_%VERSION%.zip"

:: Try to find AutoIt3Wrapper (full compile with resources). Wrapper can be .exe or .au3 (run with AutoIt3.exe).
set "WRAPPER="
set "AUTOIT3="
if exist "C:\Program Files (x86)\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.exe" set "WRAPPER=C:\Program Files (x86)\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.exe"
if exist "C:\Program Files\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.exe" set "WRAPPER=C:\Program Files\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.exe"
if "%WRAPPER%"=="" (
    if exist "C:\Program Files (x86)\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3" (
        set "WRAPPER=C:\Program Files (x86)\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3"
        set "AUTOIT3=C:\Program Files (x86)\AutoIt3\AutoIt3.exe"
    )
    if exist "C:\Program Files\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3" (
        set "WRAPPER=C:\Program Files\AutoIt3\SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3"
        set "AUTOIT3=C:\Program Files\AutoIt3\AutoIt3.exe"
    )
)
if "%WRAPPER%"=="" (
    echo AutoIt3Wrapper not found. Please compile manually:
    echo   1. Right-click "%AU3%" -^> Compile with Options
    echo   2. Click "Compile Script" to build Idle.Runner_x32.exe and Idle.Runner_x64.exe
    echo   3. Run this script again to package, or copy exes to Release\%VERSION%\
    goto :package
)

echo Building with AutoIt3Wrapper...
if defined AUTOIT3 (
    "%AUTOIT3%" "%WRAPPER%" /in "%AU3%" /prod
) else (
    "%WRAPPER%" /in "%AU3%" /prod
)
if errorlevel 1 (
    echo Compile failed.
    exit /b 1
)

:package
mkdir "%RELEASE_DIR%" 2>nul

set "EXE32=Idle.Runner_x32.exe"
set "EXE64=Idle.Runner_x64.exe"

if exist "%SCRIPT_DIR%\%EXE32%" (
    copy /y "%SCRIPT_DIR%\%EXE32%" "%RELEASE_DIR%\" >nul
    echo Added %EXE32%
)
if exist "%SCRIPT_DIR%\%EXE64%" (
    copy /y "%SCRIPT_DIR%\%EXE64%" "%RELEASE_DIR%\" >nul
    echo Added %EXE64%
)

if not exist "%RELEASE_DIR%\%EXE32%" if not exist "%RELEASE_DIR%\%EXE64%" (
    echo No exe found in Release folder. Build first via AutoIt "Compile with Options" on "%AU3%", then re-run this script.
    exit /b 1
)

copy /y "%SCRIPT_DIR%\README.md" "%RELEASE_DIR%\" >nul 2>nul
copy /y "%SCRIPT_DIR%\LICENSE.md" "%RELEASE_DIR%\" >nul 2>nul
echo.

:: Create zip (PowerShell available on Windows)
powershell -NoProfile -Command "Compress-Archive -Path '%RELEASE_DIR%\*' -DestinationPath '%SCRIPT_DIR%\Release\%ZIP_NAME%' -Force" 2>nul
if exist "%SCRIPT_DIR%\Release\%ZIP_NAME%" (
    echo Created %ZIP_NAME%
) else (
    echo Zip not created. Manually zip contents of Release\%VERSION%\
)

echo.
echo Release %VERSION% ready in Release\%VERSION%\
echo Optional: upload Release\%ZIP_NAME% to GitHub Releases.
endlocal
