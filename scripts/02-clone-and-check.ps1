# 02-clone-and-check.ps1
# Clones this repository (or updates an existing clone) and runs
# cargo check on the Rust shell. Passes when the whole crate graph
# type-checks on this machine.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\UdemyPrinterCertificate and can be
# overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\02-clone-and-check.ps1 -Drive 'F'
#
# Requires: script 01 completed (Git + Rust).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\UdemyPrinterCertificate" }
$RepoUrl = 'https://github.com/kaua-silbershlach-parodes/udemy-printer-certificate.git'
$Project = Join-Path $WorkFolder 'udemy-printer-certificate'

New-Item -ItemType Directory -Force -Path $WorkFolder | Out-Null

if (Test-Path (Join-Path $Project '.git')) {
    Write-Host 'Existing clone found. Pulling...'
    & git -C $Project pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "git pull failed (exit $LASTEXITCODE)." }
} else {
    Write-Host 'Cloning the repository...'
    & git clone $RepoUrl $Project
    if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)." }
}

Write-Host 'Type-checking the Rust shell (cargo check)...'
& cargo check --manifest-path (Join-Path $Project 'src-tauri\Cargo.toml')
if ($LASTEXITCODE -ne 0) { throw "cargo check failed (exit $LASTEXITCODE)." }

Write-Host "CHECK OK: $Project compiles clean on this machine."
