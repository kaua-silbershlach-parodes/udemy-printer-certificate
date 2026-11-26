# 03-build-installer.ps1
# Prepares the updater signing key (generating one ON THIS MACHINE if
# none exists - the private key is born here and never leaves except
# into the build environment), writes its public key into
# tauri.conf.json, and builds the NSIS installer + signed updater
# artifacts with cargo tauri build.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# The work folder defaults to <Drive>:\UdemyPrinterCertificate (same rule as
# script 02) and can be overridden with -WorkFolder.
#
# Usage (PowerShell):
#   .\03-build-installer.ps1 -Drive 'F'
#
# Requires: scripts 01 and 02 completed. Outputs in
# <clone>\src-tauri\target\release\bundle\: the NSIS Setup and its
# signature (.sig) - the signed Setup is itself the updater
# artifact. Publishing a release is a separate, deliberate step
# (see the README): upload the Setup, the .sig and a latest.json
# to a GitHub release with GH_TOKEN.

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive,
    [string]$WorkFolder
)

$ErrorActionPreference = 'Stop'
if (-not $WorkFolder) { $WorkFolder = "${Drive}:\UdemyPrinterCertificate" }
$Project = Join-Path $WorkFolder 'udemy-printer-certificate'
$TauriDir = Join-Path $Project 'src-tauri'
$Conf = Join-Path $TauriDir 'tauri.conf.json'
if (-not (Test-Path $Conf)) { throw "Project not found at $Project. Run script 02 first." }

$KeyDir = Join-Path $env:USERPROFILE '.udemy-printer-certificate'
$KeyFile = Join-Path $KeyDir 'updater-private.key'
New-Item -ItemType Directory -Force -Path $KeyDir | Out-Null
if (-not (Test-Path $KeyFile)) {
    Write-Host 'Generating the updater signing keypair on this machine...'
    & cargo tauri signer generate -w $KeyFile
    if ($LASTEXITCODE -ne 0) { throw "Key generation failed (exit $LASTEXITCODE)." }
}
$pubFile = "$KeyFile.pub"
if (-not (Test-Path $pubFile)) { throw "Public key not found at $pubFile" }
$pubKey = (Get-Content $pubFile -Raw).Trim()

$confText = Get-Content $Conf -Raw
if ($confText -match 'UPDATER_PUBKEY_PLACEHOLDER') {
    $confText = $confText -replace 'UPDATER_PUBKEY_PLACEHOLDER', $pubKey
    Set-Content -Path $Conf -Value $confText -Encoding ASCII
    Write-Host 'Public key written into tauri.conf.json (commit this change).'
} elseif ($confText -notmatch [regex]::Escape($pubKey)) {
    throw 'tauri.conf.json carries a DIFFERENT public key than this machine''s key. Refusing to build a release this key cannot sign for.'
}

$version = $null
if ((Get-Content $Conf -Raw) -match '"version"\s*:\s*"([^"]+)"') { $version = $Matches[1] }
Write-Host "Building version $version (cargo tauri build - this compiles the release binary)..."

$env:TAURI_SIGNING_PRIVATE_KEY = (Get-Content $KeyFile -Raw)
$env:TAURI_SIGNING_PRIVATE_KEY_PASSWORD = ''
& cargo tauri build --manifest-path (Join-Path $TauriDir 'Cargo.toml')
$buildRc = $LASTEXITCODE
Remove-Item Env:TAURI_SIGNING_PRIVATE_KEY -ErrorAction SilentlyContinue
if ($buildRc -ne 0) { throw "Build failed (cargo tauri exit $buildRc)." }

$bundleDir = Join-Path $TauriDir 'target\release\bundle\nsis'
$setup = Get-ChildItem $bundleDir -Filter '*setup*.exe' | Select-Object -First 1
$sig = Get-ChildItem $bundleDir -Filter '*.sig' | Select-Object -First 1
if (-not $setup -or -not $sig) { throw "Missing artifacts in $bundleDir (Setup or signature)." }

Write-Host "BUILD OK: $($setup.Name) + signature, in $bundleDir"
