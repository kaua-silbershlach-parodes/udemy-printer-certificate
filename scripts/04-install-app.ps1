# 04-install-app.ps1
# Installs the built app SILENTLY (Tauri NSIS Setup with /S):
# per-user, no wizard interaction, no admin rights. Verifies the
# installed layout afterwards, waiting for the installer to finish.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# It only locates the built Setup (work folder defaults to
# <Drive>:\UdemyPrinterCertificate, as in scripts 02/03). The app itself
# installs per-user into %LocalAppData%\Udemy Printer Certificate -
# the NSIS per-user layout, not drive-selectable.
#
# Usage (PowerShell):
#   .\04-install-app.ps1 -Drive 'F'
#
# Requires: script 03 completed (the Setup.exe exists).

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\UdemyPrinterCertificate" }
$BundleDir = Join-Path $WorkFolder 'udemy-printer-certificate\src-tauri\target\release\bundle\nsis'

$setup = Get-ChildItem $BundleDir -Filter '*setup*.exe' |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $setup) { throw 'No Setup.exe found. Run script 03 first.' }

Write-Host "Installing silently: $($setup.FullName)"
Start-Process $setup.FullName -ArgumentList '/S' -Wait

$installDir = Join-Path $env:LOCALAPPDATA 'Udemy Printer Certificate'
$appExe = Join-Path $installDir 'udemy-printer-certificate.exe'
$deadline = (Get-Date).AddSeconds(90)
while (-not (Test-Path $appExe)) {
    if ((Get-Date) -gt $deadline) { throw "Install incomplete: $appExe not found." }
    Start-Sleep -Seconds 3
}

$version = (Get-Item $appExe).VersionInfo.FileVersion
Write-Host "INSTALL OK: version $version at $installDir"
