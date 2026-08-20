# ==========================================================
#  אורז את יוצר המתנה לקובץ VBS יחיד ונייד (GiftMaker.vbs)
#  שמכיל בתוכו גם את הממשק וגם את קובץ ההתקנה המלא.
#  הרץ פעם אחת אחרי כל שינוי ב-Make-Gift.ps1 / בקובץ ההתקנה.
# ==========================================================
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$makeGift  = Join-Path $dir 'Make-Gift.ps1'
$installer = Join-Path $dir 'Install-CountdownWidget.vbs'
$outVbs    = Join-Path $dir 'GiftMaker.vbs'

foreach ($p in @($makeGift, $installer)) {
    if (-not (Test-Path $p)) { throw "לא נמצא: $p" }
}

# --- הטמעת קובץ ההתקנה המלא כ-base64 ---
$masterBytes = [System.IO.File]::ReadAllBytes($installer)
$masterB64   = [Convert]::ToBase64String($masterBytes)

# --- גוף יוצר המתנה + השמת התבנית המוטמעת מראש ---
$giftBody = [System.IO.File]::ReadAllText($makeGift, [System.Text.Encoding]::UTF8)
$boot = "`$script:MasterText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$masterB64'))`r`n" + $giftBody

# --- קידוד ה-bootstrapper ל-base64 עם גלישת שורות וגרש מוביל ---
$bootB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($boot))
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bootB64.Length; $i += 76) {
    $len = [Math]::Min(76, $bootB64.Length - $i)
    [void]$sb.Append("'").Append($bootB64.Substring($i, $len)).Append("`r`n")
}

# --- מעטפת VBScript (ASCII בלבד) שקוראת את עצמה, מפענחת ומריצה ---
$stub = @"
' GiftMaker - single-file portable gift creator (self-contained). Double-click to run.
Set sh = CreateObject("WScript.Shell")
me_ = WScript.ScriptFullName
q = Chr(34)
cmd = "powershell -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -Command " & q & _
  "`$p='" & me_ & "'; `$t=[IO.File]::ReadAllText(`$p); `$i=`$t.LastIndexOf('#PS64#')+6; `$b=(`$t.Substring(`$i) -replace ('(?m)^'+[char]39), ''); `$s=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$b)); Invoke-Expression `$s" & q
sh.Run cmd, 0, False
WScript.Quit
'#PS64#
"@

$out = $stub + $sb.ToString()

# כתיבה כ-ASCII (המעטפת וה-base64 כולם ASCII) - כדי ש-wscript יפרש נכון
[System.IO.File]::WriteAllText($outVbs, $out, (New-Object System.Text.ASCIIEncoding))

$sz = [Math]::Round((Get-Item $outVbs).Length / 1MB, 2)
Write-Host "נוצר: $outVbs ($sz MB)"
