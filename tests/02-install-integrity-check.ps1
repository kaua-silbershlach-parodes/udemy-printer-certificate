# 02-install-integrity-check.ps1 (test)
# Standalone check of an install of this app on this machine: the
# app executable and the uninstaller are present, and the version
# is readable.
#
# Usage (PowerShell):
#   .\02-install-integrity-check.ps1

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'Udemy Printer Certificate'

$appExe = Join-Path $installDir 'udemy-printer-certificate.exe'
if (-not (Test-Path $appExe)) { throw "Missing: app exe at $appExe" }
Write-Host 'OK: app exe'
if (-not (Get-ChildItem $installDir -Filter 'uninstall*.exe')) { throw 'Missing: the uninstaller.' }
Write-Host 'OK: uninstaller'

$version = (Get-Item $appExe).VersionInfo.FileVersion
Write-Host "Installed version: $version"
Write-Host 'INTEGRITY CHECK OK'
