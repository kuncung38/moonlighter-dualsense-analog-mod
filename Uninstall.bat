@echo off
title Moonlighter DualSense & 360 Analog Movement Mod - Uninstaller
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "$candidates = @();" ^
  "$sp = (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath;" ^
  "if ($sp) { $sp = $sp -replace '/','\'; $candidates += Join-Path $sp 'steamapps\common\Moonlighter'; $vdf = Join-Path $sp 'steamapps\libraryfolders.vdf'; if (Test-Path $vdf) { foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '\"path\"\s+\"([^\"]+)\"')) { $candidates += Join-Path ($m.Groups[1].Value -replace '\\\\','\') 'steamapps\common\Moonlighter' } } };" ^
  "foreach ($d in 'C','D','E','F','G') { $candidates += \"${d}:\Program Files (x86)\Steam\steamapps\common\Moonlighter\"; $candidates += \"${d}:\SteamLibrary\steamapps\common\Moonlighter\" };" ^
  "$gameDir = $candidates | Where-Object { Test-Path (Join-Path $_ 'Moonlighter.exe') } | Select-Object -First 1;" ^
  "if (-not $gameDir) { Add-Type -AssemblyName System.Windows.Forms; $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.Description = 'Select your Moonlighter folder'; if ($dlg.ShowDialog() -eq 'OK') { $gameDir = $dlg.SelectedPath } };" ^
  "if (-not $gameDir -or -not (Test-Path (Join-Path $gameDir 'Moonlighter.exe'))) { Write-Host 'Moonlighter folder not found.' -ForegroundColor Red; exit 1 };" ^
  "$dll = Join-Path $gameDir 'BepInEx\plugins\AnalogMovementMod.dll';" ^
  "if (Test-Path $dll) { Remove-Item $dll -Force; Write-Host 'Removed AnalogMovementMod.dll' -ForegroundColor Green } else { Write-Host 'AnalogMovementMod.dll was not found.' -ForegroundColor Yellow };" ^
  "$ans = Read-Host 'Also remove BepInEx loader completely? (y/N)';" ^
  "if ($ans -eq 'y' -or $ans -eq 'Y') { Remove-Item (Join-Path $gameDir 'BepInEx') -Recurse -Force; Remove-Item (Join-Path $gameDir 'winhttp.dll') -Force; Remove-Item (Join-Path $gameDir 'doorstop_config.ini') -Force; Write-Host 'Removed BepInEx completely.' -ForegroundColor Green }"
pause
