<#
    build/test/verify-package.ps1 - offline pre-flight for the nppPluginList entry.

    Re-implements the checks of validator.py (notepad-plus-plus/nppPluginList) so
    a packaging mistake is caught here instead of in the PR's CI run. Per zip:

      1. it is a valid zip file
      2. it contains exactly one "<folder-name>.dll" and that entry is at the ROOT
         of the archive (the rule Plugins Admin depends on)
      3. the DLL's numeric VERSIONINFO, the same four parts validator.py reads,
         equals the expected version padded with zeroes
      4. the SHA-256 of the zip is what the list entry calls "id"

    With -Json it also checks the plugin list entries themselves: version, id,
    repository file name, and the uniqueness rules.

    Usage:
        build\test\verify-package.ps1 -Zip dist\release\PersianKit_*.zip
        build\test\verify-package.ps1 -Zip dist\release\PersianKit_x64.zip `
                                      -Json D:\Github\nppPluginList\src\pl.x64.json
        build\test\verify-package.ps1 -Zip https://github.com/.../PersianKit_x64.zip `
                                      -Json ...\pl.x64.json          # what CI downloads

    Exit code 0 = every rule holds, 1 = something would fail the PR's CI.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string[]] $Zip,
    [string] $Version = '',
    [string] $FolderName = 'PersianKit',
    [string[]] $Json = @()
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # build\test -> repo root

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
$dllName   = "$FolderName.dll"

$problems = 0
function Pass([string] $m) { "ok    $m" }
function Fail([string] $m) { $script:problems++; "FAIL  $m" }

$infos = @()

foreach ($target in $Zip)
{
    $path = $target
    if ($target -match '^https?://')
    {
        $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetFileName(([uri]$target).AbsolutePath))
        try   { Invoke-WebRequest -Uri $target -OutFile $path -TimeoutSec 120 }
        catch { Fail "$target : download failed - $($_.Exception.Message)"; continue }
    }

    if (-not (Test-Path $path)) { Fail "$path : not found"; continue }
    # ZipFile.OpenRead resolves relative paths against the process directory, not
    # the PowerShell one, so make it absolute first.
    $path = (Resolve-Path $path).Path

    $leaf = Split-Path $path -Leaf
    $hash = (Get-FileHash $path -Algorithm SHA256).Hash.ToLower()

    try { $archive = [System.IO.Compression.ZipFile]::OpenRead($path) }
    catch { Fail "$leaf : not a valid zip file - $($_.Exception.Message)"; continue }

    try
    {
        $names    = @($archive.Entries | ForEach-Object { $_.FullName })
        $rootDll  = @($names | Where-Object { [string]::Equals($_, $dllName, 'OrdinalIgnoreCase') })
        $nestedDll = @($names | Where-Object {
            $n = ($_ -replace '\\', '/')
            $n.Contains('/') -and [string]::Equals($n.Split('/')[-1], $dllName, 'OrdinalIgnoreCase')
        })

        if ($rootDll.Count -eq 1)
        {
            Pass "$leaf : $dllName is at the zip root"
        }
        elseif ($nestedDll.Count -gt 0)
        {
            Fail ("$leaf : $dllName is nested inside " + (($nestedDll | ForEach-Object { "'$_'" }) -join ', ') +
                  " - it must be at the root (CI: 'Zip file does not contain $dllName')")
        }
        else
        {
            Fail "$leaf : no $dllName anywhere in the archive (CI: 'Zip file does not contain $dllName')"
        }

        $extraTop = @($names | Where-Object {
            $n = ($_ -replace '\\', '/')
            -not $n.Contains('/') -and -not [string]::Equals($n, $dllName, 'OrdinalIgnoreCase')
        })
        if ($extraTop.Count -gt 0) { Pass "$leaf : extra root files allowed by the list: $($extraTop -join ', ')" }

        $entry = $archive.Entries | Where-Object { [string]::Equals($_.FullName, $dllName, 'OrdinalIgnoreCase') } | Select-Object -First 1
        $dll4  = $null
        if ($entry)
        {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "pk-verify-$([guid]::NewGuid().ToString('N')).dll"
            try
            {
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $tmp, $true)
                $vi   = (Get-Item $tmp).VersionInfo
                $dll4 = '{0}.{1}.{2}.{3}' -f $vi.FileMajorPart, $vi.FileMinorPart, $vi.FileBuildPart, $vi.FilePrivatePart
                if ($dll4 -eq '0.0.0.0')
                {
                    Fail "$leaf : the DLL has no version resource (CI: 'Does not contain any version information.')"
                }
                elseif ($dll4 -ne $expected4)
                {
                    Fail "$leaf : DLL version is $dll4 but $expected4 is expected (CI: 'Unexpected DLL version')"
                }
                else
                {
                    Pass "$leaf : DLL version $dll4 matches the list version $Version"
                }
            }
            finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
        }

        $infos += [pscustomobject]@{
            Name     = $leaf
            Path     = $path
            Sha256   = $hash
            DllFour  = $dll4
            Entries  = $names -join ' | '
        }
        "      sha256 = $hash"
    }
    finally { $archive.Dispose() }
}

foreach ($j in $Json)
{
    if (-not (Test-Path $j)) { Fail "$j : not found"; continue }
    $pl = Get-Content $j -Raw | ConvertFrom-Json
    $entries = @($pl.'npp-plugins')

    $entry = $entries | Where-Object { $_.'folder-name' -eq $FolderName } | Select-Object -First 1
    if (-not $entry) { Fail "$j : no entry with folder-name '$FolderName'"; continue }

    # uniqueness rules from unique_json_keys_check()
    foreach ($key in 'display-name', 'folder-name', 'repository')
    {
        $dup = @($entries | Where-Object { $_.$key -eq $entry.$key })
        if ($dup.Count -gt 1) { Fail "$j : non unique $key '$($entry.$key)'" }
        else                  { Pass "$j : $key '$($entry.$key)' is unique" }
    }

    $entryFour = ConvertTo-FourPart $entry.version
    if ($entryFour -ne $expected4) { Fail "$j : entry version '$($entry.version)' != expected '$expected4'" }

    $match = $infos | Where-Object { $_.Sha256 -eq "$($entry.id)".ToLower() } | Select-Object -First 1
    if (-not $match)
    {
        Fail "$j : id $($entry.id) matches none of the zips given with -Zip"
        continue
    }

    Pass "$j : id matches $($match.Name)"
    if ($match.DllFour -and $match.DllFour -ne $entryFour)
    {
        Fail "$j : entry version $entryFour but $($match.Name) carries $($match.DllFour)"
    }

    $repoLeaf = ($entry.repository -split '/')[-1]
    if ($repoLeaf -ne $match.Name) { Fail "$j : repository ends with '$repoLeaf' but the matching zip is '$($match.Name)'" }
    else                           { Pass "$j : repository points at $repoLeaf" }
}

''
if ($problems -eq 0) { "PASS - the packages satisfy the nppPluginList rules (version $expected4)"; exit 0 }
"FAILED - $problems problem(s); the PR's CI would reject this"; exit 1
