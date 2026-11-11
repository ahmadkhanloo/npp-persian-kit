<#
    install.ps1  -  Notepad++ Persian Kit (RTL + Vazirmatn + pretty JSON + RTL markdown preview)

    What it does (all per-user, no admin rights needed):
      1. installs the Vazirmatn fonts for the current user
      2. patches Notepad++ config.xml   (disable DirectWrite -> enables native RTL, word wrap on)
      3. patches Notepad++ stylers.xml  (JSON: nicer colours + Consolas, keeps folding)
      4. patches the Markdown UDLs      (editor font -> Vazirmatn)
      5. installs the RTL/Persian CSS for the "Markdown Panel" plugin and points the plugin at it

    Close Notepad++ before running this script; reopen it afterwards.

    Undo: every edited file is backed up next to the original as  <name>.bak-<timestamp>
#>

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($text) { Write-Host "  * $text" -ForegroundColor Cyan }
function Ok($text)   { Write-Host "    $text" -ForegroundColor Green }
function Warn($text) { Write-Host "    $text" -ForegroundColor Yellow }

Write-Host ""
Write-Host "Notepad++ Persian Kit" -ForegroundColor White
Write-Host "---------------------" -ForegroundColor DarkGray

if (Get-Process notepad++ -ErrorAction SilentlyContinue) {
    Warn "Notepad++ appears to be running. Close it now, otherwise it will overwrite the changes when it exits."
    Read-Host "Press Enter to continue anyway (or Ctrl+C to abort)"
}

# ---------------------------------------------------------------- 1. fonts
Step "Installing Vazirmatn fonts (current user)"
$fontSrc = Join-Path $here 'fonts'
$fontDst = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item -ItemType Directory -Force -Path $fontDst | Out-Null
$fontReg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
Add-Type -Name FontApi -Namespace NppKit -MemberDefinition '[DllImport("gdi32.dll", CharSet=CharSet.Unicode)] public static extern int AddFontResourceW(string f);'
$installed = 0
if (Test-Path $fontSrc) {
    Get-ChildItem $fontSrc -Filter *.ttf | ForEach-Object {
        $target = Join-Path $fontDst $_.Name
        $needCopy = $true
        if (Test-Path $target) {
            if ((Get-Item $target).Length -eq $_.Length) { $needCopy = $false }
        }
        if ($needCopy) {
            try {
                Copy-Item $_.FullName $target -Force
            } catch {
                Warn "could not copy $($_.Name) (font file in use) - already installed, continuing"
            }
        }
        $family = $_.BaseName -replace '^Vazirmatn-NL-', 'Vazirmatn NL '
        $family = $family    -replace '^Vazirmatn-',    'Vazirmatn '
        New-ItemProperty -Path $fontReg -Name "$family (TrueType)" -Value $target -PropertyType String -Force | Out-Null
        [void][NppKit.FontApi]::AddFontResourceW($target)
        $installed++
    }
    Ok "$installed font files installed"
} else {
    Warn "fonts folder not found - skipping (install Vazirmatn manually from github.com/rastikerdar/vazirmatn)"
}

# ------------------------------------------------------- 2. locate config dir
$nppExe = @(
    'C:\Program Files\Notepad++\notepad++.exe',
    'C:\Program Files (x86)\Notepad++\notepad++.exe',
    (Join-Path $env:LOCALAPPDATA 'Programs\Notepad++\notepad++.exe')
) | Where-Object { Test-Path $_ } | Select-Object -First 1

$cfgDir = Join-Path $env:APPDATA 'Notepad++'
if ($nppExe -and (Test-Path (Join-Path (Split-Path $nppExe) 'doLocalConf.xml'))) {
    $cfgDir = Split-Path $nppExe            # portable mode
    Step "Portable Notepad++ detected"
}
if (-not (Test-Path $cfgDir)) {
    Write-Host "Notepad++ user config folder not found: $cfgDir" -ForegroundColor Red
    Write-Host "Start Notepad++ once, close it, and run this script again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Ok "config folder: $cfgDir"

function Backup($path) {
    if (Test-Path $path) {
        $bak = "$path.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item $path $bak -Force
    }
}

# ------------------------------------------------------------ 3. config.xml
Step "Patching config.xml (disable DirectWrite = enables RTL, turn word wrap on)"
$configXml = Join-Path $cfgDir 'config.xml'
if (Test-Path $configXml) {
    Backup $configXml
    $t = [IO.File]::ReadAllText($configXml)
    $t = [regex]::Replace($t, 'writeTechnologyEngine="\d"', 'writeTechnologyEngine="0"')
    $t = [regex]::Replace($t, 'Wrap="(no|yes)"', 'Wrap="yes"')
    [IO.File]::WriteAllText($configXml, $t, (New-Object Text.UTF8Encoding($false)))
    Ok "DirectWrite off, word wrap on  (toggle RTL/LTR later with Ctrl+Alt+R)"
} else {
    Warn "config.xml missing - skipped"
}

# ------------------------------------------------------------ 4. stylers.xml
Step "Patching stylers.xml (JSON colours + Consolas)"
$stylers = Join-Path $cfgDir 'stylers.xml'
if (Test-Path $stylers) {
    Backup $stylers
    $t = [IO.File]::ReadAllText($stylers)
    $jsonBlock = @'
<LexerType name="json" desc="JSON" ext="">
            <WordsStyle name="DEFAULT" styleID="0" fgColor="1F2328" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="NUMBER" styleID="1" fgColor="098658" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="STRING" styleID="2" fgColor="A31515" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="STRING EOL" styleID="3" fgColor="8A8A8A" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="PROPERTY NAME" styleID="4" fgColor="0451A5" bgColor="FFFFFF" fontName="Consolas" fontStyle="1" fontSize="11" />
            <WordsStyle name="ESCAPE SEQUENCE" styleID="5" fgColor="D12F1B" bgColor="FFFFFF" fontName="Consolas" fontStyle="1" fontSize="11" />
            <WordsStyle name="LINE COMMENT" styleID="6" fgColor="008000" bgColor="FFFFFF" fontName="Consolas" fontStyle="2" fontSize="11" />
            <WordsStyle name="BLOCK COMMENT" styleID="7" fgColor="008000" bgColor="FFFFFF" fontName="Consolas" fontStyle="2" fontSize="11" />
            <WordsStyle name="OPERATOR" styleID="8" fgColor="5A5A5A" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="URI" styleID="9" fgColor="0451A5" bgColor="FFFFFF" fontName="Consolas" fontStyle="0" fontSize="11" />
            <WordsStyle name="COMPACT IRI" styleID="10" fgColor="0451A5" bgColor="FFFFFF" fontName="Consolas" fontStyle="1" fontSize="11" />
            <WordsStyle name="KEYWORD" styleID="11" fgColor="0000C0" bgColor="FFFFFF" fontName="Consolas" fontStyle="1" fontSize="11" keywordClass="instre1" />
            <WordsStyle name="LD KEYWORD" styleID="12" fgColor="AF00DB" bgColor="FFFFFF" fontName="Consolas" fontStyle="1" fontSize="11" keywordClass="instre2" />
            <WordsStyle name="ERROR" styleID="13" fgColor="FFFFFF" bgColor="E45649" fontName="Consolas" fontStyle="1" fontSize="11" />
        </LexerType>
'@
    if ($t -notmatch 'name="json"') {
        Warn "JSON lexer not found in this Notepad++ version - skipped"
    } elseif ($t -match 'PROPERTY NAME" styleID="4" fgColor="0451A5"') {
        Ok "already patched"
    } else {
        $t = [regex]::Replace($t, '(?s)<LexerType name="json".*?</LexerType>', $jsonBlock)
        [IO.File]::WriteAllText($stylers, $t, (New-Object Text.UTF8Encoding($false)))
        Ok "JSON styles updated"
    }
} else {
    Warn "stylers.xml missing - skipped"
}

# ---------------------------------------------------------------- 5. UDL font
Step "Setting the Markdown editor font to Vazirmatn"
$udlDir = Join-Path $cfgDir 'userDefineLangs'
$patched = 0
$udlFiles = @()
if (Test-Path $udlDir) {
    $udlFiles = @(Get-ChildItem $udlDir -Filter 'markdown*.udl.xml' -Force -ErrorAction SilentlyContinue)
    foreach ($udl in $udlFiles) {
        $t = [IO.File]::ReadAllText($udl.FullName)
        if ($t -match 'fontName=""') {
            Backup $udl.FullName
            $t = $t -replace 'fontName=""', 'fontName="Vazirmatn"'
            [IO.File]::WriteAllText($udl.FullName, $t, (New-Object Text.UTF8Encoding($false)))
            $patched++
        }
    }
}
if ($udlFiles.Count -eq 0) { Warn "no Markdown UDL found (open a .md file once in Notepad++, close it, run again)" }
elseif ($patched -gt 0)   { Ok "$patched Markdown UDL file(s) patched -> Vazirmatn" }
else                      { Ok "Markdown UDL already use Vazirmatn" }

# ------------------------------------------------- 6/7. markdown preview CSS
Step "Installing Persian CSS for the Markdown Panel plugin"
$pluginCfg = Join-Path $cfgDir 'plugins\config'
New-Item -ItemType Directory -Force -Path $pluginCfg | Out-Null
$cssDir = Join-Path $here 'css'
Copy-Item (Join-Path $cssDir 'persian-markdown.css')      $pluginCfg -Force
Copy-Item (Join-Path $cssDir 'persian-markdown-dark.css') $pluginCfg -Force
Ok "persian-markdown.css / persian-markdown-dark.css copied"

$ini = Join-Path $pluginCfg 'NppMarkdownPanel.ini'
if (Test-Path $ini) {
    Backup $ini
    $lines = Get-Content $ini
    $want = [ordered]@{
        CssFileName         = (Join-Path $pluginCfg 'persian-markdown.css')
        CssDarkModeFileName = (Join-Path $pluginCfg 'persian-markdown-dark.css')
        ZoomLevel           = '100'
        AutoShowPanel       = 'True'
        RenderingEngine     = 'EDGE'
        SupportedFileExt    = 'md,mkd,mdwn,mdown,mdtxt,markdown,txt'
    }
    $seen = @{}
    $out = foreach ($line in $lines) {
        $m = [regex]::Match($line, '^([A-Za-z]+)=')
        if ($m.Success -and $want.Contains($m.Groups[1].Value)) {
            $k = $m.Groups[1].Value; $seen[$k] = $true
            "$k=$($want[$k])"
        } else { $line }
    }
    foreach ($k in $want.Keys) { if (-not $seen.ContainsKey($k)) { $out += "$k=$($want[$k])" } }
    Set-Content -Path $ini -Value $out -Encoding ASCII
    Ok "plugin settings updated (CSS file + zoom + auto preview for .md/.txt)"
} else {
    Warn "Markdown Panel plugin not installed -> install it first:"
    Warn "   Plugins > Plugins Admin > search 'Markdown Panel' > Install > restart Notepad++"
    Warn "   then run this script again (the CSS files are already in place)"
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "  - reopen Notepad++"
Write-Host "  - in a Persian .md press Ctrl+Alt+R to flip right-to-left / left-to-right"
Write-Host "  - Markdown Panel preview: Plugins > MarkdownPanel > Settings (CSS file / zoom)"
Write-Host "  - backups of every edited file are next to the originals (*.bak-<date>)"
Write-Host ""
Read-Host "Press Enter to close"
