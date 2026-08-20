# ==========================================================
#  בונה את כל הקבצים המועברים לפי הסדר הנכון:
#    מקורות -> קובץ ההתקנה + הגרסה הניידת -> GiftMaker
# ==========================================================
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition

& (Join-Path $dir 'Build-Installer.ps1')
& (Join-Path $dir 'Build-GiftMaker.ps1')

Write-Host ''
Write-Host 'הכול נבנה.' -ForegroundColor Green
