@echo off
setlocal
cd /d "%~dp0"
echo Installing the Notepad++ Persian Kit...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
