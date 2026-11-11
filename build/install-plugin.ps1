<#
    install-plugin.ps1 - copy PersianKit.dll into Notepad++ (needs administrator)

    Notepad++ only loads plugins from its own installation folder, so this step
    requires elevation (a UAC prompt will appear).

    Usage:
        powershell -ExecutionPolicy Bypass -File build\install-plugin.ps1
#>
$ErrorActionPreference = 'Stop'

$dll = Join-Path $PSScriptRoot '..\dist\PersianKit\PersianKit.dll'
if (-not (Test-Path $dll)) {
    Write-Host "Build the plugin first: build\build.bat" -ForegroundColor Red
    exit 1
}

$nppExe = @(
    'C:\Program Files\Notepad++\notepad++.exe',
    'C:\Program Files (x86)\Notepad++\notepad++.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $nppExe) { Write-Host "Notepad++ not found." -ForegroundColor Red; exit 1 }
$pluginsDir = Join-Path (Split-Path $nppExe) 'plugins\PersianKit'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
              [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Elevating (a UAC prompt will appear)..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    exit
}

if (Get-Process notepad++ -ErrorAction SilentlyContinue) {
    Write-Host "Close Notepad++ first, then run this again." -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}

New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null
Copy-Item $dll $pluginsDir -Force
Write-Host "Installed to $pluginsDir" -ForegroundColor Green
Write-Host "Start Notepad++, then open Plugins > PersianKit." -ForegroundColor Green
Read-Host "Press Enter to close"
