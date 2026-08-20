# ==========================================================
#  ווידג'ט ספירה לאחור לרגעים מרגשים  -  גרסה 1.0
#  ווידג'ט צף לשולחן העבודה (WPF / PowerShell) - ללא התקנות
# ==========================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

[System.Threading.Thread]::CurrentThread.CurrentUICulture = 'he-IL'
$ErrorActionPreference = 'Stop'

$script:Root       = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:ConfigPath = Join-Path $script:Root 'config.json'
$script:PortableFile = $null

# ---------------------- ערכות צבע ----------------------
$script:Themes = @{
    'girl'    = @{ Name='בת - ורוד'     ; Accent='#F6A9C4'; Accent2='#E888AB'; Soft='#FBD7E4'; Foot='#FBE6EF'; FootText='#7C3D57'; Heart='#F0728C'; Skin='#F8D6BE'; Hair='#C58B5C' }
    'boy'     = @{ Name='בן - תכלת'     ; Accent='#8CC6EF'; Accent2='#63A9DE'; Soft='#CFE6F8'; Foot='#DFE8ED'; FootText='#2E5573'; Heart='#F0728C'; Skin='#F8D6BE'; Hair='#A6764B' }
    'neutral' = @{ Name='ניטרלי - מנטה' ; Accent='#8FCFB4'; Accent2='#6BB396'; Soft='#D3EDE0'; Foot='#E3F3EC'; FootText='#2F6B54'; Heart='#F0728C'; Skin='#F8D6BE'; Hair='#A6764B' }
    'purple'  = @{ Name='לילך'          ; Accent='#BBA7E4'; Accent2='#9D86D1'; Soft='#E2D9F6'; Foot='#EDE7FA'; FootText='#4A3A75'; Heart='#F0728C'; Skin='#F8D6BE'; Hair='#A6764B' }
    'sun'     = @{ Name='שמש - צהוב'    ; Accent='#F8CD79'; Accent2='#E9B551'; Soft='#FCE9C4'; Foot='#FDF1DA'; FootText='#8A6320'; Heart='#F0728C'; Skin='#F8D6BE'; Hair='#A6764B' }
}
$script:ArtNames = [ordered]@{
    'baby'     = 'תינוק / לידה'
    'birthday' = 'יום הולדת'
    'wedding'  = 'חתונה'
    'trip'     = 'טיסה / חופשה'
    'star'     = 'אירוע כללי'
}

# ---------------------- הגדרות ----------------------
function New-DefaultConfig {
    $d = (Get-Date).Date.AddDays(145).AddHours(10)
    [pscustomobject]@{
        settings = [pscustomobject]@{
            alwaysOnTop = $true
            showSeconds = $true
            scale       = 1.0
            opacity     = 1.0
            frameAlpha  = 0.92
            autoStart   = $true
            stayVisible = $true
            diagLog     = $true
            left        = 120.0
            top         = 120.0
        }
        events = @(
            [pscustomobject]@{
                name  = 'לידת התינוק'
                date  = $d.ToString('yyyy-MM-ddTHH:mm:ss')
                theme = 'girl'
                art   = 'baby'
                note  = 'תאריך משוער'
            }
        )
    }
}

function Load-Config {
    if (Test-Path $script:ConfigPath) {
        try {
            $c = Get-Content -Path $script:ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not $c.settings) { $c | Add-Member settings (New-DefaultConfig).settings -Force }
            if (-not $c.events)   { $c | Add-Member events @() -Force }
            if ($null -eq $c.settings.frameAlpha) { $c.settings | Add-Member frameAlpha 0.92 -Force }
            if ($null -eq $c.settings.autoStart)  { $c.settings | Add-Member autoStart $true -Force }
            if ($null -eq $c.settings.stayVisible) { $c.settings | Add-Member stayVisible $true -Force }
            if ($null -eq $c.settings.diagLog)     { $c.settings | Add-Member diagLog $true -Force }
            $c.events = @($c.events)
            return $c
        } catch { }
    }
    $c = New-DefaultConfig
    Save-Config $c
    return $c
}

function Save-Config($cfg) {
    $json = $cfg | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($script:ConfigPath, $json, (New-Object System.Text.UTF8Encoding $true))
}

function Get-Theme($key) {
    if ($key -and $script:Themes.ContainsKey($key)) { return $script:Themes[$key] }
    return $script:Themes['girl']
}

# ==========================================================
#  ציורים (וקטור - XAML) לפי סוג האירוע
# ==========================================================
# ---- ציורים מקוריים (נחתכו מתמונת המקור) ----
$script:AssetSizes = @{ 'main' = @(130,122); 'small' = @(53,52); 'foot' = @(30,28) }

function Get-AssetArt([string]$slot, [string]$art, [string]$themeKey) {
    if (-not $art)      { $art = 'baby' }
    if (-not $themeKey) { $themeKey = 'girl' }
    $names = @(('{0}_{1}_{2}.png' -f $slot, $art, $themeKey), ('{0}_{1}.png' -f $slot, $art))
    foreach ($n in $names) {
        $file = Join-Path (Join-Path $script:Root 'assets') $n
        if (Test-Path $file) {
            $sz  = $script:AssetSizes[$slot]
            $uri = 'file:///' + ($file.Replace([char]92, [char]47))
            $tpl = '<Image Width="{1}" Height="{2}" Stretch="Fill" SnapsToDevicePixels="True" RenderOptions.BitmapScalingMode="HighQuality">' +
                   '<Image.Source><BitmapImage UriSource="{0}" CacheOption="OnLoad"/></Image.Source></Image>'
            return ($tpl -f $uri, $sz[0], $sz[1])
        }
    }
    return $null
}

function Get-ArtMain($art) {
    switch ($art) {
        'birthday' { @'
<Canvas Width="130" Height="92" FlowDirection="LeftToRight">
  <Path Data="M8,14 L10,20 L16,22 L10,24 L8,30 L6,24 L0,22 L6,20 Z" Fill="{{ACCENT}}" Opacity="0.55"/>
  <Path Data="M116,8 L118,14 L124,16 L118,18 L116,24 L114,18 L108,16 L114,14 Z" Fill="{{ACCENT}}" Opacity="0.4"/>
  <Ellipse Canvas.Left="34" Canvas.Top="10" Width="8" Height="8" Fill="{{ACCENT}}" Opacity="0.35"/>
  <Ellipse Canvas.Left="92" Canvas.Top="30" Width="6" Height="6" Fill="{{ACCENT}}" Opacity="0.35"/>
  <Line X1="46" Y1="26" X2="46" Y2="40" Stroke="{{ACCENT}}" StrokeThickness="3"/>
  <Line X1="65" Y1="22" X2="65" Y2="40" Stroke="{{ACCENT}}" StrokeThickness="3"/>
  <Line X1="84" Y1="26" X2="84" Y2="40" Stroke="{{ACCENT}}" StrokeThickness="3"/>
  <Path Data="M46,26 C41,19 51,17 46,10 C55,16 51,22 46,26 Z" Fill="#FFB300"/>
  <Path Data="M65,22 C60,15 70,13 65,6 C74,12 70,18 65,22 Z" Fill="#FF8F00"/>
  <Path Data="M84,26 C79,19 89,17 84,10 C93,16 89,22 84,26 Z" Fill="#FFB300"/>
  <Rectangle Canvas.Left="28" Canvas.Top="38" Width="74" Height="20" RadiusX="6" RadiusY="6" Fill="{{SOFT}}"/>
  <Rectangle Canvas.Left="22" Canvas.Top="56" Width="86" Height="22" RadiusX="7" RadiusY="7" Fill="{{ACCENT}}"/>
  <Path Data="M22,60 q10,9 21,0 q10,9 21,0 q10,9 21,0 q10,9 21,0" Stroke="#FFFFFF" StrokeThickness="3" Fill="Transparent" Opacity="0.7"/>
  <Rectangle Canvas.Left="14" Canvas.Top="76" Width="102" Height="7" RadiusX="3.5" RadiusY="3.5" Fill="#FFFFFF" Stroke="{{SOFT}}" StrokeThickness="1"/>
</Canvas>
'@ }
        'wedding' { @'
<Canvas Width="130" Height="92" FlowDirection="LeftToRight">
  <Path Data="M10,16 L12,22 L18,24 L12,26 L10,32 L8,26 L2,24 L8,22 Z" Fill="{{ACCENT}}" Opacity="0.5"/>
  <Path Data="M118,54 L120,60 L126,62 L120,64 L118,70 L116,64 L110,62 L116,60 Z" Fill="{{ACCENT}}" Opacity="0.45"/>
  <Ellipse Canvas.Left="24" Canvas.Top="32" Width="50" Height="50" Stroke="#E6B85C" StrokeThickness="7" Fill="Transparent"/>
  <Ellipse Canvas.Left="58" Canvas.Top="32" Width="50" Height="50" Stroke="#F2CE86" StrokeThickness="7" Fill="Transparent"/>
  <Path Data="M66,10 C66,4 56,2 53,9 C50,2 40,4 40,10 C40,20 53,28 53,28 C53,28 66,20 66,10 Z" Fill="{{ACCENT}}"/>
  <Path Data="M96,14 C96,10 89,9 87,13 C85,9 78,10 78,14 C78,21 87,26 87,26 C87,26 96,21 96,14 Z" Fill="{{ACCENT}}" Opacity="0.55"/>
</Canvas>
'@ }
        'trip' { @'
<Canvas Width="130" Height="92" FlowDirection="LeftToRight">
  <Ellipse Canvas.Left="94" Canvas.Top="6" Width="28" Height="28" Fill="#FFCC66"/>
  <Path Data="M6,36 C10,28 22,28 26,34 C34,24 52,28 54,38 L4,38 Z" Fill="#FFFFFF" Opacity="0.9"/>
  <Path Data="M12,22 L46,14 L44,24 L60,22 L34,36 L30,28 L14,30 Z" Fill="{{ACCENT}}" Opacity="0.75"/>
  <Path Data="M52,54 L52,46 A10,8 0 0 1 78,46 L78,54" Stroke="{{ACCENT}}" StrokeThickness="5" Fill="Transparent"/>
  <Rectangle Canvas.Left="34" Canvas.Top="50" Width="62" Height="40" RadiusX="8" RadiusY="8" Fill="{{ACCENT}}"/>
  <Rectangle Canvas.Left="42" Canvas.Top="50" Width="10" Height="40" Fill="#FFFFFF" Opacity="0.55"/>
  <Rectangle Canvas.Left="78" Canvas.Top="50" Width="10" Height="40" Fill="#FFFFFF" Opacity="0.55"/>
  <Rectangle Canvas.Left="56" Canvas.Top="64" Width="18" Height="10" RadiusX="3" RadiusY="3" Fill="{{SOFT}}"/>
</Canvas>
'@ }
        'star' { @'
<Canvas Width="130" Height="92" FlowDirection="LeftToRight">
  <Path Data="M65,12 L77,46 L112,46 L84,64 L94,90 L65,74 L36,90 L46,64 L18,46 L53,46 Z" Fill="{{ACCENT}}"/>
  <Path Data="M65,24 L73,48 L96,48 L77,60 L83,80 L65,70 L47,80 L53,60 L34,48 L57,48 Z" Fill="#FFFFFF" Opacity="0.3"/>
  <Path Data="M14,10 L16,17 L23,19 L16,21 L14,28 L12,21 L5,19 L12,17 Z" Fill="{{ACCENT}}" Opacity="0.5"/>
  <Path Data="M118,58 L120,64 L126,66 L120,68 L118,74 L116,68 L110,66 L116,64 Z" Fill="{{ACCENT}}" Opacity="0.5"/>
</Canvas>
'@ }
        default { @'
<Canvas Width="150" Height="108" FlowDirection="LeftToRight">
  <TextBlock Canvas.Left="10" Canvas.Top="34" Text="z" FontFamily="Segoe UI" FontStyle="Italic" FontWeight="Bold" FontSize="11" Foreground="#AFC0CE"/>
  <TextBlock Canvas.Left="19" Canvas.Top="20" Text="z" FontFamily="Segoe UI" FontStyle="Italic" FontWeight="Bold" FontSize="14" Foreground="#9AAFC1"/>
  <TextBlock Canvas.Left="32" Canvas.Top="3" Text="z" FontFamily="Segoe UI" FontStyle="Italic" FontWeight="Bold" FontSize="18" Foreground="#8299AF"/>
  <Path Data="M7,58 L9,65 L16,67 L9,69 L7,76 L5,69 L-2,67 L5,65 Z" Fill="#F7C948"/>
  <Path Data="M142,28 L144,35 L151,37 L144,39 L142,46 L140,39 L133,37 L140,35 Z" Fill="#F7C948" Opacity="0.9"/>
  <Path Data="M132,88 L133,92 L137,93 L133,94 L132,98 L131,94 L127,93 L131,92 Z" Fill="#F7C948" Opacity="0.8"/>
  <Path Data="M120,16 L121,20 L125,21 L121,22 L120,26 L119,22 L115,21 L119,20 Z" Fill="#F7C948" Opacity="0.6"/>
  <Path Data="M128,12 C128,6 120,4 117,10 C114,4 106,6 106,12 C106,21 117,28 117,28 C117,28 128,21 128,12 Z" Fill="{{HEART}}"/>
  <Path Data="M124,10 C122,8 119,8 118,11" Stroke="#FFFFFF" StrokeThickness="2" Fill="Transparent" Opacity="0.55" StrokeStartLineCap="Round"/>
  <Ellipse Canvas.Left="18" Canvas.Top="92" Width="116" Height="14" Fill="#000000" Opacity="0.06"/>
  <Ellipse Canvas.Left="8"  Canvas.Top="64" Width="66" Height="38" Fill="#E9EFF6"/>
  <Ellipse Canvas.Left="42" Canvas.Top="54" Width="62" Height="48" Fill="#E9EFF6"/>
  <Ellipse Canvas.Left="86" Canvas.Top="64" Width="56" Height="38" Fill="#E9EFF6"/>
  <Rectangle Canvas.Left="18" Canvas.Top="82" Width="114" Height="20" RadiusX="10" RadiusY="10" Fill="#E9EFF6"/>
  <Ellipse Canvas.Left="8"  Canvas.Top="60" Width="66" Height="36" Fill="#FFFFFF"/>
  <Ellipse Canvas.Left="42" Canvas.Top="50" Width="62" Height="46" Fill="#FFFFFF"/>
  <Ellipse Canvas.Left="86" Canvas.Top="60" Width="56" Height="36" Fill="#FFFFFF"/>
  <Rectangle Canvas.Left="18" Canvas.Top="78" Width="114" Height="20" RadiusX="10" RadiusY="10" Fill="#FFFFFF"/>
  <Path Data="M74,64 C72,51 85,43 99,45 L113,48 C126,51 128,66 119,72 C109,79 84,78 76,72 C73,70 74,67 74,64 Z" Fill="{{SOFT}}"/>
  <Path Data="M78,68 C88,74 110,74 119,68 C110,76 86,76 78,68 Z" Fill="#000000" Opacity="0.07"/>
  <Path Data="M82,50 C92,45 106,46 116,52" Stroke="#FFFFFF" StrokeThickness="3.5" Fill="Transparent" Opacity="0.9" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Path Data="M96,58 C104,55 112,56 118,60" Stroke="#FFFFFF" StrokeThickness="2" Fill="Transparent" Opacity="0.45" StrokeStartLineCap="Round"/>
  <Ellipse Canvas.Left="112" Canvas.Top="60" Width="15" Height="12" Fill="{{SKIN}}"/>
  <Ellipse Canvas.Left="39" Canvas.Top="57" Width="10" Height="13" Fill="{{SKIN}}"/>
  <Ellipse Canvas.Left="41" Canvas.Top="60" Width="5" Height="7" Fill="#E9A78C" Opacity="0.5"/>
  <Ellipse Canvas.Left="43" Canvas.Top="41" Width="44" Height="42" Fill="{{SKIN}}"/>
  <Ellipse Canvas.Left="49" Canvas.Top="45" Width="26" Height="18" Fill="#FFFFFF" Opacity="0.22"/>
  <Path Data="M50,45 C55,34 76,33 82,44 C73,39 59,39 50,45 Z" Fill="{{HAIR}}" Opacity="0.8"/>
  <Path Data="M64,37 C63,27 77,26 73,35" Stroke="{{HAIR}}" StrokeThickness="3.6" Fill="Transparent" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Path Data="M75,35 C79,31 84,33 83,37" Stroke="{{HAIR}}" StrokeThickness="2.6" Fill="Transparent" Opacity="0.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Path Data="M51,60 A7,6 0 0 0 65,60" Stroke="#6B4A38" StrokeThickness="2.4" Fill="Transparent" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Path Data="M69,60 A7,6 0 0 0 83,60" Stroke="#6B4A38" StrokeThickness="2.4" Fill="Transparent" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Ellipse Canvas.Left="48" Canvas.Top="65" Width="12" Height="8" Fill="#F79AAF" Opacity="0.6"/>
  <Ellipse Canvas.Left="73" Canvas.Top="65" Width="12" Height="8" Fill="#F79AAF" Opacity="0.6"/>
  <Path Data="M61,71 A5,4.5 0 0 0 72,71" Stroke="#D4736A" StrokeThickness="2" Fill="Transparent" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
</Canvas>
'@ }
    }
}

function Get-ArtSmall($art) {
    switch ($art) {
        'birthday' { @'
<Canvas Width="56" Height="56" FlowDirection="LeftToRight">
  <Rectangle Canvas.Left="8" Canvas.Top="24" Width="40" Height="26" RadiusX="3" RadiusY="3" Fill="{{ACCENT}}"/>
  <Rectangle Canvas.Left="5" Canvas.Top="17" Width="46" Height="10" RadiusX="3" RadiusY="3" Fill="{{SOFT}}"/>
  <Rectangle Canvas.Left="24" Canvas.Top="17" Width="8" Height="33" Fill="#FFFFFF" Opacity="0.85"/>
  <Path Data="M28,17 C22,17 16,13 18,8 C21,4 27,9 28,17 Z" Fill="{{ACCENT}}"/>
  <Path Data="M28,17 C34,17 40,13 38,8 C35,4 29,9 28,17 Z" Fill="{{ACCENT}}"/>
</Canvas>
'@ }
        'wedding' { @'
<Canvas Width="56" Height="56" FlowDirection="LeftToRight">
  <Path Data="M28,50 C28,50 6,36 6,22 C6,13 18,9 28,20 C38,9 50,13 50,22 C50,36 28,50 28,50 Z" Fill="{{ACCENT}}"/>
  <Path Data="M20,20 C16,20 14,24 15,27" Stroke="#FFFFFF" StrokeThickness="3" Fill="Transparent" Opacity="0.7" StrokeStartLineCap="Round"/>
</Canvas>
'@ }
        'trip' { @'
<Canvas Width="56" Height="56" FlowDirection="LeftToRight">
  <Path Data="M4,34 L46,16 L42,28 L22,34 L16,46 L11,45 L13,33 Z" Fill="{{ACCENT}}"/>
  <Path Data="M6,46 L26,46" Stroke="{{SOFT}}" StrokeThickness="3" StrokeDashArray="2 2"/>
  <Ellipse Canvas.Left="44" Canvas.Top="8" Width="8" Height="8" Fill="{{SOFT}}"/>
</Canvas>
'@ }
        'star' { @'
<Canvas Width="56" Height="56" FlowDirection="LeftToRight">
  <Path Data="M38,10 A20,20 0 1 0 38,46 A15,15 0 1 1 38,10 Z" Fill="{{ACCENT}}"/>
  <Path Data="M46,20 L48,26 L54,28 L48,30 L46,36 L44,30 L38,28 L44,26 Z" Fill="{{ACCENT}}" Opacity="0.55"/>
</Canvas>
'@ }
        default { @'
<Canvas Width="66" Height="60" FlowDirection="LeftToRight">
  <Path Data="M15,11 C15,6 9,3 6,8 C3,3 -3,6 -3,11 C-3,18 6,25 6,25 C6,25 15,18 15,11 Z" Fill="{{HEART}}"/>
  <Path Data="M13,7 C12,6 10,6 10,8" Stroke="#FFFFFF" StrokeThickness="1.6" Fill="Transparent" Opacity="0.6" StrokeStartLineCap="Round"/>
  <Path Data="M27,4 C27,1 23,-1 21,2 C19,-1 15,1 15,4 C15,8 21,13 21,13 C21,13 27,8 27,4 Z" Fill="{{HEART}}" Opacity="0.65"/>
  <Ellipse Canvas.Left="49" Canvas.Top="9" Width="8" Height="8" Fill="#FFFFFF" Stroke="{{ACCENT2}}" StrokeThickness="1.2" Opacity="0.95"/>
  <Ellipse Canvas.Left="57" Canvas.Top="18" Width="5" Height="5" Fill="#FFFFFF" Stroke="{{ACCENT2}}" StrokeThickness="1.1" Opacity="0.95"/>
  <Ellipse Canvas.Left="31" Canvas.Top="11" Width="20" Height="19" Fill="{{SKIN}}"/>
  <Ellipse Canvas.Left="34" Canvas.Top="13" Width="11" Height="8" Fill="#FFFFFF" Opacity="0.22"/>
  <Path Data="M33,16 C36,9 48,9 50,16 C44,12 38,12 33,16 Z" Fill="{{HAIR}}" Opacity="0.8"/>
  <Path Data="M41,9 C41,3 48,4 46,8" Stroke="{{HAIR}}" StrokeThickness="2.4" Fill="Transparent" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
  <Path Data="M34,21 A3.5,3 0 0 0 41,21" Stroke="#6B4A38" StrokeThickness="1.7" Fill="Transparent" StrokeStartLineCap="Round"/>
  <Path Data="M43,21 A3.5,3 0 0 0 50,21" Stroke="#6B4A38" StrokeThickness="1.7" Fill="Transparent" StrokeStartLineCap="Round"/>
  <Ellipse Canvas.Left="33" Canvas.Top="23" Width="6" Height="4" Fill="#F79AAF" Opacity="0.6"/>
  <Ellipse Canvas.Left="45" Canvas.Top="23" Width="6" Height="4" Fill="#F79AAF" Opacity="0.6"/>
  <Path Data="M39,27 A3,2.5 0 0 0 45,27" Stroke="#D4736A" StrokeThickness="1.5" Fill="Transparent" StrokeStartLineCap="Round"/>
  <Ellipse Canvas.Left="22" Canvas.Top="28" Width="9" Height="8" Fill="{{SKIN}}"/>
  <Ellipse Canvas.Left="51" Canvas.Top="28" Width="9" Height="8" Fill="{{SKIN}}"/>
  <Path Data="M8,34 C8,47 18,54 32,54 C46,54 56,47 56,34 Z" Fill="{{ACCENT}}"/>
  <Path Data="M14,46 C20,52 44,52 50,46 C44,54 20,54 14,46 Z" Fill="#000000" Opacity="0.08"/>
  <Path Data="M13,38 C14,44 18,49 24,51" Stroke="#FFFFFF" StrokeThickness="2.6" Fill="Transparent" Opacity="0.5" StrokeStartLineCap="Round"/>
  <Ellipse Canvas.Left="6" Canvas.Top="28" Width="52" Height="13" Fill="{{ACCENT2}}"/>
  <Ellipse Canvas.Left="10" Canvas.Top="30" Width="44" Height="9" Fill="#FFFFFF" Opacity="0.92"/>
  <Ellipse Canvas.Left="14" Canvas.Top="27" Width="11" Height="9" Fill="#FFFFFF"/>
  <Ellipse Canvas.Left="24" Canvas.Top="25" Width="8" Height="7" Fill="#FFFFFF"/>
  <Ellipse Canvas.Left="17" Canvas.Top="29" Width="4" Height="3" Fill="#DCE8F2"/>
  <Path Data="M44,30 C44,26 49,25 51,28 L56,29 L51,32 C49,34 44,33 44,30 Z" Fill="#F9CE5A"/>
  <Ellipse Canvas.Left="45" Canvas.Top="27" Width="3" Height="3" Fill="#4A4A4A"/>
  <Rectangle Canvas.Left="13" Canvas.Top="52" Width="8" Height="6" RadiusX="2" RadiusY="2" Fill="{{ACCENT2}}"/>
  <Rectangle Canvas.Left="44" Canvas.Top="52" Width="8" Height="6" RadiusX="2" RadiusY="2" Fill="{{ACCENT2}}"/>
</Canvas>
'@ }
    }
}

# ==========================================================
#  תבנית כרטיס אירוע
# ==========================================================
$script:CardXaml = @'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        FlowDirection="RightToLeft" TextElement.FontFamily="Segoe UI"
        Background="#F9F4E8" CornerRadius="13" Margin="7,2,7,7"
        BorderBrush="#EDE4D2" BorderThickness="1" Cursor="Hand">
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Grid Grid.Row="0" Margin="15,11,15,10">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>

      <StackPanel Grid.Column="0" VerticalAlignment="Center">
        <StackPanel Orientation="Horizontal">
          <Border VerticalAlignment="Center">{{ART_SMALL}}</Border>
          <TextBlock x:Name="txtName" Text="" FontSize="23" FontWeight="Bold" Foreground="#1F2126"
                     VerticalAlignment="Center" Margin="9,0,6,0" TextTrimming="CharacterEllipsis"/>
        </StackPanel>
        <TextBlock x:Name="txtDone" Text="הרגע הגדול הגיע!  מזל טוב!" FontSize="19" FontWeight="Bold"
                   Foreground="{{ACCENT2}}" Visibility="Collapsed" Margin="4,10,0,4"/>
        <StackPanel x:Name="numRow" Orientation="Horizontal" Margin="2,8,0,0">
          <StackPanel MinWidth="52" Margin="0,0,11,0">
            <TextBlock x:Name="nDays" Text="0" FontSize="36" FontWeight="Bold" Foreground="#15171D" LineHeight="39" HorizontalAlignment="Center"/>
            <TextBlock Text="ימים" FontSize="10.5" Foreground="#8D8A83" HorizontalAlignment="Center" Margin="0,-2,0,0"/>
          </StackPanel>
          <Rectangle Width="1" Height="48" Fill="#DED6C3" Margin="0,0,11,0"/>
          <StackPanel MinWidth="46" Margin="0,0,11,0">
            <TextBlock x:Name="nHours" Text="0" FontSize="36" FontWeight="Bold" Foreground="#15171D" LineHeight="39" HorizontalAlignment="Center"/>
            <TextBlock Text="שעות" FontSize="10.5" Foreground="#8D8A83" HorizontalAlignment="Center" Margin="0,-2,0,0"/>
          </StackPanel>
          <Rectangle Width="1" Height="48" Fill="#DED6C3" Margin="0,0,11,0"/>
          <StackPanel MinWidth="46" Margin="0,0,11,0">
            <TextBlock x:Name="nMin" Text="0" FontSize="36" FontWeight="Bold" Foreground="#15171D" LineHeight="39" HorizontalAlignment="Center"/>
            <TextBlock Text="דקות" FontSize="10.5" Foreground="#8D8A83" HorizontalAlignment="Center" Margin="0,-2,0,0"/>
          </StackPanel>
          <Rectangle x:Name="secLine" Width="1" Height="48" Fill="#DED6C3" Margin="0,0,11,0"/>
          <StackPanel x:Name="secBlock" MinWidth="46">
            <TextBlock x:Name="nSec" Text="0" FontSize="36" FontWeight="Bold" Foreground="#15171D" LineHeight="39" HorizontalAlignment="Center"/>
            <TextBlock Text="שניות" FontSize="10.5" Foreground="#8D8A83" HorizontalAlignment="Center" Margin="0,-2,0,0"/>
          </StackPanel>
        </StackPanel>
      </StackPanel>

      <Border Grid.Column="1" VerticalAlignment="Center" Margin="4,0,0,0">{{ART_MAIN}}</Border>
    </Grid>

    <Border Grid.Row="1" Background="{{FOOT}}" CornerRadius="0,0,12,12" Padding="15,8,15,8">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
          <Border VerticalAlignment="Center">{{ART_RATTLE}}</Border>
          <TextBlock x:Name="txtDate" Text="" FontSize="12" Foreground="{{FOOTTEXT}}" VerticalAlignment="Center" Margin="6,0,0,0"/>
        </StackPanel>
        <Button x:Name="btnAdd" Grid.Column="1" Content="הוסף אירוע  +" FontSize="11" FontWeight="SemiBold"
                Foreground="{{FOOTTEXT}}" Padding="13,5,13,5" Cursor="Hand" BorderThickness="0" Background="Transparent">
          <Button.Template>
            <ControlTemplate TargetType="Button">
              <Border x:Name="bd" Background="#FFFFFF" CornerRadius="9" BorderBrush="{{ACCENT}}" BorderThickness="1" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter TargetName="bd" Property="Background" Value="{{SOFT}}"/>
                </Trigger>
              </ControlTemplate.Triggers>
            </ControlTemplate>
          </Button.Template>
        </Button>
      </Grid>
    </Border>
  </Grid>
</Border>
'@

# ==========================================================
#  חלון הווידג'ט
# ==========================================================
$script:WindowXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ספירה לאחור לרגעים מרגשים" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" Topmost="True" ShowInTaskbar="False"
        SizeToContent="WidthAndHeight" ResizeMode="NoResize" WindowStartupLocation="Manual"
        FontFamily="Segoe UI">
  <Grid Margin="18">
    <Border x:Name="shell" CornerRadius="19" Padding="5,5,5,3"
            BorderBrush="#B3FFFFFF" BorderThickness="1" FlowDirection="RightToLeft" Width="504">
      <Border.Background>
        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
          <GradientStop Color="#F2EDF3F8" Offset="0"/>
          <GradientStop Color="#E6DCE5EE" Offset="1"/>
        </LinearGradientBrush>
      </Border.Background>
      <Border.Effect>
        <DropShadowEffect BlurRadius="28" ShadowDepth="6" Direction="270" Opacity="0.3" Color="#000000"/>
      </Border.Effect>
      <Border.LayoutTransform>
        <ScaleTransform x:Name="scaleT" ScaleX="1" ScaleY="1"/>
      </Border.LayoutTransform>
      <Border.ContextMenu>
        <ContextMenu FlowDirection="RightToLeft">
          <MenuItem x:Name="miSettings" Header="הגדרות ואירועים..."/>
          <MenuItem x:Name="miTop" Header="תמיד מעל כל החלונות" IsCheckable="True"/>
          <Separator/>
          <MenuItem x:Name="miClose" Header="סגירת הווידג'ט"/>
        </ContextMenu>
      </Border.ContextMenu>
      <StackPanel>
        <Grid Margin="14,7,10,5">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <Canvas Grid.Column="0" Width="21" Height="21" FlowDirection="LeftToRight" VerticalAlignment="Center">
            <Rectangle Canvas.Left="1" Canvas.Top="2" Width="19" Height="17" RadiusX="4.5" RadiusY="4.5" Stroke="#83888F" StrokeThickness="1.7" Fill="Transparent"/>
            <Line X1="5.5" Y1="7" X2="15.5" Y2="7" Stroke="#83888F" StrokeThickness="1.7"/>
            <Line X1="5.5" Y1="10.8" X2="15.5" Y2="10.8" Stroke="#83888F" StrokeThickness="1.7"/>
            <Line X1="5.5" Y1="14.6" X2="11.5" Y2="14.6" Stroke="#83888F" StrokeThickness="1.7"/>
          </Canvas>
          <TextBlock Grid.Column="1" Text="ספירה לאחור לרגעים מרגשים" FontSize="13.5" FontWeight="SemiBold"
                     Foreground="#4E5259" Margin="9,0,0,0" VerticalAlignment="Center"/>
          <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
            <Button x:Name="btnSettings" Content="הגדרות" FontSize="11" Foreground="#5A5F66" Cursor="Hand"
                    Background="Transparent" BorderThickness="0" Padding="8,3,8,3" ToolTip="פתיחת חלון ההגדרות"/>
            <Button x:Name="btnClose" Content="✕" FontSize="12" Foreground="#8A8F96" Cursor="Hand"
                    Background="Transparent" BorderThickness="0" Padding="8,3,8,3" ToolTip="סגירה"/>
          </StackPanel>
        </Grid>
        <StackPanel x:Name="cardsHost"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
'@

# ==========================================================
#  חלון ההגדרות
# ==========================================================
$script:SettingsXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="הגדרות - ספירה לאחור לרגעים מרגשים" Width="680" Height="620" MinWidth="600" MinHeight="560"
        FlowDirection="RightToLeft" TextElement.FontFamily="Segoe UI" FontSize="13"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize" Background="#F5F6FA" Topmost="True">
  <Grid Margin="14">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="210"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border Grid.Row="0" Grid.Column="0" Background="White" CornerRadius="10" Padding="10" Margin="0,0,0,0" BorderBrush="#E2E4EC" BorderThickness="1">
      <DockPanel>
        <TextBlock DockPanel.Dock="Top" Text="האירועים שלי" FontWeight="Bold" Margin="2,0,2,8"/>
        <StackPanel DockPanel.Dock="Bottom" Orientation="Horizontal" Margin="0,8,0,0">
          <Button x:Name="btnNew" Content="+ אירוע חדש" Padding="10,5,10,5" Margin="0,0,6,0"/>
          <Button x:Name="btnDelete" Content="מחיקה" Padding="10,5,10,5"/>
        </StackPanel>
        <ListBox x:Name="lstEvents" BorderThickness="0"/>
      </DockPanel>
    </Border>

    <Border Grid.Row="0" Grid.Column="1" Background="White" CornerRadius="10" Padding="16" Margin="10,0,0,0" BorderBrush="#E2E4EC" BorderThickness="1">
      <StackPanel>
        <TextBlock Text="פרטי האירוע" FontWeight="Bold" Margin="0,0,0,10"/>
        <TextBlock Text="שם האירוע (למשל: לידת התינוק)"/>
        <TextBox x:Name="txtName" Padding="6,4,6,4" Margin="0,3,0,10"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Margin="0,0,10,0">
            <TextBlock Text="תאריך היעד"/>
            <DatePicker x:Name="dpDate" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel Grid.Column="1" Margin="0,0,8,0">
            <TextBlock Text="שעה"/>
            <ComboBox x:Name="cmbHour" Width="70" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel Grid.Column="2">
            <TextBlock Text="דקות"/>
            <ComboBox x:Name="cmbMin" Width="70" Margin="0,3,0,0"/>
          </StackPanel>
        </Grid>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" Margin="0,0,10,0">
            <TextBlock Text="ערכת צבע (תינוק / תינוקת)"/>
            <ComboBox x:Name="cmbTheme" Margin="0,3,0,0"/>
          </StackPanel>
          <StackPanel Grid.Column="1">
            <TextBlock Text="סגנון הציור"/>
            <ComboBox x:Name="cmbArt" Margin="0,3,0,0"/>
          </StackPanel>
        </Grid>
        <TextBlock Text="כיתוב לצד התאריך (למשל: תאריך משוער)"/>
        <TextBox x:Name="txtNote" Padding="6,4,6,4" Margin="0,3,0,12"/>
        <Button x:Name="btnApply" Content="עדכון האירוע הנבחר" Padding="14,6,14,6" HorizontalAlignment="Right"/>
      </StackPanel>
    </Border>
    <Border Grid.Row="1" Grid.ColumnSpan="2" Background="White" CornerRadius="10" Padding="14,10,14,10"
            Margin="0,12,0,0" BorderBrush="#E2E4EC" BorderThickness="1">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <WrapPanel Grid.Row="0">
          <CheckBox x:Name="chkTop" Content="תמיד מעל כל החלונות" VerticalAlignment="Center" Margin="0,0,18,0"/>
          <CheckBox x:Name="chkSec" Content="הצגת שניות" VerticalAlignment="Center" Margin="0,0,18,0"/>
          <CheckBox x:Name="chkStartup" Content="הפעלה אוטומטית עם הדלקת המחשב" VerticalAlignment="Center" Margin="0,0,18,0"/>
          <CheckBox x:Name="chkStay" Content="להישאר על המסך גם ב&quot;הצג שולחן עבודה&quot;" VerticalAlignment="Center" Margin="0,0,18,0"
                    ToolTip="הווידג'ט חוזר מיד גם אחרי Win+D או החלקה בשלוש אצבעות למטה"/>
        </WrapPanel>
        <Grid Grid.Row="1" Margin="0,12,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <TextBlock Grid.Column="0" Text="גודל:" VerticalAlignment="Center" Margin="0,0,6,0"/>
          <Slider x:Name="sldScale" Grid.Column="1" Minimum="0.7" Maximum="1.6" TickFrequency="0.05" IsSnapToTickEnabled="True" VerticalAlignment="Center" Margin="0,0,14,0"/>
          <TextBlock Grid.Column="2" Text="שקיפות כללית:" VerticalAlignment="Center" Margin="0,0,6,0"/>
          <Slider x:Name="sldOpacity" Grid.Column="3" Minimum="0.4" Maximum="1.0" TickFrequency="0.05" IsSnapToTickEnabled="True" VerticalAlignment="Center" Margin="0,0,14,0"/>
          <TextBlock Grid.Column="4" Text="שקיפות המסגרת:" VerticalAlignment="Center" Margin="0,0,6,0"/>
          <Slider x:Name="sldFrame" Grid.Column="5" Minimum="0.15" Maximum="1.0" TickFrequency="0.05" IsSnapToTickEnabled="True" VerticalAlignment="Center"/>
        </Grid>
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,14,0,0">
          <Button x:Name="btnOk" Content="שמירה וסגירה" Padding="18,7,18,7" FontWeight="SemiBold" Margin="0,0,8,0"/>
          <Button x:Name="btnCancel" Content="סגירה" Padding="18,7,18,7"/>
        </StackPanel>
      </Grid>
    </Border>
  </Grid>
</Window>
'@

# ==========================================================
#  לוגיקה
# ==========================================================
function ConvertFrom-Xaml([string]$text) {
    $sr = New-Object System.IO.StringReader $text
    $xr = [System.Xml.XmlReader]::Create($sr)
    return [Windows.Markup.XamlReader]::Load($xr)
}

function Format-EventDate($ev) {
    $months = @('ינואר','פברואר','מרץ','אפריל','מאי','יוני','יולי','אוגוסט','ספטמבר','אוקטובר','נובמבר','דצמבר')
    $d = [datetime]::Parse($ev.date)
    $s = "{0} ב{1} {2}" -f $d.Day, $months[$d.Month - 1], $d.Year
    if ($d.TimeOfDay.TotalMinutes -gt 0) { $s = "$s, " + $d.ToString('HH:mm') }
    $note = if ($ev.note) { [string]$ev.note } else { 'תאריך היעד' }
    return "$note`: $s"
}

function Build-Card($ev, [bool]$showAdd, [int]$index) {
    $t = Get-Theme $ev.theme
    $xaml = $script:CardXaml
    $small  = Get-AssetArt 'small'  $ev.art $ev.theme
    $main   = Get-AssetArt 'main'   $ev.art $ev.theme
    $rattle = Get-AssetArt 'foot'   $ev.art $ev.theme
    if (-not $small)  { $small  = Get-ArtSmall $ev.art }
    if (-not $main)   { $main   = Get-ArtMain  $ev.art }
    if (-not $rattle) {
        $rattle = '<Canvas Width="24" Height="18" FlowDirection="LeftToRight"><Ellipse Canvas.Left="0" Canvas.Top="4" Width="11" Height="11" Fill="{{ACCENT}}"/><Ellipse Canvas.Left="8" Canvas.Top="2" Width="14" Height="15" Stroke="{{ACCENT2}}" StrokeThickness="2.6" Fill="Transparent"/></Canvas>'
    }
    $xaml = $xaml.Replace('{{ART_SMALL}}',  $small)
    $xaml = $xaml.Replace('{{ART_MAIN}}',   $main)
    $xaml = $xaml.Replace('{{ART_RATTLE}}', $rattle)
    foreach ($k in @('Accent','Accent2','Soft','Foot','FootText','Heart','Skin','Hair')) {
        $xaml = $xaml.Replace(('{{' + $k.ToUpper() + '}}'), [string]$t[$k])
    }
    $card = ConvertFrom-Xaml $xaml
    $card.Tag = $index

    $card.FindName('txtName').Text = [string]$ev.name
    $card.FindName('txtDate').Text = Format-EventDate $ev

    $btnAdd = $card.FindName('btnAdd')
    if ($showAdd) {
        $btnAdd.Add_Click({ Show-SettingsWindow -NewEvent $true })
    } else {
        $btnAdd.Visibility = 'Collapsed'
    }
    $card.Add_MouseLeftButtonDown({
        param($s, $e)
        if ($e.ClickCount -eq 2) { Show-SettingsWindow -SelectIndex ([int]$s.Tag) }
    })

    if (-not $script:Config.settings.showSeconds) {
        $card.FindName('secBlock').Visibility = 'Collapsed'
        $card.FindName('secLine').Visibility  = 'Collapsed'
    }

    return [pscustomobject]@{
        Element = $card
        Target  = [datetime]::Parse($ev.date)
        Days    = $card.FindName('nDays')
        Hours   = $card.FindName('nHours')
        Mins    = $card.FindName('nMin')
        Secs    = $card.FindName('nSec')
        Row     = $card.FindName('numRow')
        Done    = $card.FindName('txtDone')
    }
}

function Update-Cards {
    $now = Get-Date
    foreach ($c in $script:CardRefs) {
        $span = $c.Target - $now
        if ($span.TotalSeconds -le 0) {
            $c.Row.Visibility  = 'Collapsed'
            $c.Done.Visibility = 'Visible'
            continue
        }
        $c.Row.Visibility  = 'Visible'
        $c.Done.Visibility = 'Collapsed'
        $c.Days.Text  = [string][math]::Floor($span.TotalDays)
        $c.Hours.Text = [string]$span.Hours
        $c.Mins.Text  = [string]$span.Minutes
        $c.Secs.Text  = '{0:00}' -f $span.Seconds
    }
}

$script:EmptyCardXaml = @'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        FlowDirection="RightToLeft" TextElement.FontFamily="Segoe UI" Background="#FDF7EC" CornerRadius="13"
        Margin="7,2,7,7" BorderBrush="#F0E6D5" BorderThickness="1" Padding="18,24,18,24">
  <StackPanel HorizontalAlignment="Center">
    <TextBlock Text="עדיין אין אירועים בספירה לאחור" FontSize="15" FontWeight="SemiBold" Foreground="#20222A" HorizontalAlignment="Center"/>
    <Button x:Name="btnAddEmpty" Content="הוסף אירוע  +" Margin="0,12,0,0" Padding="16,6,16,6" Cursor="Hand" HorizontalAlignment="Center"/>
  </StackPanel>
</Border>
'@

function Rebuild-Cards {
    $panel = $script:Win.FindName('cardsHost')
    $panel.Children.Clear()
    $script:CardRefs = @()

    $events = @(@($script:Config.events) | Where-Object { $_ -and $_.date } | Sort-Object { [datetime]::Parse($_.date) })
    if (-not $events -or $events.Count -eq 0) {
        $empty = ConvertFrom-Xaml $script:EmptyCardXaml
        $empty.FindName('btnAddEmpty').Add_Click({ Show-SettingsWindow -NewEvent $true })
        $panel.Children.Add($empty) | Out-Null
        return
    }

    for ($i = 0; $i -lt $events.Count; $i++) {
        $isLast = ($i -eq $events.Count - 1)
        $ref = Build-Card $events[$i] $isLast $i
        $panel.Children.Add($ref.Element) | Out-Null
        $script:CardRefs += $ref
    }
    Update-Cards
}

function Apply-VisualSettings {
    $s = $script:Config.settings
    $script:Win.Topmost = [bool]$s.alwaysOnTop
    $script:Win.Opacity = [double]$s.opacity
    $sc = $script:Win.FindName('scaleT')
    $sc.ScaleX = [double]$s.scale
    $sc.ScaleY = [double]$s.scale
    $mi = $script:Win.FindName('miTop')
    if ($mi) { $mi.IsChecked = [bool]$s.alwaysOnTop }
    Set-FrameAlpha ([double]$s.frameAlpha)
}

function Set-FrameAlpha([double]$a) {
    if ($a -lt 0.15) { $a = 0.15 }
    if ($a -gt 1.0)  { $a = 1.0 }
    $shell = $script:Win.FindName('shell')
    $top = [System.Windows.Media.Color]::FromArgb([byte][Math]::Round(242 * $a), 237, 243, 248)
    $bot = [System.Windows.Media.Color]::FromArgb([byte][Math]::Round(230 * $a), 220, 229, 238)
    $br  = New-Object System.Windows.Media.LinearGradientBrush
    $br.StartPoint = New-Object System.Windows.Point 0,0
    $br.EndPoint   = New-Object System.Windows.Point 0,1
    $br.GradientStops.Add((New-Object System.Windows.Media.GradientStop $top, 0.0))
    $br.GradientStops.Add((New-Object System.Windows.Media.GradientStop $bot, 1.0))
    $shell.Background = $br
    $rim = [System.Windows.Media.Color]::FromArgb([byte][Math]::Round(200 * $a), 255, 255, 255)
    $shell.BorderBrush = New-Object System.Windows.Media.SolidColorBrush $rim
}

# ---------------- הפעלה אוטומטית עם Windows ----------------
function Get-StartupFile {
    Join-Path ([Environment]::GetFolderPath('Startup')) 'CountdownWidget.vbs'
}
function Test-StartupEnabled { Test-Path (Get-StartupFile) }
function Set-Startup([bool]$enable) {
    $q = [string][char]34
    $f = Get-StartupFile
    if ($enable) {
        if ($script:PortableFile) {
            $cmd = 'CreateObject(' + $q + 'WScript.Shell' + $q + ').Run ' + ($q*3) + $script:PortableFile + ($q*3) + ', 0, False'
        } else {
            $ps1 = Join-Path $script:Root 'CountdownWidget.ps1'
            $cmd = 'CreateObject(' + $q + 'WScript.Shell' + $q + ').Run ' + $q + 'powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ' + ($q*2) + $ps1 + ($q*2) + $q + ', 0, False'
        }
        [System.IO.File]::WriteAllText($f, $cmd, [System.Text.Encoding]::ASCII)
    } elseif (Test-Path $f) {
        Remove-Item $f -Force
    }
}

# ==========================================================
#  חלון ההגדרות - לוגיקה
# ==========================================================
function Show-SettingsWindow {
    param([bool]$NewEvent = $false, [int]$SelectIndex = -1)

    if ($script:SettingsWin) { $script:SettingsWin.Activate(); return }

    $w = ConvertFrom-Xaml $script:SettingsXaml
    $script:SettingsWin = $w

    $themeKeys = @('girl','boy','neutral','purple','sun')
    $artKeys   = @([string[]]$script:ArtNames.Keys)

    $lst = $w.FindName('lstEvents'); $txtName = $w.FindName('txtName'); $txtNote = $w.FindName('txtNote')
    $dp  = $w.FindName('dpDate');    $cmbH   = $w.FindName('cmbHour');  $cmbM   = $w.FindName('cmbMin')
    $cmbT = $w.FindName('cmbTheme'); $cmbA   = $w.FindName('cmbArt')

    foreach ($k in $themeKeys) { $cmbT.Items.Add($script:Themes[$k].Name) | Out-Null }
    foreach ($k in $artKeys)   { $cmbA.Items.Add($script:ArtNames[$k])    | Out-Null }
    0..23 | ForEach-Object { $cmbH.Items.Add(('{0:00}' -f $_)) | Out-Null }
    0..59 | ForEach-Object { $cmbM.Items.Add(('{0:00}' -f $_)) | Out-Null }

    $work = New-Object System.Collections.ArrayList
    foreach ($e in (@($script:Config.events) | Where-Object { $_ -and $_.date } | Sort-Object { [datetime]::Parse($_.date) })) {
        [void]$work.Add([pscustomobject]@{ name=[string]$e.name; date=[string]$e.date; theme=[string]$e.theme; art=[string]$e.art; note=[string]$e.note })
    }

    $state = @{ loading = $false; index = -1 }

    $refreshList = {
        $state.loading = $true
        $sel = $lst.SelectedIndex
        $lst.Items.Clear()
        foreach ($e in $work) {
            $d = [datetime]::Parse($e.date)
            $lst.Items.Add(("{0}  ({1})" -f $e.name, $d.ToString('dd.MM.yyyy'))) | Out-Null
        }
        if ($sel -ge 0 -and $sel -lt $lst.Items.Count) { $lst.SelectedIndex = $sel }
        $state.loading = $false
    }

    $loadFields = {
        $i = $lst.SelectedIndex
        $state.index = $i
        if ($i -lt 0 -or $i -ge $work.Count) { return }
        $state.loading = $true
        $e = $work[$i]
        $d = [datetime]::Parse($e.date)
        $txtName.Text = $e.name
        $txtNote.Text = $e.note
        $dp.SelectedDate = $d.Date
        $cmbH.SelectedIndex = $d.Hour
        $cmbM.SelectedIndex = $d.Minute
        $ti = [array]::IndexOf($themeKeys, [string]$e.theme); if ($ti -lt 0) { $ti = 0 }
        $ai = [array]::IndexOf($artKeys,   [string]$e.art);   if ($ai -lt 0) { $ai = 0 }
        $cmbT.SelectedIndex = $ti
        $cmbA.SelectedIndex = $ai
        $state.loading = $false
    }

    $applyFields = {
        $i = $state.index
        if ($i -lt 0 -or $i -ge $work.Count) { return }
        $name = $txtName.Text.Trim(); if (-not $name) { $name = 'אירוע חדש' }
        $date = if ($dp.SelectedDate) { [datetime]$dp.SelectedDate } else { (Get-Date).Date.AddDays(30) }
        $hh = [Math]::Max(0, $cmbH.SelectedIndex); $mm = [Math]::Max(0, $cmbM.SelectedIndex)
        $full = $date.Date.AddHours($hh).AddMinutes($mm)
        $work[$i].name  = $name
        $work[$i].note  = $txtNote.Text.Trim()
        $work[$i].date  = $full.ToString('yyyy-MM-ddTHH:mm:ss')
        $work[$i].theme = $themeKeys[[Math]::Max(0,$cmbT.SelectedIndex)]
        $work[$i].art   = $artKeys[[Math]::Max(0,$cmbA.SelectedIndex)]
        & $refreshList
    }

    $lst.Add_SelectionChanged({ if (-not $state.loading) { & $loadFields } })

    $w.FindName('btnApply').Add_Click({ & $applyFields })

    $w.FindName('btnNew').Add_Click({
        & $applyFields
        $d = (Get-Date).Date.AddDays(30).AddHours(10)
        [void]$work.Add([pscustomobject]@{ name='אירוע חדש'; date=$d.ToString('yyyy-MM-ddTHH:mm:ss'); theme='girl'; art='baby'; note='תאריך היעד' })
        & $refreshList
        $lst.SelectedIndex = $work.Count - 1
        $txtName.Focus() | Out-Null
        $txtName.SelectAll()
    })

    $w.FindName('btnDelete').Add_Click({
        $i = $lst.SelectedIndex
        if ($i -lt 0) { return }
        $res = [System.Windows.MessageBox]::Show("למחוק את האירוע '" + $work[$i].name + "'?", 'מחיקת אירוע', 'YesNo', 'Question')
        if ($res -eq 'Yes') {
            $work.RemoveAt($i)
            $state.index = -1
            & $refreshList
            if ($work.Count -gt 0) { $lst.SelectedIndex = 0 }
        }
    })

    $s = $script:Config.settings
    $chkTop = $w.FindName('chkTop');   $chkSec = $w.FindName('chkSec');  $chkStart = $w.FindName('chkStartup')
    $chkStay = $w.FindName('chkStay')
    $sldS   = $w.FindName('sldScale'); $sldO   = $w.FindName('sldOpacity'); $sldF = $w.FindName('sldFrame')
    $chkTop.IsChecked   = [bool]$s.alwaysOnTop
    $chkSec.IsChecked   = [bool]$s.showSeconds
    $chkStart.IsChecked = Test-StartupEnabled
    $chkStay.IsChecked  = [bool]$s.stayVisible
    $sldS.Value = [double]$s.scale
    $sldO.Value = [double]$s.opacity
    $sldF.Value = [double]$s.frameAlpha

    $sldS.Add_ValueChanged({
        $sc = $script:Win.FindName('scaleT'); $sc.ScaleX = $sldS.Value; $sc.ScaleY = $sldS.Value
    })
    $sldO.Add_ValueChanged({ $script:Win.Opacity = $sldO.Value })
    $sldF.Add_ValueChanged({ Set-FrameAlpha ([double]$sldF.Value) })
    $chkTop.Add_Click({ $script:Win.Topmost = [bool]$chkTop.IsChecked })

    $w.FindName('btnOk').Add_Click({
        & $applyFields
        $script:Config.settings.alwaysOnTop = [bool]$chkTop.IsChecked
        $script:Config.settings.showSeconds = [bool]$chkSec.IsChecked
        $script:Config.settings.stayVisible = [bool]$chkStay.IsChecked
        $script:Config.settings.scale       = [double]$sldS.Value
        $script:Config.settings.opacity     = [double]$sldO.Value
        $script:Config.settings.frameAlpha  = [double]$sldF.Value
        $script:Config.events = @($work | Sort-Object { [datetime]::Parse($_.date) })
        $script:Config.settings.autoStart = [bool]$chkStart.IsChecked
        Set-Startup ([bool]$chkStart.IsChecked)
        Save-Config $script:Config
        Apply-VisualSettings
        Rebuild-Cards
        $w.Close()
    })

    $w.FindName('btnCancel').Add_Click({ $w.Close() })

    $w.Add_Closed({
        $script:SettingsWin = $null
        Apply-VisualSettings
    })

    & $refreshList
    if ($NewEvent) {
        $d = (Get-Date).Date.AddDays(30).AddHours(10)
        [void]$work.Add([pscustomobject]@{ name='אירוע חדש'; date=$d.ToString('yyyy-MM-ddTHH:mm:ss'); theme='girl'; art='baby'; note='תאריך היעד' })
        & $refreshList
        $lst.SelectedIndex = $work.Count - 1
    } elseif ($SelectIndex -ge 0 -and $SelectIndex -lt $work.Count) {
        $lst.SelectedIndex = $SelectIndex
    } elseif ($work.Count -gt 0) {
        $lst.SelectedIndex = 0
    }

    $w.ShowDialog() | Out-Null
}

# ==========================================================
#  הפעלה
# ==========================================================
$script:Mutex = New-Object System.Threading.Mutex($false, 'Global\BabyCountdownWidget_v1')
if (-not $script:Mutex.WaitOne(0, $false)) {
    [System.Windows.MessageBox]::Show('הווידג''ט כבר פועל.', 'ספירה לאחור', 'OK', 'Information') | Out-Null
    return
}

$script:Config   = Load-Config
$script:CardRefs = @()
$script:Win      = ConvertFrom-Xaml $script:WindowXaml
$script:SettingsWin = $null

# מיקום החלון (עם בדיקה שהוא בתוך המסך)
$sw = [System.Windows.SystemParameters]::PrimaryScreenWidth
$sh = [System.Windows.SystemParameters]::PrimaryScreenHeight
$L = [double]$script:Config.settings.left
$T = [double]$script:Config.settings.top
if ($L -lt 0 -or $L -gt ($sw - 120)) { $L = [Math]::Max(20, $sw - 560) }
if ($T -lt 0 -or $T -gt ($sh - 80))  { $T = 60 }
$script:Win.Left = $L
$script:Win.Top  = $T

Apply-VisualSettings
Rebuild-Cards

# הפעלה אוטומטית עם הדלקת המחשב (ברירת מחדל)
if ($script:Config.settings.autoStart) {
    try { Set-Startup $true } catch { }
}

# גרירה של הווידג'ט
$script:Win.Add_MouseLeftButtonDown({
    param($s, $e)
    if ($e.ClickCount -eq 1) {
        try { $script:Win.DragMove() } catch { }
    }
})
$script:Win.Add_LocationChanged({
    $script:Config.settings.left = [double]$script:Win.Left
    $script:Config.settings.top  = [double]$script:Win.Top
})

# הצמדת הווידג'ט לתוך גבולות המסך - בפיקסלים אמיתיים (עובד בכל סקאלת תצוגה)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class ScreenFit {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint action, uint p, ref RECT r, uint w);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int idx);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out int val, int size);
    public delegate bool EnumProc(IntPtr h, IntPtr l);

    static bool IsCloaked(IntPtr h) {
        int v = 0;
        return DwmGetWindowAttribute(h, 14, out v, 4) == 0 && v != 0;   // DWMWA_CLOAKED
    }
    static string Cls(IntPtr h) {
        var sb = new System.Text.StringBuilder(64);
        GetClassName(h, sb, 64);
        return sb.ToString();
    }
    // האם שולחן העבודה נמצא בראש הערימה (אחרי "הצג שולחן עבודה" / קליק על השולחן).
    // סורקים את סדר הערימה ומדלגים על החלון שלנו ועל חלונות עזר; מי שמופיע ראשון קובע.
    public static bool DesktopShown(IntPtr self) {
        bool result = false, done = false;
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            if (done) return false;
            if (h == self) return true;
            if (!IsWindowVisible(h) || IsIconic(h) || IsCloaked(h)) return true;
            RECT r;
            if (!GetWindowRect(h, out r)) return true;
            if (r.Right - r.Left < 120 || r.Bottom - r.Top < 60) return true;
            int ex = GetWindowLong(h, -20);
            if ((ex & 0x00000080) != 0) return true;                    // WS_EX_TOOLWINDOW
            string c = Cls(h);
            if (c == "Shell_TrayWnd" || c == "Shell_SecondaryTrayWnd" ||
                c == "NotifyIconOverflowWindow" || c == "Windows.UI.Core.CoreWindow" ||
                c == "ForegroundStaging" || c == "XamlExplorerHostIslandWindow") return true;
            result = (c == "WorkerW" || c == "Progman");                // מי בראש - השולחן או אפליקציה?
            done = true;
            return false;
        }, IntPtr.Zero);
        if (!done) {
            IntPtr fg = GetForegroundWindow();
            if (fg != IntPtr.Zero) { string fc = Cls(fg); result = (fc == "WorkerW" || fc == "Progman"); }
        }
        return result;
    }
    [DllImport("user32.dll")] public static extern IntPtr WindowFromPoint(POINT p);
    [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h, uint flags);
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }

    // האם מה שמצויר מעל מרכז הווידג'ט הוא שולחן העבודה עצמו
    public static bool CoveredByDesktop(IntPtr self) {
        RECT r;
        if (!GetWindowRect(self, out r)) return false;
        POINT p;
        p.X = (r.Left + r.Right) / 2;
        p.Y = (r.Top + r.Bottom) / 2;
        IntPtr top = WindowFromPoint(p);
        if (top == IntPtr.Zero) return false;
        IntPtr root = GetAncestor(top, 2);   // GA_ROOT
        if (root == self) return false;
        string c = Cls(root);
        return c == "WorkerW" || c == "Progman" || c == "SHELLDLL_DefView";
    }
    public static bool DesktopInFront() {
        IntPtr fg = GetForegroundWindow();
        if (fg == IntPtr.Zero) return false;
        string c = Cls(fg);
        return c == "WorkerW" || c == "Progman";
    }
    // הרמה מעל שולחן העבודה בלי להפוך ל"תמיד עליון" ובלי לגנוב פוקוס
    public static void RaiseAbove(IntPtr h) {
        SetWindowPos(h, IntPtr.Zero, 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010); // HWND_TOP|NOSIZE|NOMOVE|NOACTIVATE
    }
    public static void SetHidden(IntPtr h, bool hide) { ShowWindow(h, hide ? 0 : 8); } // SW_HIDE / SW_SHOWNA

    // מחזיר את הווידג'ט למסך אחרי "הצג שולחן עבודה" (Win+D / החלקה בשלוש אצבעות) - בלי לגנוב פוקוס
    public static bool Revive(IntPtr hWnd, bool topmost) {
        bool changed = false;
        if (IsIconic(hWnd))            { ShowWindow(hWnd, 4); changed = true; }   // SW_SHOWNOACTIVATE
        else if (!IsWindowVisible(hWnd)) { ShowWindow(hWnd, 8); changed = true; } // SW_SHOWNA
        if (changed)
            SetWindowPos(hWnd, topmost ? new IntPtr(-1) : IntPtr.Zero, 0, 0, 0, 0,
                         0x0001 | 0x0002 | 0x0010); // HWND_TOPMOST/HWND_TOP | NOSIZE|NOMOVE|NOACTIVATE
        return changed;
    }
    public static void Fit(IntPtr hWnd, int pad) {
        RECT w, area = new RECT();
        if (!GetWindowRect(hWnd, out w)) return;
        if (!SystemParametersInfo(0x0030, 0, ref area, 0)) return;   // SPI_GETWORKAREA
        int width = w.Right - w.Left, height = w.Bottom - w.Top;
        int x = w.Left, y = w.Top;
        if (x + width  > area.Right  - pad) x = area.Right  - pad - width;
        if (y + height > area.Bottom - pad) y = area.Bottom - pad - height;
        if (x < area.Left + pad) x = area.Left + pad;
        if (y < area.Top  + pad) y = area.Top  + pad;
        if (x != w.Left || y != w.Top)
            SetWindowPos(hWnd, IntPtr.Zero, x, y, 0, 0, 0x0001 | 0x0004 | 0x0010);  // NOSIZE|NOZORDER|NOACTIVATE
    }
}
"@

function Keep-OnScreen {
    try {
        $h = (New-Object System.Windows.Interop.WindowInteropHelper $script:Win).Handle
        if ($h -ne [IntPtr]::Zero) { [ScreenFit]::Fit($h, 6) }
    } catch { }
}
$script:HiddenByUs = $false
$script:TempTop    = $false
$script:LastDiag   = ''

# יומן אבחון: נכתב רק כשמשהו במצב החלון משתנה
function Write-Diag($line) {
    try {
        if (-not $script:Config.settings.diagLog) { return }
        $p = Join-Path $script:Root 'diag.log'
        if ((Test-Path $p) -and (Get-Item $p).Length -gt 300000) { Remove-Item $p -Force }
        Add-Content -Path $p -Value ((Get-Date).ToString('HH:mm:ss.fff') + '  ' + $line) -Encoding UTF8
    } catch { }
}

# ההגדרה "להישאר על המסך" קובעת את ההתנהגות בשני הכיוונים:
#   דלוקה  - הווידג'ט חוזר/מורם מעל שולחן העבודה גם אחרי "הצג שולחן עבודה"
#   כבויה  - הווידג'ט יורד יחד עם שאר החלונות, וחוזר כשעוזבים את שולחן העבודה
function Sync-Visibility {
    try {
        $h = (New-Object System.Windows.Interop.WindowInteropHelper $script:Win).Handle
        if ($h -eq [IntPtr]::Zero) { return }
        $onTop   = [bool]$script:Config.settings.alwaysOnTop
        $desktop = [ScreenFit]::DesktopShown($h) -or [ScreenFit]::DesktopInFront()
        $covered = [ScreenFit]::CoveredByDesktop($h)
        $state = "vis={0} icon={1} desktop={2} covered={3} top={4} stay={5} hidden={6} temptop={7}" -f `
                 [ScreenFit]::IsWindowVisible($h), [ScreenFit]::IsIconic($h), $desktop, $covered, $onTop,
                 [bool]$script:Config.settings.stayVisible, $script:HiddenByUs, $script:TempTop
        if ($state -ne $script:LastDiag) { Write-Diag $state; $script:LastDiag = $state }

        if ($script:Config.settings.stayVisible) {
            if ($script:HiddenByUs) { [ScreenFit]::SetHidden($h, $false); $script:HiddenByUs = $false }
            if ([ScreenFit]::Revive($h, $onTop)) { Keep-OnScreen }
            # בזמן "הצג שולחן עבודה" השולחן נמצא מעל השכבה הרגילה, ולכן הרמה רגילה לא מספיקה:
            # מעלים את הווידג'ט לשכבה העליונה באופן זמני, ומחזירים אותו למקומו כשהשולחן יורד.
            if (-not $onTop) {
                if ($desktop -or $covered) {
                    if (-not $script:TempTop) { $script:Win.Topmost = $true; $script:TempTop = $true }
                    [ScreenFit]::RaiseAbove($h)
                }
                elseif ($script:TempTop) { $script:Win.Topmost = $false; $script:TempTop = $false }
            }
            elseif ($script:TempTop) { $script:TempTop = $false }
        }
        elseif ($desktop) {
            if ($script:TempTop) { $script:Win.Topmost = [bool]$script:Config.settings.alwaysOnTop; $script:TempTop = $false }
            if (-not $script:HiddenByUs) { [ScreenFit]::SetHidden($h, $true); $script:HiddenByUs = $true }
        }
        else {
            if ($script:HiddenByUs) { [ScreenFit]::SetHidden($h, $false); $script:HiddenByUs = $false }
            [void][ScreenFit]::Revive($h, $onTop)
        }
    } catch { }
}
$script:Win.Add_StateChanged({ Sync-Visibility })
$script:Win.Add_ContentRendered({ Keep-OnScreen })
$script:Win.Add_SizeChanged({ Keep-OnScreen })

$script:Win.FindName('btnSettings').Add_Click({ Show-SettingsWindow })
$script:Win.FindName('miSettings').Add_Click({ Show-SettingsWindow })
$script:Win.FindName('btnClose').Add_Click({ $script:Win.Close() })
$script:Win.FindName('miClose').Add_Click({ $script:Win.Close() })
$script:Win.FindName('miTop').Add_Click({
    $v = [bool]$script:Win.FindName('miTop').IsChecked
    $script:Config.settings.alwaysOnTop = $v
    $script:Win.Topmost = $v
    Save-Config $script:Config
})

$script:Win.Add_Closing({ Write-Diag "=== הווידגט נסגר ==="; Save-Config $script:Config })

$script:Timer = New-Object System.Windows.Threading.DispatcherTimer
$script:Timer.Interval = [TimeSpan]::FromMilliseconds(500)
$script:Timer.Add_Tick({ Update-Cards })
$script:Timer.Start()

# בדיקת נראות בקצב מהיר (0.064 מ"ש לקריאה) - כדי שהחזרה אחרי "הצג שולחן עבודה" תהיה מיידית
$script:VisTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:VisTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$script:VisTimer.Add_Tick({ Sync-Visibility })
$script:VisTimer.Start()

Update-Cards
Write-Diag "=== הווידגט עלה ==="
$script:Win.ShowDialog() | Out-Null
$script:VisTimer.Stop()
$script:Timer.Stop()
$script:Mutex.ReleaseMutex()
