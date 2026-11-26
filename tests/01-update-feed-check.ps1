# 01-update-feed-check.ps1 (test)
# Standalone check of the signed update feed the app consumes:
# downloads latest.json from the newest GitHub release and verifies
# it carries a version, a Windows bundle URL and a signature.
# Strict on purpose: it FAILS when no release has been published.
#
# Usage (PowerShell):
#   .\01-update-feed-check.ps1

$ErrorActionPreference = 'Stop'
$feedUrl = 'https://github.com/kaua-silbershlach-parodes/udemy-printer-certificate/releases/latest/download/latest.json'

$feed = Invoke-RestMethod -Uri $feedUrl
if (-not $feed.version) { throw 'latest.json has no version.' }
$win = $feed.platforms.'windows-x86_64'
if (-not $win) { throw 'latest.json has no windows-x86_64 platform entry.' }
if (-not $win.url -or -not $win.signature) { throw 'The windows entry lacks a URL or a signature.' }
Write-Host "Feed version: $($feed.version)"
Write-Host "Windows bundle: $($win.url)"
Write-Host 'Signature present: yes'

$appExe = Join-Path $env:LOCALAPPDATA 'Udemy Printer Certificate\udemy-printer-certificate.exe'
if (Test-Path $appExe) {
    $installed = (Get-Item $appExe).VersionInfo.FileVersion
    Write-Host "Installed version: $installed"
    if ([version]$feed.version -gt [version]$installed) {
        Write-Host 'An update is available on the feed.'
    } else {
        Write-Host 'The installed copy is current.'
    }
} else {
    Write-Host 'App not installed on this machine (feed check only).'
}

Write-Host 'FEED CHECK OK'
