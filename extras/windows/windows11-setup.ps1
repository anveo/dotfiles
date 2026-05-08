# windows11-setup.ps1
# Run from an elevated PowerShell prompt for full effect.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-RegistryValue {
    param($Path, $Name, $Value, $Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
}

Write-Host "Applying Windows 11 tweaks..." -ForegroundColor Cyan

# ── Context menu: always show classic (full) options ──────────────────────────
$ctxMenu = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (-not (Test-Path $ctxMenu)) { New-Item -Path $ctxMenu -Force | Out-Null }
Set-ItemProperty -Path $ctxMenu -Name '(default)' -Value '' -Type String
Write-Host "  [+] Classic context menu restored"

# ── File Explorer ─────────────────────────────────────────────────────────────
$explorerAdv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Show file extensions
Set-RegistryValue $explorerAdv 'HideFileExt' 0
# Show hidden files and folders
Set-RegistryValue $explorerAdv 'Hidden' 1
# Open Explorer to This PC instead of Quick Access
Set-RegistryValue $explorerAdv 'LaunchTo' 1
# Remove Widgets button from taskbar
Set-RegistryValue $explorerAdv 'TaskbarDa' 0
# Remove Task View button from taskbar
Set-RegistryValue $explorerAdv 'ShowTaskViewButton' 0
# Remove Chat (Teams) button from taskbar
Set-RegistryValue $explorerAdv 'TaskbarMn' 0
# Show full path in title bar
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" 'FullPath' 1

# Default view: Details for all folder types
# Affects unvisited folders only — folders with saved Bags state keep their view.
# To reset all per-folder overrides: delete HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Streams
$folderTypes = @(
    '{fef2a4eb-9f28-4a62-ab21-6a63cf3f19a0}',  # Generic (catch-all)
    '{7d49d726-3c21-4f05-99aa-fdc2c9474656}',  # Documents
    '{885a186e-a440-4ada-812b-db871b942259}',  # Downloads
    '{94d6ddcc-4a68-4175-a374-bd584a510b78}',  # Music
    '{b3690e58-e961-423b-b687-386ebfd83239}',  # Pictures
    '{0b2baaeb-0042-4dca-aa4d-3ee8648d03e5}'   # Videos
)
foreach ($guid in $folderTypes) {
    $viewPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes\$guid\TopViews\{00000000-0000-0000-0000-000000000000}"
    Set-RegistryValue $viewPath 'LogicalViewMode' 1  # 1 = Details
    Set-RegistryValue $viewPath 'IconSize' 16
}

Write-Host "  [+] File Explorer configured"

# ── Start Menu ────────────────────────────────────────────────────────────────
# Disable Bing web search in Start
Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\Explorer" 'DisableSearchBoxSuggestions' 1
# Disable "Show recommendations" (suggested/recently added apps)
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" 'Start_IrisRecommendations' 0

Write-Host "  [+] Start Menu cleaned up"

# ── Privacy ───────────────────────────────────────────────────────────────────
# Disable advertising ID
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" 'Enabled' 0
# Disable app launch tracking
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" 'Start_TrackProgs' 0
# Disable suggested content in Settings app
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-338393Enabled' 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-353694Enabled' 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 'SubscribedContent-353696Enabled' 0

Write-Host "  [+] Privacy settings tightened"

# ── Telemetry (requires admin) ────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    # Minimum telemetry level (Security = 0, but 1 is the lowest most editions allow)
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" 'AllowTelemetry' 1
    Write-Host "  [+] Telemetry minimized"
} else {
    Write-Host "  [!] Skipped telemetry (not admin)" -ForegroundColor Yellow
}

# ── Restart Explorer to apply changes ─────────────────────────────────────────
Write-Host "`nRestarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2
Start-Process explorer

Write-Host "`nDone. Some changes (Start Menu layout) may need a sign-out/sign-in." -ForegroundColor Green
