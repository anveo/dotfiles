# windows11-setup.ps1
# Runs as current user -- no elevation needed. All changes are HKCU.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function reg-add {
    param([string]$Path, [string]$Name, [string]$Type, [string]$Value)
    $result = reg add $Path /v $Name /t $Type /d $Value /f 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [!] Failed: $Path\$Name" -ForegroundColor Yellow
    }
}

Write-Host "Applying Windows 11 tweaks..." -ForegroundColor Cyan

# -- Context menu: always show classic (full) options --------------------------
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve 2>&1 | Out-Null
Write-Host "  [+] Classic context menu restored"

# -- File Explorer -------------------------------------------------------------
$adv = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
reg-add $adv 'HideFileExt'               'REG_DWORD' '0'
reg-add $adv 'Hidden'                    'REG_DWORD' '1'
reg-add $adv 'LaunchTo'                  'REG_DWORD' '1'
reg-add $adv 'ShowTaskViewButton'        'REG_DWORD' '0'
reg-add $adv 'TaskbarMn'                 'REG_DWORD' '0'
reg-add $adv 'TaskbarAl'                 'REG_DWORD' '1'  # 1 = center, 0 = left
reg-add $adv 'Start_IrisRecommendations' 'REG_DWORD' '0'
reg-add $adv 'Start_TrackProgs'          'REG_DWORD' '0'

reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" 'FullPath' 'REG_DWORD' '1'

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
    reg-add $vp 'LogicalViewMode' 'REG_DWORD' '1'
    reg-add $vp 'IconSize'        'REG_DWORD' '16'
}

Write-Host "  [+] File Explorer configured"

# -- Start Menu ----------------------------------------------------------------
# Use Search key instead of Policies path (Policies is write-protected on some machines)
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" 'BingSearchEnabled'     'REG_DWORD' '0'
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" 'CortanaConsent'        'REG_DWORD' '0'
Write-Host "  [+] Start Menu cleaned up"

# -- Privacy -------------------------------------------------------------------
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"       'Enabled'                        'REG_DWORD' '0'
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
reg-add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
Write-Host "  [+] Privacy settings tightened"

# -- Appearance ----------------------------------------------------------------
$p = "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
reg-add $p 'AppsUseLightTheme'    'REG_DWORD' '0'
reg-add $p 'SystemUsesLightTheme' 'REG_DWORD' '0'
Write-Host "  [+] Dark mode enabled"

# -- Restart Explorer to apply changes -----------------------------------------
Write-Host "`nRestarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "`nDone. Some changes (Start Menu layout) may need a sign-out/sign-in." -ForegroundColor Green
