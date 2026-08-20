# ==========================================================
#  אורז את הווידג'ט לשני קבצים בודדים וניידים:
#    Install-CountdownWidget.vbs   - קובץ התקנה (קוד + ציורים מוטמעים)
#    CountdownWidget-Portable.cmd  - הרצה בלי התקנה
#  מקורות: CountdownWidget.ps1, assets\*.png, build\Installer.ps1
#  הרץ אחרי כל שינוי באחד מהם, ואז Build-GiftMaker.ps1.
# ==========================================================
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$widgetPs1    = Join-Path $dir 'CountdownWidget.ps1'
$assetDir     = Join-Path $dir 'assets'
$installerPs1 = Join-Path $dir 'build\Installer.ps1'
$outInstaller = Join-Path $dir 'Install-CountdownWidget.vbs'
$outPortable  = Join-Path $dir 'CountdownWidget-Portable.cmd'

foreach ($p in @($widgetPs1, $installerPs1, $assetDir)) {
    if (-not (Test-Path $p)) { throw "לא נמצא: $p" }
}

# ---------- עזרים ----------

# קריאת קובץ UTF-8 ונרמול סופי שורה ל-LF (כך נבנו הקבצים המקוריים)
function Read-SourceText([string]$path) {
    ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)) -replace "`r`n", "`n"
}

# מפת הציורים כשורות PowerShell:  'שם.png' = 'base64'
function Get-AssetMapLines([string]$indent) {
    $files = @(Get-ChildItem -Path $assetDir -Filter *.png -File | Sort-Object Name)
    if ($files.Count -eq 0) { throw "לא נמצאו ציורים ב-$assetDir" }
    $out = foreach ($f in $files) {
        $b64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($f.FullName))
        "$indent'$($f.Name)' = '$b64'"
    }
    ,@($out)
}

# קידוד ה-payload ל-base64 עטוף בשורות, עם תחילית לכל שורה (גרש ב-VBS, ריק ב-CMD)
function ConvertTo-WrappedBase64([string]$text, [int]$width, [string]$linePrefix) {
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($text))
    $sb  = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $b64.Length; $i += $width) {
        if ($i -gt 0) { [void]$sb.Append("`r`n") }
        [void]$sb.Append($linePrefix).Append($b64.Substring($i, [Math]::Min($width, $b64.Length - $i)))
    }
    $sb.ToString()
}

# כתיבה כ-ASCII: המעטפת וה-base64 כולם ASCII, כך ש-wscript/cmd יפרשו נכון
function Write-AsciiFile([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.ASCIIEncoding))
}

$widgetText = Read-SourceText $widgetPs1

# ==========================================================
#  1. קובץ ההתקנה
# ==========================================================
$assetLines  = Get-AssetMapLines '    '
$widgetB64   = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($widgetText))

$installerPayload =
    '$EmbeddedAssets = @{' + "`n" +
    (($assetLines) -join "`n") + "`n" +
    '}' + "`n`n" +
    "`$WidgetB64 = '$widgetB64'" + "`n`n" +
    (Read-SourceText $installerPs1)

$installerStub = @"
' ============================================================
'  Countdown Widget - single file installer (Hebrew RTL)
'  Double click to install. No console window, no taskbar entry.
' ============================================================
Set sh = CreateObject("WScript.Shell")
me_ = WScript.ScriptFullName
cmd = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command """ & _
      "`$p='" & me_ & "'; `$t=[IO.File]::ReadAllText(`$p); `$i=`$t.LastIndexOf('#PAYLOAD64#')+11; `$b=(`$t.Substring(`$i) -replace ('(?m)^'+[char]39), ''); `$s=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$b)); `$InstallerPath=`$p; Invoke-Expression `$s" & """"
sh.Run cmd, 0, False
WScript.Quit
'#PAYLOAD64#
"@

Write-AsciiFile $outInstaller ($installerStub + "`r`n" + (ConvertTo-WrappedBase64 $installerPayload 200 "'"))

# ==========================================================
#  2. הגרסה הניידת
#  אותו קוד ווידג'ט, כשראש הקובץ מוחלף: נתונים ב-%APPDATA%
#  והציורים מוטמעים ונחלצים בהפעלה הראשונה.
# ==========================================================
$localHeader = @'
$script:Root       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:ConfigPath = Join-Path $script:Root 'config.json'
$script:PortableFile = $null
'@ -replace "`r`n", "`n"

if (-not $widgetText.Contains($localHeader)) {
    throw "ראש הקובץ ב-CountdownWidget.ps1 השתנה - יש לעדכן את `$localHeader ב-Build-Installer.ps1."
}

$portableHeader = @'
$script:Root = Join-Path $env:APPDATA 'BabyCountdownWidget'
if (-not (Test-Path $script:Root)) { New-Item -ItemType Directory -Path $script:Root -Force | Out-Null }
$script:ConfigPath   = Join-Path $script:Root 'config.json'
$script:PortableFile = $global:PortableFile

# ---- הציורים מוטמעים בקובץ ונחלצים בהפעלה הראשונה ----
$script:EmbeddedAssets = @{
__ASSETS__
}
$script:AssetDir = Join-Path $script:Root 'assets'
if (-not (Test-Path $script:AssetDir)) { New-Item -ItemType Directory -Path $script:AssetDir -Force | Out-Null }
foreach ($k in @($script:EmbeddedAssets.Keys)) {
    $p = Join-Path $script:AssetDir $k
    $bytes = [Convert]::FromBase64String($script:EmbeddedAssets[$k])
    if (-not (Test-Path $p) -or (Get-Item $p).Length -ne $bytes.Length) { [IO.File]::WriteAllBytes($p, $bytes) }
}

'@ -replace "`r`n", "`n"

$portableHeader  = $portableHeader.Replace('__ASSETS__', (($assetLines) -join "`n"))
$portablePayload = $widgetText.Replace($localHeader, $portableHeader.TrimEnd("`n") + "`n")

$portableStub = @'
@echo off
rem ============================================================
rem  Countdown Widget - portable single file (Hebrew RTL)
rem  Double click to run. Data folder: %APPDATA%\BabyCountdownWidget
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$f='%~f0'; $t=[IO.File]::ReadAllText($f); $i=$t.LastIndexOf('#PAYLOAD64#')+11; $s=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($t.Substring($i))); $global:PortableFile=$f; Invoke-Expression $s"
exit /b
#PAYLOAD64#
'@

Write-AsciiFile $outPortable ($portableStub + "`r`n" + (ConvertTo-WrappedBase64 $portablePayload 200 ''))

# ---------- סיכום ----------
foreach ($f in @($outInstaller, $outPortable)) {
    $mb = [Math]::Round((Get-Item $f).Length / 1MB, 2)
    Write-Host ("נוצר: {0} ({1} MB)" -f (Split-Path -Leaf $f), $mb)
}
