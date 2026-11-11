@echo off
rem ---------------------------------------------------------------
rem  Build PersianKit.dll (x64) with the MSVC toolchain.
rem  Run from a normal command prompt:  build\build.bat
rem  Output: dist\PersianKit\PersianKit.dll
rem ---------------------------------------------------------------
setlocal enabledelayedexpansion
cd /d "%~dp0.."

set "VC_VARS="

rem 1) ask vswhere (shipped with every Visual Studio / Build Tools)
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        if exist "%%i\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
    )
)

rem 2) fall back to the usual install locations
if not defined VC_VARS if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

if not defined VC_VARS (
    echo [!] vcvars64.bat not found.
    echo     Install "Visual Studio Build Tools" with the "Desktop development with C++"
    echo     workload, or let the GitHub Actions workflow build the DLL for you.
    exit /b 1
)

echo Using: !VC_VARS!
call "!VC_VARS!" >nul || exit /b 1

if not exist dist\PersianKit mkdir dist\PersianKit

cl /nologo /LD /O2 /EHsc /W3 /DUNICODE /D_UNICODE ^
   src\PersianKit.cpp ^
   /Fo:dist\PersianKit\ ^
   /Fe:dist\PersianKit\PersianKit.dll ^
   user32.lib advapi32.lib
if errorlevel 1 exit /b 1

echo.
echo Built: dist\PersianKit\PersianKit.dll
echo Install with:  powershell -ExecutionPolicy Bypass -File build\install-plugin.ps1
endlocal
