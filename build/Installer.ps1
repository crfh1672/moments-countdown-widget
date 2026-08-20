# ============================================================
#  מתקין - ווידג'ט ספירה לאחור לרגעים מרגשים
#  מותקן ל-%LOCALAPPDATA%\BabyCountdownWidget ורץ חבוי לגמרי
# ============================================================
$ErrorActionPreference = 'Stop'
# סגירת כל מופע קודם של הווידג'ט (תיקייה / נייד / מותקן)
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessId -ne $PID -and ($_.CommandLine -like '*CountdownWidget*' -or $_.CommandLine -like '*PAYLOAD64*') } |
    ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch { } }
Start-Sleep -Milliseconds 400

$dest = Join-Path $env:LOCALAPPDATA 'BabyCountdownWidget'
$assetDir = Join-Path $dest 'assets'
foreach ($d in @($dest, $assetDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# --- הציורים ---
foreach ($k in @($EmbeddedAssets.Keys)) {
    $p = Join-Path $assetDir $k
    $bytes = [Convert]::FromBase64String($EmbeddedAssets[$k])
    if (-not (Test-Path $p) -or (Get-Item $p).Length -ne $bytes.Length) {
        [System.IO.File]::WriteAllBytes($p, $bytes)
    }
}

foreach ($f in @(Get-ChildItem $assetDir -Filter *.png -ErrorAction SilentlyContinue)) {
    if (-not $EmbeddedAssets.ContainsKey($f.Name)) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue }
}

# --- קוד הווידג'ט ---
$ps1 = Join-Path $dest 'CountdownWidget.ps1'
$code = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($WidgetB64))
[System.IO.File]::WriteAllText($ps1, $code, (New-Object System.Text.UTF8Encoding $true))

# --- העברת הגדרות קיימות אם יש ---
$cfg = Join-Path $dest 'config.json'
if (-not (Test-Path $cfg)) {
    $candidates = @(
        (Join-Path $env:APPDATA 'BabyCountdownWidget\config.json'),
        (Join-Path (Split-Path -Parent $InstallerPath) 'config.json')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { Copy-Item $c $cfg -Force; break }
    }
}

# --- קובץ הפעלה חבוי + הפעלה אוטומטית עם Windows ---
$q = [string][char]34
$launchVbs = Join-Path $dest 'Launch.vbs'
$line = 'CreateObject(' + $q + 'WScript.Shell' + $q + ').Run ' + $q +
        'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ' +
        ($q*2) + $ps1 + ($q*2) + $q + ', 0, False'
[System.IO.File]::WriteAllText($launchVbs, $line, [System.Text.Encoding]::ASCII)

$startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'CountdownWidget.vbs'
[System.IO.File]::WriteAllText($startup, $line, [System.Text.Encoding]::ASCII)

# --- קיצור דרך על שולחן העבודה ---
try {
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'ווידגט ספירה לאחור.lnk'))
    $lnk.TargetPath = 'wscript.exe'
    $lnk.Arguments  = $q + $launchVbs + $q
    $lnk.WorkingDirectory = $dest
    $lnk.IconLocation = 'shell32.dll,43'
    $lnk.Description = 'ווידגט ספירה לאחור לרגעים מרגשים'
    $lnk.Save()
} catch { }

# --- סגירת מופע קודם והפעלה ---
Start-Sleep -Milliseconds 400
Start-Process wscript.exe -ArgumentList ($q + $launchVbs + $q) -WindowStyle Hidden

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show(
    "הווידג'ט הותקן ופועל." + [Environment]::NewLine + [Environment]::NewLine +
    "מיקום: $dest" + [Environment]::NewLine +
    "הוא ייפתח אוטומטית בכל הפעלה של המחשב," + [Environment]::NewLine +
    "ולא מופיע בשורת המשימות.",
    "ספירה לאחור לרגעים מרגשים", 'OK', 'Information') | Out-Null
