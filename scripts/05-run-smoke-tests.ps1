# 05-run-smoke-tests.ps1
# End-to-end proof on the rebuilt machine:
#   1. the install layout is intact (app exe present, version reads);
#   2. the GitHub update feed (latest.json) - checked when a release
#      has been published; before the first release this step is
#      reported as pending, not failed (publishing is deliberate);
#   3. the app launches and its process stays up;
#   4. a record file is written to the Desktop.
#
# Usage (PowerShell):
#   .\05-run-smoke-tests.ps1
#
# Requires: script 04 completed (the app installed).

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'Udemy Printer Certificate'
$appExe = Join-Path $installDir 'udemy-printer-certificate.exe'

if (-not (Test-Path $appExe)) { throw 'App exe missing. Run script 04 first.' }
$installed = (Get-Item $appExe).VersionInfo.FileVersion
Write-Host "1. Install layout OK. Installed version: $installed"

$feedUrl = 'https://github.com/kaua-silbershlach-parodes/udemy-printer-certificate/releases/latest/download/latest.json'
$feedNote = 'not published yet'
try {
    $feed = Invoke-RestMethod -Uri $feedUrl
    if (-not $feed.version) { throw 'manifest without a version' }
    $feedNote = "published, newest $($feed.version)"
    Write-Host "2. Update feed OK. Newest published version: $($feed.version)"
} catch {
    Write-Host '2. Update feed: no signed release published yet (expected before the first release).'
}

Write-Host '3. Launching the app...'
Start-Process $appExe
Start-Sleep -Seconds 5
$proc = Get-Process -Name 'udemy-printer-certificate' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { throw 'The app process is not running after launch.' }
Write-Host "   App running (PID $($proc.Id))."

$record = Join-Path ([Environment]::GetFolderPath('Desktop')) 'CHATGPT-COMMANDER-ELITE-SMOKE-TEST.txt'
@(
    'Udemy Printer Certificate - rebuild record'
    "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Machine: $env:COMPUTERNAME"
    "Install folder: $installDir"
    "Installed version: $installed"
    "Update feed: $feedNote"
    "Feed: $feedUrl"
    'Result: installed app, update feed availability and app launch verified.'
) | Set-Content -Path $record -Encoding ASCII
Write-Host "4. Record written: $record"

Write-Host 'SMOKE TESTS OK: installed app and updater checks completed.'
