param()
$ErrorActionPreference = 'Stop'
Set-Location "C:\Users\Yene\Desktop\STEMs Prof Files\Sample Projects\prepup_ai"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host '-- start of final verification --'

$okFiles = @(
  'lib/main.dart',
  'lib/core/constants.dart',
  'lib/core/theme.dart',
  'design/INVENTORY.md',
  'design/README.md'
)

Write-Host '-- pub get --'
try { flutter pub get --verbosity=error 2>&1 | Select-Object -First 60 } catch { Write-Host "pub get failed: $($_.Exception.Message)" }

Write-Host '-- analyze --'
try { dart analyze lib/main.dart lib/core/constants.dart lib/core/theme.dart 2>&1 | Select-Object -First 60 }
catch { Write-Host "analyze failed: $($_.Exception.Message)" }

Write-Host '-- files exist --'
foreach ($f in $okFiles) {
  if (Test-Path $f) { Write-Host 'ok   ' $f } else { Write-Host 'MISSING ' $f }
}

Write-Host '-- ports 11090/11100/11110 (unexpected listeners only) --'
try {
  netstat -an -p tcp 2>$null | findstr /I '11090 11100 11110' | ForEach-Object { Write-Host $_.Trim() }
} catch { Write-Host 'netstat skipped: ' $_.Exception.Message }

Write-Host '-- end of final verification --'
