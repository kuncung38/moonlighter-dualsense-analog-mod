# Moonlighter DualSense & 360 Analog Movement Mod - 1-Click Installer
$ErrorActionPreference = "Stop"

$RepoOwner = "kuncung38"
$RepoName = "moonlighter-dualsense-analog-mod"
$ZipName = "Moonlighter-DualSense-Analog-Mod.zip"
$ReleaseUrl = "https://github.com/$RepoOwner/$RepoName/releases/latest/download/$ZipName"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Moonlighter - DualSense & 360 Analog Movement Mod  " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

function Find-MoonlighterDir {
    $candidates = New-Object System.Collections.Generic.List[string]

    # 1. Check Steam registry
    $steamPath = $null
    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
        if (-not $steamPath) {
            $steamPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -ErrorAction SilentlyContinue).InstallPath
        }
    } catch {}

    if ($steamPath) {
        $steamPath = $steamPath -replace "/", "\"
        $candidates.Add((Join-Path $steamPath "steamapps\common\Moonlighter"))

        $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
        if (Test-Path $vdfPath) {
            $vdfContent = Get-Content $vdfPath -Raw
            $matches = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"')
            foreach ($m in $matches) {
                $libPath = $m.Groups[1].Value -replace "\\\\", "\"
                $candidates.Add((Join-Path $libPath "steamapps\common\Moonlighter"))
            }
        }
    }

    # 2. Common fallback paths
    foreach ($drive in @("C", "D", "E", "F", "G")) {
        $candidates.Add("${drive}:\Program Files (x86)\Steam\steamapps\common\Moonlighter")
        $candidates.Add("${drive}:\SteamLibrary\steamapps\common\Moonlighter")
        $candidates.Add("${drive}:\Games\Moonlighter")
    }

    foreach ($dir in ($candidates | Select-Object -Unique)) {
        if (Test-Path (Join-Path $dir "Moonlighter.exe")) {
            return $dir
        }
    }
    return $null
}

function Select-MoonlighterDir {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select your Moonlighter installation folder (where Moonlighter.exe is located)"
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

# Check if running from an extracted release folder (offline install)
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$LocalWinhttp = Join-Path $ScriptDir "winhttp.dll"
$LocalBepInEx = Join-Path $ScriptDir "BepInEx"
$IsLocalPackage = (Test-Path $LocalWinhttp) -and (Test-Path $LocalBepInEx)

Write-Host "[1/3] Locating Moonlighter installation..." -ForegroundColor Yellow
$GameDir = Find-MoonlighterDir

if (-not $GameDir) {
    Write-Host "Could not auto-detect Moonlighter. Please select your Moonlighter folder..." -ForegroundColor Yellow
    $GameDir = Select-MoonlighterDir
}

if (-not $GameDir -or -not (Test-Path (Join-Path $GameDir "Moonlighter.exe"))) {
    Write-Host ""
    Write-Host "ERROR: Moonlighter.exe was not found in the selected folder." -ForegroundColor Red
    Write-Host "Installation cancelled." -ForegroundColor Red
    if ($Host.Name -eq "ConsoleHost") { Read-Host "Press Enter to exit" }
    exit 1
}

Write-Host "Found Moonlighter at: $GameDir" -ForegroundColor Green

if ($IsLocalPackage) {
    Write-Host "[2/3] Installing bundled BepInEx & AnalogMovementMod..." -ForegroundColor Yellow
    Copy-Item -Path (Join-Path $ScriptDir "winhttp.dll") -Destination $GameDir -Force
    Copy-Item -Path (Join-Path $ScriptDir "doorstop_config.ini") -Destination $GameDir -Force
    Copy-Item -Path (Join-Path $ScriptDir "BepInEx") -Destination $GameDir -Recurse -Force
} else {
    Write-Host "[2/3] Downloading latest release from GitHub..." -ForegroundColor Yellow
    $TempZip = Join-Path $env:TEMP $ZipName
    $TempExtract = Join-Path $env:TEMP "MoonlighterModExtract"

    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $TempZip -UseBasicParsing

    Write-Host "[3/3] Extracting mod files to Moonlighter..." -ForegroundColor Yellow
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

    Copy-Item -Path (Join-Path $TempExtract "winhttp.dll") -Destination $GameDir -Force
    Copy-Item -Path (Join-Path $TempExtract "doorstop_config.ini") -Destination $GameDir -Force
    Copy-Item -Path (Join-Path $TempExtract "BepInEx") -Destination $GameDir -Recurse -Force

    Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "SUCCESS! Mod installed to:" -ForegroundColor Green
Write-Host "  $GameDir\BepInEx\plugins\AnalogMovementMod.dll" -ForegroundColor White
Write-Host ""
Write-Host "Tips for DualSense users:" -ForegroundColor Cyan
Write-Host "  - Keep Steam Input ENABLED in Steam (required for Moonlighter to see DualSense)." -ForegroundColor Gray
Write-Host "  - PlayStation button icons will appear automatically (USB & Bluetooth)." -ForegroundColor Gray
Write-Host "  - Optional: Set L2 to 'Hair Trigger' in Steam Overlay for instant dodge." -ForegroundColor Gray
Write-Host ""
