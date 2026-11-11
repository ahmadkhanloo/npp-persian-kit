@echo off
rem Builds and runs the offline JSON-beautifier test.
rem   build\test\run-test.bat                 -> built-in samples
rem   build\test\run-test.bat path\to.json    -> also formats that file
setlocal enabledelayedexpansion
cd /d "%~dp0..\.."

set "VC_VARS="
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        if exist "%%i\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
    )
)
if not defined VC_VARS if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" set "VC_VARS=%ProgramFiles(x86)%\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if not defined VC_VARS (
    echo [!] vcvars64.bat not found - install the "Desktop development with C++" workload.
    exit /b 1
)
call "!VC_VARS!" >nul || exit /b 1

if not exist dist mkdir dist
cl /nologo /O2 /EHsc /W3 /DUNICODE /D_UNICODE build\test\jsonfmt_test.cpp ^
   /Fo:dist\ /Fe:dist\jsonfmt_test.exe user32.lib advapi32.lib
if errorlevel 1 exit /b 1

dist\jsonfmt_test.exe %*
endlocal
