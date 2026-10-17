@echo off
rem vectorize - raster (PNG) to SVG. Default: black vector (potrace).
rem -c / --color: color layers (vtracer).
rem Usage: vectorize [-c|--color] INPUT.png [OUTPUT.svg]
setlocal EnableExtensions DisableDelayedExpansion

set "VZ_COLOR=0"
set "VZ_INPUT="
set "VZ_OUTPUT="

if /i "%~1"=="/?" goto show_usage
if /i "%~1"=="-h" goto show_usage
if /i "%~1"=="--help" goto show_usage
if /i "%~1"=="/c" goto arg_color
if /i "%~1"=="-c" goto arg_color
if /i "%~1"=="--color" goto arg_color

set "VZ_INPUT=%~1"
set "VZ_OUTPUT=%~2"
goto have_args

:arg_color
set "VZ_COLOR=1"
set "VZ_INPUT=%~2"
set "VZ_OUTPUT=%~3"

:have_args
if not defined VZ_INPUT (
    echo vectorize: missing INPUT.png. Usage: vectorize [-c ^| --color] INPUT.png [OUTPUT.svg] 1>&2
    exit /b 1
)
if not exist "%VZ_INPUT%" (
    echo vectorize: input not found: "%VZ_INPUT%" 1>&2
    exit /b 1
)
if "%VZ_COLOR%"=="1" goto color_path
goto bw_path

:color_path
where /q vtracer 2>nul
if errorlevel 1 goto no_vtracer
if defined VZ_OUTPUT goto color_run
for %%I in ("%VZ_INPUT%") do set "VZ_OUTPUT=%%~dpnI.svg"

:color_run
vtracer --input "%VZ_INPUT%" --output "%VZ_OUTPUT%" --colormode color --mode spline
set "VZ_RC=%ERRORLEVEL%"
if not "%VZ_RC%"=="0" exit /b %VZ_RC%
echo SVG written: "%VZ_OUTPUT%"
exit /b 0

:bw_path
where /q potrace 2>nul
if errorlevel 1 goto no_potrace
call :find_magick
if errorlevel 1 goto no_imagemagick
if defined VZ_OUTPUT goto bw_run
for %%I in ("%VZ_INPUT%") do set "VZ_OUTPUT=%%~dpnI.svg"

:bw_run
set "VZ_TMP=%TEMP%\vectorize-%RANDOM%%RANDOM%.pgm"
"%VZ_CONV%" "%VZ_INPUT%" -flatten -grayscale Rec709Luminance -threshold 50%% "%VZ_TMP%"
if not errorlevel 1 goto bw_potrace
del "%VZ_TMP%" 2>nul
echo vectorize: %VZ_CONV% failed while preprocessing "%VZ_INPUT%" 1>&2
exit /b 1

:bw_potrace
potrace "%VZ_TMP%" -s -o "%VZ_OUTPUT%"
set "VZ_RC=%ERRORLEVEL%"
del "%VZ_TMP%" 2>nul
if not "%VZ_RC%"=="0" exit /b %VZ_RC%
echo SVG written: "%VZ_OUTPUT%"
exit /b 0

:show_usage
echo vectorize: raster (PNG) to SVG. Default: black vector via potrace.
echo Usage: vectorize [-c ^| --color] INPUT.png [OUTPUT.svg]
echo.
echo   INPUT.png     input image
echo   OUTPUT.svg    output file; default: INPUT with .svg extension
echo.
echo Options:
echo   -c, --color   color tracing via vtracer
echo   -h, --help    show this help
exit /b 0

:no_potrace
echo vectorize: potrace not found. 1>&2
echo   install it with: winget install Potrace.Potrace  or  choco install potrace 1>&2
exit /b 1

:no_imagemagick
echo vectorize: ImageMagick not found - need magick or convert. 1>&2
echo   install it with: winget install ImageMagick.ImageMagick 1>&2
exit /b 1

:no_vtracer
echo vectorize: color tracing needs vtracer. 1>&2
echo   install it with: pip install --user vtracer 1>&2
exit /b 1

:find_magick
set "VZ_CONV="
where /q magick 2>nul
if not errorlevel 1 (
    set "VZ_CONV=magick"
    exit /b 0
)
where /q convert 2>nul
if errorlevel 1 exit /b 1
convert -version 2>nul | findstr /i /c:"ImageMagick" >nul
if errorlevel 1 exit /b 1
set "VZ_CONV=convert"
exit /b 0
