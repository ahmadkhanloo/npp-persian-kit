<#
    build/package.ps1 - build the plugin zips that nppPluginList / Plugins Admin expect.

    The Plugin List rules (npp-user-manual.org/docs/plugins, "Packaging") are
    strict about the layout: <folder-name>.dll has to sit at the ROOT of the
    zip. A wrapper folder - the old x64/PersianKit/PersianKit.dll - makes the
    CI validator fail with "Zip file does not contain PersianKit.dll", and even
    if it passed, Plugins Admin would extract it to plugins\x64\PersianKit\.

    Output (git-ignored):
        dist\release\PersianKit_x64.zip
        dist\release\PersianKit_x86.zip
    Each archive contains PersianKit.dll and README.txt at the root, nothing else.

    Usage:
        build\package.ps1                      # both architectures
        build\package.ps1 -Arch x64            # one of them
        build\package.ps1 -Version 1.3.1       # override src/version.h (CI guard)

    The version is taken from src/version.h and cross-checked against the DLL's
    numeric VERSIONINFO, so a stale binary can never be packaged by accident.
#>
[CmdletBinding()]
param(
    [string] $Version = '',
    [ValidateSet('x64', 'x86', 'all')] [string] $Arch = 'all'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo     = Split-Path -Parent $PSScriptRoot                 # build\ -> repo root
$folder   = 'PersianKit'
$dllDirs  = @{ x64 = 'dist\PersianKit'; x86 = 'dist\PersianKit-x86' }
$outDir   = Join-Path $repo 'dist\release'
$readmeT  = Join-Path $repo 'packaging\README.txt'

function Get-SourceVersion {
    $hit = Select-String -Path (Join-Path $repo 'src\version.h') `
                         -Pattern '^\s*#define\s+PK_VERSION_STR\s+"([^"]+)"' | Select-Object -First 1
    if (-not $hit) { throw 'PK_VERSION_STR not found in src/version.h' }
    $hit.Matches[0].Groups[1].Value
}

function ConvertTo-FourPart([string] $v) {
    $parts = @($v.Split('.'))
    if ($parts.Count -lt 1 -or $parts.Count -gt 4) { throw "cannot interpret version '$v'" }
    while ($parts.Count -lt 4) { $parts += '0' }
    $parts -join '.'
}

if (-not $Version) { $Version = Get-SourceVersion }
$expected4 = ConvertTo-FourPart $Version
if (-not (Test-Path $readmeT)) { throw "missing $readmeT" }

$archs = if ($Arch -eq 'all') { @('x64', 'x86') } else { @($Arch) }
$readme = (Get-Content $readmeT -Raw) -replace '@VERSION@', $Version

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$built = @()
foreach ($a in $archs)
{
    $dll = Join-Path $repo (Join-Path $dllDirs[$a] 'PersianKit.dll')
    if (-not (Test-Path $dll))
    {
        $script = if ($a -eq 'x86') { 'build\build-x86.bat' } else { 'build\build.bat' }
        throw "missing $dll - run $script first"
    }

    $vi  = (Get-Item $dll).VersionInfo
    $got = '{0}.{1}.{2}.{3}' -f $vi.FileMajorPart, $vi.FileMinorPart, $vi.FileBuildPart, $vi.FilePrivatePart
    if ($got -ne $expected4)
    {
        throw "$dll carries version $got but src/version.h says $expected4 - rebuild the DLL"
    }

    $zipPath = Join-Path $outDir "PersianKit_$a.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    $tmpReadme = Join-Path ([System.IO.Path]::GetTempPath()) "PersianKit-README-$a.txt"
    Set-Content -Path $tmpReadme -Value $readme -Encoding utf8 -NoNewline
    # Zip entries keep their source file's timestamp, so stamp the temp README with
    # the DLL's time: re-packaging the same DLL then gives the same SHA-256.
    (Get-Item $tmpReadme).LastWriteTime = (Get-Item $dll).LastWriteTime

    $archive = [System.IO.Compression.ZipFile]::Open($zipPath, 'Create')
    try
    {
        # Entry names are explicit: no staging directory, so no wrapper folder
        # can sneak into the archive.
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $dll, "$folder.dll", [System.IO.Compression.CompressionLevel]::Optimal)
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $tmpReadme, 'README.txt', [System.IO.Compression.CompressionLevel]::Optimal)
    }
    finally
    {
        $archive.Dispose()
        Remove-Item $tmpReadme -Force -ErrorAction SilentlyContinue
    }

    $size = (Get-Item $zipPath).Length
    $hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
    $built += [pscustomobject]@{ Arch = $a; Name = "PersianKit_$a.zip"; Bytes = $size; Sha256 = $hash }

    'packaged {0} ({1} B, dll version {2})' -f "PersianKit_$a.zip", $size, $got
}

# The kit (fonts, RTL stylesheets, installer) is not a plugin package - Plugins
# Admin never sees it - but every release used to carry it, so it is rebuilt here
# from kit/ with its contents at the root, exactly like the old assets.
$kitDir = Join-Path $repo 'kit'
$kitZip = Join-Path $outDir 'NotepadPlusPlus-Persian-Kit.zip'
if (Test-Path $kitDir)
{
    if (Test-Path $kitZip) { Remove-Item $kitZip -Force }
    $kitArchive = [System.IO.Compression.ZipFile]::Open($kitZip, 'Create')
    try
    {
        Get-ChildItem $kitDir -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($kitDir.Length + 1) -replace '\\', '/'
            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $kitArchive, $_.FullName, $rel, [System.IO.Compression.CompressionLevel]::Optimal)
        }
    }
    finally { $kitArchive.Dispose() }

    $kitSize = (Get-Item $kitZip).Length
    $built += [pscustomobject]@{
        Arch   = 'kit'
        Name   = 'NotepadPlusPlus-Persian-Kit.zip'
        Bytes  = $kitSize
        Sha256 = (Get-FileHash $kitZip -Algorithm SHA256).Hash.ToLower()
    }
    'packaged NotepadPlusPlus-Persian-Kit.zip ({0} B, contents of kit/)' -f $kitSize
}

''
'Use these values in the nppPluginList entry (ids are the zip SHA-256):'
$built | Format-Table -AutoSize | Out-String -Width 200
