@echo off
rem ---------------------------------------------------------------
rem  Build the 32-bit PersianKit.dll (for 32-bit Notepad++).
rem  Run from a normal command prompt:  build\build-x86.bat
rem  Output: dist\PersianKit-x86\PersianKit.dll
rem ---------------------------------------------------------------
setlocal enabledelayedexpansion
cd /d "%~dp0.."

set "VC_VARS="
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        if exist "%%i\VC\Auxiliary\Build\vcvars32.bat" set "VC_VARS=%%i\VC\Auxiliary\Build\vcvars32.bat"
    )
)
if not defined VC_VARS if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars32.bat" set "VC_VARS=%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars32.bat"
if not defined VC_VARS if exist "%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars32.bat" set "VC_VARS=%ProgramFiles%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars32.bat"

if not defined VC_VARS (
    echo [!] vcvars32.bat not found - install the "Desktop development with C++" workload.
    exit /b 1
)

echo Using: !VC_VARS!
call "!VC_VARS!" >nul || exit /b 1

if not exist dist\PersianKit-x86 mkdir dist\PersianKit-x86 dist\PersianKit-x86

cl /nologo /LD /O2 /EHsc /W3 /DUNICODE /D_UNICODE ^
   src\PersianKit.cpp ^
   /Fo:dist\PersianKit-x86\ ^
   /Fe:dist\PersianKit-x86\PersianKit.dll ^
   user32.lib advapi32.lib
if errorlevel 1 exit /b 1

echo.
echo Built: dist\PersianKit-x86\PersianKit.dll
endlocal
