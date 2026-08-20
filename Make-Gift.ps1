# ==========================================================
#  יוצר מתנה - Countdown Gift Maker
#  ממשק גרפי ליצירת קובץ התקנה מותאם אישית (VBS יחיד)
#  שמזריק אירוע (למשל חתונה) לתוך קובץ ההתקנה ומוכן לשליחה.
# ==========================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[System.Threading.Thread]::CurrentThread.CurrentUICulture = 'he-IL'
$ErrorActionPreference = 'Stop'

# $script:MasterText may be pre-set by an embedding bootstrapper (single-file build).
if (-not (Test-Path variable:script:MasterText)) { $script:MasterText = $null }
if ([string]::IsNullOrWhiteSpace($script:MasterText)) {
    # מצב רגיל: קוראים את קובץ ההתקנה מהתיקייה שליד הסקריפט
    try { $script:Root = Split-Path -Parent $MyInvocation.MyCommand.Definition } catch { $script:Root = $null }
    if ([string]::IsNullOrEmpty($script:Root) -or -not (Test-Path -LiteralPath $script:Root -ErrorAction SilentlyContinue)) {
        $script:Root = (Get-Location).Path
    }
    $script:Master = Join-Path $script:Root 'Install-CountdownWidget.vbs'
} else {
    # מצב נייד: קובץ ההתקנה מוטמע בקובץ עצמו
    $script:Root = $null
    $script:Master = $null
}

function Get-MasterText {
    if (-not [string]::IsNullOrWhiteSpace($script:MasterText)) { return $script:MasterText }
    if (Test-Path $script:Master) { return [System.IO.File]::ReadAllText($script:Master, [System.Text.Encoding]::UTF8) }
    throw "לא נמצא קובץ ההתקנה Install-CountdownWidget.vbs בתיקייה:`n$script:Root"
}

$script:ThemeKeys  = @('girl','boy','neutral','purple','sun')
$script:ThemeNames = @('בת - ורוד','בן - תכלת','ניטרלי - מנטה','לילך','שמש - צהוב')
$script:ArtKeys    = @('baby','birthday','wedding','trip','star')
$script:ArtNames   = @('תינוק / לידה','יום הולדת','חתונה','טיסה / חופשה','אירוע כללי')

# ---------- ליבה: הזרקת קונפיג לתוך קובץ ההתקנה ----------
function Build-GiftInstaller {
    param(
        [string]$MasterText,
        [string]$ConfigJson,
        [string]$OutPath
    )

    if ([string]::IsNullOrWhiteSpace($MasterText)) {
        throw 'תוכן קובץ ההתקנה ריק.'
    }

    $text = $MasterText

    # המרקר האמיתי הוא ההופעה האחרונה של #PAYLOAD64#
    $marker = '#PAYLOAD64#'
    $mi = $text.LastIndexOf($marker)
    if ($mi -lt 0) { throw 'קובץ ההתקנה אינו בפורמט המצופה (חסר PAYLOAD64).' }

    $header  = $text.Substring(0, $mi + $marker.Length)
    $b64part = $text.Substring($mi + $marker.Length)

    # שחזור ה-base64 של ה-payload: הסרת גרש מוביל מכל שורה
    $b64 = ($b64part -replace "(?m)^'", '')
    $b64 = ($b64 -replace '\s', '')
    if ([string]::IsNullOrWhiteSpace($b64)) { throw 'לא נמצא תוכן payload בקובץ ההתקנה.' }

    $payloadBytes = [Convert]::FromBase64String($b64)
    $payload = [System.Text.Encoding]::UTF8.GetString($payloadBytes)

    # הסרת הזרקה קודמת אם קיימת (כדי שאפשר לעבוד גם על קובץ שכבר נוצר)
    $payload = [System.Text.RegularExpressions.Regex]::Replace(
        $payload, '(?s)\r?\n?# >>> GIFT.*?# <<< GIFT\r?\n?', "`r`n")

    # בניית בלוק ההזרקה
    $cfgB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ConfigJson))
    $inject = @"
# >>> GIFT
try {
    `$giftB64 = '$cfgB64'
    `$giftJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$giftB64))
    `$gift = `$giftJson | ConvertFrom-Json
    `$giftEv = @(`$gift.events)[0]
    `$giftEnc = New-Object System.Text.UTF8Encoding `$true
    if (Test-Path `$cfg) {
        # מיזוג לא-הרסני: הוספת אירוע המתנה לאירועים הקיימים ללא כפילות
        `$existing = Get-Content `$cfg -Raw -Encoding UTF8 | ConvertFrom-Json
        `$events = @()
        if (`$existing.PSObject.Properties['events'] -and `$existing.events) { `$events = @(`$existing.events) }
        `$dup = `$false
        foreach (`$e in `$events) { if (`$e.name -eq `$giftEv.name -and `$e.date -eq `$giftEv.date) { `$dup = `$true } }
        if (-not `$dup) { `$events = `$events + `$giftEv }
        if (`$existing.PSObject.Properties['events']) { `$existing.events = `$events }
        else { `$existing | Add-Member -NotePropertyName events -NotePropertyValue `$events -Force }
        [System.IO.File]::WriteAllText(`$cfg, (`$existing | ConvertTo-Json -Depth 6), `$giftEnc)
    } else {
        [System.IO.File]::WriteAllText(`$cfg, `$giftJson, `$giftEnc)
    }
} catch {
    try { [System.IO.File]::WriteAllText(`$cfg, `$giftJson, (New-Object System.Text.UTF8Encoding `$true)) } catch { }
}
# <<< GIFT
"@

    # עוגן: לפני יצירת קובץ ההפעלה החבוי. אם לא נמצא - בסוף ה-payload.
    $anchor = "# --- קובץ הפעלה חבוי"
    $ai = $payload.IndexOf($anchor)
    if ($ai -ge 0) {
        $payload = $payload.Substring(0, $ai) + $inject + "`r`n`r`n" + $payload.Substring($ai)
    } else {
        $payload = $payload.TrimEnd() + "`r`n`r`n" + $inject + "`r`n"
    }

    # קידוד מחדש ל-base64, גלישה לשורות עם גרש מוביל
    $newB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload))
    $sb = New-Object System.Text.StringBuilder
    for ($p = 0; $p -lt $newB64.Length; $p += 76) {
        $len = [Math]::Min(76, $newB64.Length - $p)
        [void]$sb.Append("'").Append($newB64.Substring($p, $len)).Append("`r`n")
    }

    $out = $header + "`r`n" + $sb.ToString()
    $enc = New-Object System.Text.UTF8Encoding($false)   # ללא BOM
    [System.IO.File]::WriteAllText($OutPath, $out, $enc)
}

function New-GiftConfig {
    param($Name, [datetime]$When, $Theme, $Art, $Note)
    $cfg = [ordered]@{
        settings = [ordered]@{
            showSeconds = $true
            scale       = 1.0
            opacity     = 1.0
            frameAlpha  = 0.92
            autoStart   = $true
            stayVisible = $true
            alwaysOnTop = $false
            left        = 120.0
            top         = 120.0
        }
        events = @(
            [ordered]@{
                name  = [string]$Name
                date  = $When.ToString('yyyy-MM-ddTHH:mm:ss')
                theme = [string]$Theme
                art   = [string]$Art
                note  = [string]$Note
            }
        )
    }
    return ($cfg | ConvertTo-Json -Depth 6)
}

# ---------------------- ממשק גרפי ----------------------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="יוצר מתנה - ספירה לאחור" Height="540" Width="440"
        WindowStartupLocation="CenterScreen" FlowDirection="RightToLeft"
        FontFamily="Segoe UI" FontSize="13" ResizeMode="CanMinimize"
        Background="#FFF7FA">
  <Grid Margin="18">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <TextBlock Grid.Row="0" Text="יצירת קובץ מתנה לשליחה" FontSize="18"
               FontWeight="Bold" Foreground="#B23A6B" Margin="0,0,0,14"/>

    <TextBlock Grid.Row="1" Text="שם האירוע"/>
    <TextBox   Grid.Row="2" x:Name="txtName" Margin="0,3,0,10"
               Text="החתונה של דנה ויוסי"/>

    <Grid Grid.Row="3" Margin="0,0,0,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="12"/>
        <ColumnDefinition Width="120"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="תאריך"/>
        <DatePicker x:Name="dpDate" Margin="0,3,0,0"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="שעה (HH:mm)"/>
        <TextBox x:Name="txtTime" Margin="0,3,0,0" Text="19:00"/>
      </StackPanel>
    </Grid>

    <Grid Grid.Row="4" Margin="0,0,0,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="12"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="ערכת צבע"/>
        <ComboBox x:Name="cmbTheme" Margin="0,3,0,0"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="סוג אירוע (איור)"/>
        <ComboBox x:Name="cmbArt" Margin="0,3,0,0"/>
      </StackPanel>
    </Grid>

    <TextBlock Grid.Row="5" Text="הערה (רשות)"/>
    <TextBox   Grid.Row="6" x:Name="txtNote" Margin="0,3,0,10" Text="מזל טוב!"/>

    <TextBlock Grid.Row="7" Text="שמירת הקובץ בשם:"/>
    <Grid Grid.Row="8" Margin="0,3,0,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="8"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <TextBox Grid.Column="0" x:Name="txtOut"/>
      <Button  Grid.Column="2" x:Name="btnBrowse" Content="עיון..." Padding="10,3"/>
    </Grid>

    <TextBlock Grid.Row="9" x:Name="txtStatus" TextWrapping="Wrap"
               Foreground="#556" VerticalAlignment="Top" Margin="0,4,0,4"
               MinHeight="34"/>

    <Button Grid.Row="10" x:Name="btnCreate" Content="צור קובץ מתנה"
            Height="40" FontSize="15" FontWeight="Bold"
            Background="#F6A9C4" Foreground="#5B2740" BorderThickness="0"
            Cursor="Hand" Margin="0,4,0,0"/>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)

$txtName   = $win.FindName('txtName')
$dpDate    = $win.FindName('dpDate')
$txtTime   = $win.FindName('txtTime')
$cmbTheme  = $win.FindName('cmbTheme')
$cmbArt    = $win.FindName('cmbArt')
$txtNote   = $win.FindName('txtNote')
$txtOut    = $win.FindName('txtOut')
$btnBrowse = $win.FindName('btnBrowse')
$txtStatus = $win.FindName('txtStatus')
$btnCreate = $win.FindName('btnCreate')

foreach ($n in $script:ThemeNames) { [void]$cmbTheme.Items.Add($n) }
foreach ($n in $script:ArtNames)   { [void]$cmbArt.Items.Add($n) }
$cmbArt.SelectedIndex   = 2   # חתונה
$cmbTheme.SelectedIndex = 3   # לילך
$dpDate.SelectedDate    = (Get-Date).AddMonths(2).Date

$desktop = [Environment]::GetFolderPath('Desktop')
$txtOut.Text = Join-Path $desktop 'Install-Countdown-Gift.vbs'

if ([string]::IsNullOrWhiteSpace($script:MasterText) -and -not (Test-Path $script:Master)) {
    $txtStatus.Foreground = 'Red'
    $txtStatus.Text = "אזהרה: לא נמצא Install-CountdownWidget.vbs בתיקייה זו. יש להריץ את הכלי מתוך תיקיית BabyCountdown."
}

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = 'קובץ התקנה (*.vbs)|*.vbs'
    $dlg.FileName = [System.IO.Path]::GetFileName($txtOut.Text)
    try { $dlg.InitialDirectory = [System.IO.Path]::GetDirectoryName($txtOut.Text) } catch {}
    if ($dlg.ShowDialog() -eq 'OK') { $txtOut.Text = $dlg.FileName }
})

$btnCreate.Add_Click({
    try {
        $name = $txtName.Text.Trim()
        if (-not $name) { throw 'יש להזין שם לאירוע.' }
        if (-not $dpDate.SelectedDate) { throw 'יש לבחור תאריך.' }

        $tm = [datetime]::MinValue
        if (-not [datetime]::TryParseExact($txtTime.Text.Trim(), 'HH:mm',
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::None, [ref]$tm)) {
            throw 'שעה לא תקינה. יש להזין בפורמט HH:mm (למשל 19:00).'
        }
        $when = ([datetime]$dpDate.SelectedDate).Date.Add($tm.TimeOfDay)

        $theme = $script:ThemeKeys[[Math]::Max(0,$cmbTheme.SelectedIndex)]
        $art   = $script:ArtKeys[[Math]::Max(0,$cmbArt.SelectedIndex)]
        $note  = $txtNote.Text.Trim()
        $out   = $txtOut.Text.Trim()
        if (-not $out) { throw 'יש לבחור מיקום לשמירת הקובץ.' }
        if (-not $out.ToLower().EndsWith('.vbs')) { $out += '.vbs' }

        $json = New-GiftConfig -Name $name -When $when -Theme $theme -Art $art -Note $note
        Build-GiftInstaller -MasterText (Get-MasterText) -ConfigJson $json -OutPath $out

        $txtStatus.Foreground = 'Green'
        $txtStatus.Text = "נוצר בהצלחה! שלח/י את הקובץ לחבר - לחיצה כפולה תתקין את הווידג'ט עם התאריך שהוגדר."

        $r = [System.Windows.Forms.MessageBox]::Show(
            "הקובץ נוצר:`n$out`n`nלפתוח את התיקייה?",
            'הצלחה', 'YesNo', 'Information')
        if ($r -eq 'Yes') { Start-Process explorer.exe "/select,`"$out`"" }
    } catch {
        $txtStatus.Foreground = 'Red'
        $txtStatus.Text = "שגיאה: $($_.Exception.Message)"
    }
})

[void]$win.ShowDialog()
