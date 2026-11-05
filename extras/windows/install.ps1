<#
.SYNOPSIS
    Copies extras\windows\bin\* into C:\bin. A poor man's `make install`.

.DESCRIPTION
    - Creates the bin dir if it doesn't exist.
    - Copies every file in extras\windows\bin.
    - For each .ps1 without a matching .cmd, copies ps1-shim.cmd as
      <name>.cmd, so the script runs by name from cmd, PowerShell and Run.
    - Idempotent: unchanged files are left alone (hash compare), files this
      installer copied earlier are updated or pruned, and anything else in
      the bin dir is never replaced without -Force.
    - Plain copies, no symlinks, no admin needed. Re-run after editing.

    Installed names are tracked in <BinDir>\.dotfiles-installed.
#>
[CmdletBinding()]
param(
    [string]$BinDir = 'C:\bin',
    [switch]$Force,
    [switch]$Pause
)

$ErrorActionPreference = 'Stop'
$exitCode = 0

try {
    $here     = $PSScriptRoot
    $srcDir   = Join-Path $here 'bin'
    $shim     = Join-Path $here 'ps1-shim.cmd'
    $BinDir   = [IO.Path]::GetFullPath($BinDir).TrimEnd('\')
    $manifest = Join-Path $BinDir '.dotfiles-installed'

    Write-Host "Copying $srcDir -> $BinDir"

    if (-not (Test-Path -LiteralPath $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir | Out-Null
        Write-Host "created   $BinDir"
    }

    # Desired state: name -> source file (keys are case-insensitive).
    $want = [ordered]@{}
    foreach ($f in Get-ChildItem -LiteralPath $srcDir -File) { $want[$f.Name] = $f.FullName }
    foreach ($f in Get-ChildItem -LiteralPath $srcDir -File -Filter *.ps1) {
        $cmdName = $f.BaseName + '.cmd'
        if (-not $want.Contains($cmdName)) { $want[$cmdName] = $shim }
    }

    # What we copied last time.
    $installed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if (Test-Path -LiteralPath $manifest) {
        foreach ($l in Get-Content -LiteralPath $manifest) { if ($l.Trim()) { [void]$installed.Add($l.Trim()) } }
    }
    $nowInstalled = [Collections.Generic.List[string]]::new()

    foreach ($name in $want.Keys) {
        $dest   = Join-Path $BinDir $name
        $src    = $want[$name]
        $exists = Test-Path -LiteralPath $dest

        if ($exists -and -not $Force -and -not $installed.Contains($name)) {
            Write-Warning "skipped   $name (not installed by this script; use -Force to replace it)"
            continue
        }

        if ($exists -and (Get-FileHash -LiteralPath $dest).Hash -eq (Get-FileHash -LiteralPath $src).Hash) {
            Write-Host "ok        $name"
        } else {
            Copy-Item -LiteralPath $src -Destination $dest -Force
            Write-Host ('{0,-9} {1}' -f ($(if ($exists) { 'updated' } else { 'installed' })), $name)
        }
        $nowInstalled.Add($name)
    }

    # Prune files we copied earlier that are no longer in the repo.
    foreach ($name in $installed) {
        if ($want.Contains($name)) { continue }
        $dest = Join-Path $BinDir $name
        if (Test-Path -LiteralPath $dest) {
            Remove-Item -LiteralPath $dest -Force
            Write-Host "removed   $name"
        }
    }

    Set-Content -LiteralPath $manifest -Value ($nowInstalled | Sort-Object) -Force

    $onPath = ($env:Path -split ';') | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
    if ($onPath -notcontains $BinDir) { Write-Warning "$BinDir isn't on your PATH." }

    Write-Host 'Done.' -ForegroundColor Green
} catch {
    Write-Host $_ -ForegroundColor Red
    $exitCode = 1
} finally {
    if ($Pause) { Read-Host 'Press Enter to close' | Out-Null }
}
exit $exitCode
