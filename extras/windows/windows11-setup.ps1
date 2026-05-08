# windows11-setup.ps1
# Runs as current user -- no elevation needed. All changes are HKCU.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-RegDWord {
    param([string]$Path, [string]$Name, [int]$Value)
    reg add $Path /v $Name /t REG_DWORD /d $Value /f | Out-Null
}

Write-Host "Applying Windows 11 tweaks..." -ForegroundColor Cyan

# -- Context menu: always show classic (full) options --------------------------
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
Write-Host "  [+] Classic context menu restored"

# -- File Explorer -------------------------------------------------------------
$adv = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-RegDWord $adv 'HideFileExt'         0   # show file extensions
Set-RegDWord $adv 'Hidden'              1   # show hidden files
Set-RegDWord $adv 'LaunchTo'            1   # open to This PC, not Quick Access
Set-RegDWord $adv 'TaskbarDa'           0   # remove Widgets button
Set-RegDWord $adv 'ShowTaskViewButton'  0   # remove Task View button
Set-RegDWord $adv 'TaskbarMn'           0   # remove Chat button
Set-RegDWord $adv 'Start_IrisRecommendations' 0  # no Start Menu recommendations
Set-RegDWord $adv 'Start_TrackProgs'    0   # no app launch tracking

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPath /t REG_DWORD /d 1 /f | Out-Null

# Default view: Details for all folder types
# Affects unvisited folders only -- folders with saved Bags state keep their view.
# To reset saved views: delete HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams
$folderTypes = @(
    '{fef2a4eb-9f28-4a62-ab21-6a63cf3f19a0}',  # Generic (catch-all)
    '{7d49d726-3c21-4f05-99aa-fdc2c9474656}',  # Documents
    '{885a186e-a440-4ada-812b-db871b942259}',  # Downloads
    '{94d6ddcc-4a68-4175-a374-bd584a510b78}',  # Music
    '{b3690e58-e961-423b-b687-386ebfd83239}',  # Pictures
    '{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}'   # Videos
)
foreach ($guid in $folderTypes) {
    $vp = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\$guid\TopViews\{00000000-0000-0000-0000-000000000000}"
    Set-RegDWord $vp 'LogicalViewMode' 1
    Set-RegDWord $vp 'IconSize' 16
}

Write-Host "  [+] File Explorer configured"

# -- Start Menu ----------------------------------------------------------------
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null
Write-Host "  [+] Start Menu cleaned up"

# -- Privacy -------------------------------------------------------------------
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f | Out-Null
Write-Host "  [+] Privacy settings tightened"

# -- Appearance ----------------------------------------------------------------
$personalize = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-RegDWord $personalize 'AppsUseLightTheme'    0
Set-RegDWord $personalize 'SystemUsesLightTheme' 0
Write-Host "  [+] Dark mode enabled"

# -- Restart Explorer to apply changes -----------------------------------------
Write-Host "`nRestarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "`nDone. Some changes (Start Menu layout) may need a sign-out/sign-in." -ForegroundColor Green
