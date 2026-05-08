# windows11-debloat.ps1
# Removes built-in apps via winget and Appx. Run from an elevated PowerShell prompt.
# Comment out any line you want to keep before running.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'  # Don't abort if one package isn't present

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Not running as admin - some removals may fail."
}

# ── Telemetry (HKLM, requires admin) ─────────────────────────────────────────
if ($isAdmin) {
    $dataCollection = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $dataCollection)) { New-Item -Path $dataCollection -Force | Out-Null }
    # Lowest level most editions allow (0 = Security is Enterprise-only)
    Set-ItemProperty -Path $dataCollection -Name 'AllowTelemetry' -Value 1 -Type DWord
    Write-Host "  [+] Telemetry minimized" -ForegroundColor Cyan
} else {
    Write-Warning "Skipped telemetry (not admin)"
}

# ── Appx packages (built-in, no winget ID) ────────────────────────────────────
# These use Get-AppxPackage; failures are non-fatal (package may already be gone).

$appxPackages = @(
    'Microsoft.BingWeather',
    'Microsoft.BingNews',              # News widget / MSN News
    'Microsoft.BingFinance',
    'Microsoft.BingSports',
    'Microsoft.GetHelp',               # "Get Help" app
    'Microsoft.Getstarted',            # Tips
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MicrosoftOfficeHub',    # "Office" app (launcher, not actual Office)
    'Microsoft.MixedReality.Portal',
    'Microsoft.People',
    'Microsoft.SkypeApp',
    'Microsoft.Todos',                 # Microsoft To Do — remove if you use another task manager
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.YourPhone',             # Phone Link — remove if you don't use it
    'Microsoft.ZuneMusic',             # Media Player — remove if you use another
    'Microsoft.ZuneVideo',             # Movies & TV
    'MicrosoftTeams',                  # Teams (personal, not work Teams)
    'Clipchamp.Clipchamp',             # Video editor
    'Disney.37853D22215B2'             # Disney+ if pre-installed
)

Write-Host "Removing Appx packages..." -ForegroundColor Cyan
foreach ($pkg in $appxPackages) {
    $found = Get-AppxPackage -Name $pkg -AllUsers -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "  [-] $pkg"
        $found | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    } else {
        Write-Host "  [~] $pkg (not found, skipping)"
    }
}

# ── winget removals (have proper package IDs) ─────────────────────────────────
# These are apps that show up in Add/Remove Programs and have winget IDs.

$wingetPackages = @(
    # 'Microsoft.OneDrive',            # Using OneDrive for shared save game files
    'Microsoft.Cortana',
    'Microsoft.549981C3F5F10'          # Cortana (Store version, different ID)
    # 'Microsoft.Xbox.TCUI',           # Keeping Xbox packages
    # 'Microsoft.XboxApp',
    # 'Microsoft.XboxGameOverlay',
    # 'Microsoft.XboxGamingOverlay',
    # 'Microsoft.XboxIdentityProvider',
    # 'Microsoft.XboxSpeechToTextOverlay',
)

Write-Host "`nRemoving winget packages..." -ForegroundColor Cyan
foreach ($pkg in $wingetPackages) {
    Write-Host "  [-] $pkg"
    winget uninstall --id $pkg --silent --accept-source-agreements 2>&1 | Out-Null
}

Write-Host "`nDone. A restart is recommended." -ForegroundColor Green
