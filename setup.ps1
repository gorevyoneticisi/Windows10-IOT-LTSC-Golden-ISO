<#
.SYNOPSIS
    GOLDEN IMAGE – FLEXIBLE GAMER EDITION
.DESCRIPTION
    - Keeps Microsoft Store & Xbox
    - Removes consumer bloat
    - Disables AI / Copilot / Recall
    - Gaming-focused system tweaks
    - Locks Windows version (security updates only)
    - Generates "Optional Tweaks" toolbox on Public Desktop
.AUTHOR
    gorevyoneticisi
#>

Write-Host "=== STARTING GOLDEN IMAGE SETUP ===" -ForegroundColor Cyan

# ---------------------------------------------------------
# GLOBALS
# ---------------------------------------------------------
$ToolPath = "$env:PUBLIC\Desktop\Optional Tweaks"
$IsWin11 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName -like "*Windows 11*"

# Ensure Optional Tweaks folder exists
New-Item -Path $ToolPath -ItemType Directory -Force | Out-Null

# ---------------------------------------------------------
# PART 1: CLEANUP & POLICY HARDENING
# ---------------------------------------------------------

## 1. Disable Consumer Bloat & Silent Installs
Write-Host "Blocking consumer features..." -ForegroundColor Yellow
$CloudKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
New-Item -Path $CloudKey -Force | Out-Null
Set-ItemProperty $CloudKey DisableWindowsConsumerFeatures 1
Set-ItemProperty $CloudKey DisableTailoredExperiencesWithDiagnosticData 1

$CDMKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
New-Item -Path $CDMKey -Force | Out-Null
"ContentDeliveryAllowed","OemPreInstalledAppsEnabled","SilentInstalledAppsEnabled" |
ForEach-Object { Set-ItemProperty $CDMKey $_ 0 }

## 2. Disable AI / Copilot / Recall
Write-Host "Disabling AI & Copilot..." -ForegroundColor Yellow
$CopilotKeys = @(
    "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
)
foreach ($Key in $CopilotKeys) {
    New-Item -Path $Key -Force | Out-Null
    Set-ItemProperty $Key TurnOffWindowsCopilot 1
}

$AIKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
New-Item $AIKey -Force | Out-Null
Set-ItemProperty $AIKey DisableAIDataAnalysis 1

## 3. Remove Safe-List Bloat (Store & Xbox kept)
Write-Host "Removing junk apps..." -ForegroundColor Yellow
$Bloat = @(
    "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted",
    "Microsoft.Messaging","Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftSolitaireCollection","Microsoft.People",
    "Microsoft.SkypeApp","Microsoft.YourPhone","Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo","Microsoft.WindowsFeedbackHub",
    "Microsoft.MixedReality.Portal","Microsoft.Windows.Cortana",
    "Microsoft.Todos","Microsoft.PowerAutomateDesktop"
)

foreach ($App in $Bloat) {
    Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $App |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

## 4. Gaming Tweaks
Write-Host "Applying gaming tweaks..." -ForegroundColor Yellow
New-Item "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
Set-ItemProperty "HKCU:\Software\Microsoft\GameBar" AllowAutoGameMode 1
Set-ItemProperty "HKCU:\Control Panel\Mouse" MouseSpeed 0

## 5. Lock Windows Version (Security Updates Only)
Write-Host "Locking Windows version..." -ForegroundColor Yellow
$Current = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$WUKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
New-Item $WUKey -Force | Out-Null
Set-ItemProperty $WUKey TargetReleaseVersion 1
Set-ItemProperty $WUKey ProductVersion $Current.ProductName.Split()[0..1] -Join " "
Set-ItemProperty $WUKey TargetReleaseVersionInfo $Current.DisplayVersion

# ---------------------------------------------------------
# PART 2: OPTIONAL TWEAKS TOOLBOX
# ---------------------------------------------------------
Write-Host "Generating Optional Tweaks toolbox..." -ForegroundColor Green

## Steam & Epic Installer
@"
@echo off
echo Downloading Steam...
powershell -Command "Invoke-WebRequest https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe -OutFile `%TEMP%\SteamSetup.exe"
start /wait "" `%TEMP%\SteamSetup.exe /S
echo Downloading Epic Games...
powershell -Command "Invoke-WebRequest https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher.msi -OutFile `%TEMP%\Epic.msi"
start /wait "" msiexec /i `%TEMP%\Epic.msi /q
pause
"@ | Set-Content "$ToolPath\Install_Steam_Epic.bat"

## GPU Driver Shortcuts
'@echo off
start https://www.techpowerup.com/download/techpowerup-nvcleanstall/
pause' | Set-Content "$ToolPath\Get_Nvidia_Drivers.bat"

'@echo off
start https://www.amd.com/en/support
pause' | Set-Content "$ToolPath\Get_AMD_Drivers.bat"

## Hibernation
'@echo off
powercfg /h on
pause' | Set-Content "$ToolPath\Enable_Hibernation.bat"

'@echo off
powercfg /h off
pause' | Set-Content "$ToolPath\Disable_Hibernation.bat"

## Visual Effects
'@echo off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f
pause' | Set-Content "$ToolPath\Visuals_Performance_Mode.bat"

'@echo off
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f
pause' | Set-Content "$ToolPath\Visuals_Pretty_Mode.bat"

## Unlock Windows Updates
'@echo off
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f
pause' | Set-Content "$ToolPath\Unlock_Windows_Updates.bat"

## Classic Context Menu (Win11)
if ($IsWin11) {
'@echo off
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
taskkill /f /im explorer.exe
start explorer.exe
pause' | Set-Content "$ToolPath\Enable_Classic_RightClick.bat"
}

Write-Host "=== SETUP COMPLETE ===" -ForegroundColor Green
Write-Host "Check the 'Optional Tweaks' folder on your Desktop."
