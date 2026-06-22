@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%"

set "AU3=Idle Runner.au3"
set "VERSION=3.5.9.0"
set "RELEASE_DIR=%SCRIPT_DIR%\Release\%VERSION%"
set "ZIP_NAME=Idle.Runner_%VERSION%.zip"
set "ASSET32=Idle.Runner_%VERSION%_x32.exe"
set "ASSET64=Idle.Runner_%VERSION%_x64.exe"
set "CHECKSUMS=SHA256SUMS.txt"

if defined SKIP_COMPILE goto :package_prebuilt

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
    copy /y "%SCRIPT_DIR%\%EXE32%" "%SCRIPT_DIR%\Release\%ASSET32%" >nul
    echo Added %EXE32%
)
if exist "%SCRIPT_DIR%\%EXE64%" (
    copy /y "%SCRIPT_DIR%\%EXE64%" "%RELEASE_DIR%\" >nul
    copy /y "%SCRIPT_DIR%\%EXE64%" "%SCRIPT_DIR%\Release\%ASSET64%" >nul
    echo Added %EXE64%
)

goto :validate_assets

:package_prebuilt
mkdir "%RELEASE_DIR%" 2>nul
set "EXE32=Idle.Runner_x32.exe"
set "EXE64=Idle.Runner_x64.exe"
if exist "%SCRIPT_DIR%\Release\%ASSET32%" copy /y "%SCRIPT_DIR%\Release\%ASSET32%" "%RELEASE_DIR%\%EXE32%" >nul
if exist "%SCRIPT_DIR%\Release\%ASSET64%" copy /y "%SCRIPT_DIR%\Release\%ASSET64%" "%RELEASE_DIR%\%EXE64%" >nul

:validate_assets

if not exist "%SCRIPT_DIR%\Release\%ASSET32%" (
    echo Missing x32 executable. Both architectures are required.
    exit /b 1
)
if not exist "%SCRIPT_DIR%\Release\%ASSET64%" (
    echo Missing x64 executable. Both architectures are required.
    exit /b 1
)

copy /y "%SCRIPT_DIR%\README.md" "%RELEASE_DIR%\" >nul 2>nul
copy /y "%SCRIPT_DIR%\LICENSE.md" "%RELEASE_DIR%\" >nul 2>nul
if exist "%SCRIPT_DIR%\RELEASE_NOTES_%VERSION%.md" copy /y "%SCRIPT_DIR%\RELEASE_NOTES_%VERSION%.md" "%RELEASE_DIR%\RELEASE_NOTES.md" >nul
echo.

:: Generate checksums for the standalone updater assets.
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; function Hash($p) { $s=[IO.File]::OpenRead($p); try { ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($s))).Replace('-','').ToLower() } finally { $s.Dispose() } }; $files=@('%SCRIPT_DIR%\Release\%ASSET32%','%SCRIPT_DIR%\Release\%ASSET64%'); $lines=$files | ForEach-Object { (Hash $_) + '  ' + [IO.Path]::GetFileName($_) }; Set-Content -LiteralPath '%SCRIPT_DIR%\Release\%CHECKSUMS%' -Value $lines -Encoding Ascii"
if errorlevel 1 (
    echo Failed to create SHA-256 manifest.
    exit /b 1
)
copy /y "%SCRIPT_DIR%\Release\%CHECKSUMS%" "%RELEASE_DIR%\%CHECKSUMS%" >nul

:: Create zip (PowerShell available on Windows)
powershell -NoProfile -Command "Compress-Archive -Path '%RELEASE_DIR%\*' -DestinationPath '%SCRIPT_DIR%\Release\%ZIP_NAME%' -Force" 2>nul
if exist "%SCRIPT_DIR%\Release\%ZIP_NAME%" (
    echo Created %ZIP_NAME%
    powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $p='%SCRIPT_DIR%\Release\%ZIP_NAME%'; $s=[IO.File]::OpenRead($p); try { $hash=([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($s))).Replace('-','').ToLower() } finally { $s.Dispose() }; Add-Content -LiteralPath '%SCRIPT_DIR%\Release\%CHECKSUMS%' -Value ($hash + '  ' + [IO.Path]::GetFileName($p)) -Encoding Ascii"
    if errorlevel 1 (
        echo Failed to add the ZIP checksum.
        exit /b 1
    )
) else (
    echo Zip not created.
    exit /b 1
)

echo.
echo Release %VERSION% ready in Release\%VERSION%\
echo Upload these four assets to the GitHub release tagged %VERSION%:
echo   Release\%ASSET32%
echo   Release\%ASSET64%
echo   Release\%ZIP_NAME%
echo   Release\%CHECKSUMS%
endlocal
