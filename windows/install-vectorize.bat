@echo off
rem install-vectorize.bat - installs the vectorize CLI for the current user.
rem   - copies vectorize.bat to a dir already on the user PATH when possible
rem   - falls back to a Programs dir + PATH registry update (no admin needed)
rem   - --deps: installs ImageMagick + potrace via winget, vtracer via pip
rem   - --system: installs for all users (run from an elevated shell)
rem Usage: install-vectorize.bat [--deps] [--system]
setlocal EnableExtensions DisableDelayedExpansion

set "SRC=%~dp0vectorize.bat"
if not exist "%SRC%" (
    echo installer error: vectorize.bat not found in "%~dp0" 1>&2
    echo   keep vectorize.bat and install-vectorize.bat in the same folder 1>&2
    exit /b 1
)

set "DEPS=0"
set "SYSTEM=0"
if /i "%~1"=="--deps" set "DEPS=1"
if /i "%~1"=="--system" set "SYSTEM=1"
if /i "%~2"=="--deps" set "DEPS=1"
if /i "%~2"=="--system" set "SYSTEM=1"

if "%SYSTEM%"=="0" goto install_main
net session >nul 2>&1
if errorlevel 1 (
    echo installer error: --system needs an elevated shell. Right-click and run as administrator 1>&2
    exit /b 1
)

:install_main
set "INSTALLDIR=%LOCALAPPDATA%\Microsoft\WindowsApps"
if "%SYSTEM%"=="1" set "INSTALLDIR=%ProgramFiles%\Vectorize"
if exist "%INSTALLDIR%" goto install_copy

rem - WindowsApps missing on some systems: fall back to a Programs dir.
if "%SYSTEM%"=="1" goto make_dir
set "INSTALLDIR=%LOCALAPPDATA%\Programs\Vectorize"

:make_dir
mkdir "%INSTALLDIR%" 2>nul
if exist "%INSTALLDIR%" goto install_copy
echo installer error: cannot create "%INSTALLDIR%" 1>&2
exit /b 1

:install_copy
copy /y "%SRC%" "%INSTALLDIR%\vectorize.bat" >nul
if errorlevel 1 (
    echo installer error: could not copy vectorize.bat to "%INSTALLDIR%" 1>&2
    exit /b 1
)
echo Installed: "%INSTALLDIR%\vectorize.bat"

if "%SYSTEM%"=="1" goto system_path_note
call :ensure_user_path
if errorlevel 1 exit /b 1
goto register_profiles

:system_path_note
echo   add "%INSTALLDIR%" to the SYSTEM PATH if it is not already there
echo   via System Properties ^> Environment Variables ^> Path ^> New
call :register_profiles

:register_profiles
call :register_profile powershell
where /q pwsh 2>nul
if not errorlevel 1 call :register_profile pwsh
echo   in an already-open PowerShell you can enable it right away: . $PROFILE
goto maybe_deps

:maybe_deps
if not "%DEPS%"=="1" goto selftest
call :do_deps

:selftest
call "%INSTALLDIR%\vectorize.bat" -h >nul 2>nul
if errorlevel 1 (
    echo Self-test FAILED: "%INSTALLDIR%\vectorize.bat" -h exited nonzero 1>&2
    exit /b 1
)
echo Self-test OK: vectorize -h
echo Done. Usage: vectorize [-c ^| --color] INPUT.png [OUTPUT.svg]
exit /b 0

:register_profile
rem %1 = powershell | pwsh
set "RP_PROFILE="
for /f "usebackq delims=" %%P in (`%~1 -NoProfile -Command "$PROFILE" 2^>nul`) do set "RP_PROFILE=%%P"
if not defined RP_PROFILE exit /b 0
for %%P in ("%RP_PROFILE%") do set "RP_DIR=%%~dpP"
if not exist "%RP_DIR%" mkdir "%RP_DIR%" 2>nul
if not exist "%RP_PROFILE%" type nul > "%RP_PROFILE%"
findstr /i /c:"vectorize shim" "%RP_PROFILE%" >nul 2>&1
if not errorlevel 1 (
    find /i "%INSTALLDIR%" "%RP_PROFILE%" >nul 2>&1
    if errorlevel 1 (
        echo   NOTE: "%RP_PROFILE%" already has a vectorize shim for another install folder
        echo         remove its block and re-run this installer to repoint it
    ) else (
        echo   already registered in %~1 profile: "%RP_PROFILE%"
    )
    exit /b 0
)
set "RP_ESC=%INSTALLDIR%"
set "RP_ESC=%RP_ESC:^=^^%"
set "RP_ESC=%RP_ESC:&=^&%"
set "RP_ESC=%RP_ESC:(=^(%"
set "RP_ESC=%RP_ESC:)=^)%"
(
    echo.
    echo # ^>^>^> vectorize shim
    echo $Global:VectorizeShim = '%RP_ESC%'
    echo function vectorize {
    echo     ^& $Global:VectorizeShim @args
    echo }
    echo # ^<^<^< vectorize shim
) >> "%RP_PROFILE%"
echo   registered for %~1: one-line command "vectorize" in "%RP_PROFILE%"
exit /b 0

:do_deps
echo Checking dependencies...
where /q magick 2>nul
if not errorlevel 1 (
    echo   OK: ImageMagick
    goto dep_potrace
)
where /q winget 2>nul
if errorlevel 1 (
    echo   MISSING: ImageMagick. Install it from https://imagemagick.org/script/download.php#windows 1>&2
    goto dep_potrace
)
echo   Installing ImageMagick via winget...
winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
:dep_potrace
where /q potrace 2>nul
if not errorlevel 1 (
    echo   OK: potrace
    goto dep_vtracer
)
where /q winget 2>nul
if errorlevel 1 (
    echo   MISSING: potrace. Install from https://potrace.sourceforge.net or run: choco install potrace 1>&2
    goto dep_vtracer
)
echo   Installing potrace via winget...
winget install --id Potrace.Potrace -e --accept-source-agreements --accept-package-agreements
:dep_vtracer
where /q vtracer 2>nul
if not errorlevel 1 (
    echo   OK: vtracer
    goto dep_done
)
where /q pip 2>nul
if errorlevel 1 (
    echo   MISSING: pip. Install Python, then run: pip install --user vtracer 1>&2
    goto dep_done
)
echo   Installing vtracer via pip...
pip install --user vtracer
:dep_done
echo NOTE: open a NEW terminal so freshly installed tools appear on PATH.
exit /b 0

:ensure_user_path
echo "%PATH%" | find /i "%INSTALLDIR%" >nul
if not errorlevel 1 (
    echo   "%INSTALLDIR%" is already on your PATH
    exit /b 0
)
set "ENV_TYPE="
set "USER_PATH="
for /f "tokens=2*" %%A in ('reg query HKCU\Environment /v Path 2^>nul ^| findstr /i "REG_"') do (
    set "ENV_TYPE=%%A"
    set "USER_PATH=%%B"
)
if not defined ENV_TYPE set "ENV_TYPE=REG_SZ"
if not defined USER_PATH set "USER_PATH=%INSTALLDIR%"
if not "%USER_PATH%"=="%INSTALLDIR%" set "USER_PATH=%USER_PATH%;%INSTALLDIR%"
reg add HKCU\Environment /v Path /t %ENV_TYPE% /d "%USER_PATH%" /f >nul
if errorlevel 1 (
    echo   WARNING: could not update the user PATH registry value 1>&2
    echo   Add "%INSTALLDIR%" to your user PATH manually 1>&2
    exit /b 1
)
echo   Added "%INSTALLDIR%" to the user PATH
echo   NOTE: open a NEW terminal for it to take effect; sign out and back in if it still fails
exit /b 0
