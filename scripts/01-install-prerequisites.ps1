# 01-install-prerequisites.ps1
# Installs everything a freshly formatted Windows machine needs to
# build this template: Git, the Rust toolchain (rustup + stable,
# MSVC host), the Visual Studio Build Tools (C++ workload - the
# linker Rust needs on Windows), the WebView2 runtime, the Tauri
# CLI, and the BEAM toolchain for the backend: Erlang/OTP + Elixir.
#
# -Drive is a PARAMETER on purpose: drive letters change per machine.
# Rust lives on the chosen drive: RUSTUP_HOME = <Drive>:\rust\rustup
# and CARGO_HOME = <Drive>:\rust\cargo (user-level environment).
# rustup-init.exe is verified by EXACT SIZE and SHA256 (official
# .sha256 file) before it runs. The Build Tools are system-level
# (winget installs them in the default location). Everything silent.
#
# Usage (PowerShell):
#   .\01-install-prerequisites.ps1 -Drive 'F'
#
# Requires: Windows 10/11 x64, internet access, winget (App
# Installer), about 12 GB free (Build Tools are the big one).
# Prefer an INTERNAL drive for the Rust and BEAM homes.

param(
    [Parameter(Mandatory = $true)]
    [string]$Drive
)

$ErrorActionPreference = 'Stop'

$RustupHome = "${Drive}:\rust\rustup"
$CargoHome = "${Drive}:\rust\cargo"

Write-Host 'Installing Git...'
& winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { throw "Git install failed (winget exit $LASTEXITCODE)." }

Write-Host 'Installing Visual Studio Build Tools (C++ workload)...'
& winget install --id Microsoft.VisualStudio.2022.BuildTools -e --silent --accept-source-agreements --accept-package-agreements --override '--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
if ($LASTEXITCODE -ne 0) { throw "Build Tools install failed (winget exit $LASTEXITCODE)." }

Write-Host 'Installing the WebView2 runtime...'
& winget install --id Microsoft.EdgeWebView2Runtime -e --silent --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0) { Write-Host 'WebView2 runtime step returned nonzero (it is usually preinstalled on Windows 10/11). Continuing.' }

$RustupUrl = 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe'
$ExactSize = 12839424
$ExactSha256 = '38027d51d69a5d05493627a0634dbea52d6cd793c8f072d2373d3f4163eec7db'
$init = Join-Path $env:TEMP 'rustup-init.exe'
if ((Test-Path $init) -and (Get-Item $init).Length -ne $ExactSize) { Remove-Item $init -Force }
if (-not (Test-Path $init)) {
    Write-Host 'Downloading rustup-init.exe...'
    & curl.exe -L --fail -o $init $RustupUrl
    if ($LASTEXITCODE -ne 0) { throw "rustup-init download failed (curl exit $LASTEXITCODE)." }
}
if ((Get-Item $init).Length -ne $ExactSize) { throw 'rustup-init size mismatch. Aborting.' }
$sha = (certutil -hashfile $init SHA256 | Select-Object -Index 1).Trim().ToLower()
if ($sha -ne $ExactSha256) { throw "rustup-init SHA256 mismatch ($sha). Aborting." }
Write-Host 'rustup-init verified: exact size and SHA256.'

[Environment]::SetEnvironmentVariable('RUSTUP_HOME', $RustupHome, 'User')
[Environment]::SetEnvironmentVariable('CARGO_HOME', $CargoHome, 'User')
$env:RUSTUP_HOME = $RustupHome
$env:CARGO_HOME = $CargoHome
Write-Host "Installing Rust (stable, MSVC) into $RustupHome / $CargoHome ..."
& $init -y --default-toolchain stable --profile minimal --no-modify-path
if ($LASTEXITCODE -ne 0) { throw "rustup install failed (exit $LASTEXITCODE)." }

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$CargoHome\bin*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$CargoHome\bin", 'User')
}
$env:Path = "$env:Path;$CargoHome\bin"

$rustc = & rustc --version
$cargo = & cargo --version
Write-Host "Rust OK: $rustc | $cargo"

Write-Host 'Installing the Tauri CLI (compiles from source, takes a few minutes)...'
& cargo install tauri-cli --version '^2'
if ($LASTEXITCODE -ne 0) { throw "tauri-cli install failed (exit $LASTEXITCODE)." }
$tauri = & cargo tauri --version
Write-Host "Tauri CLI OK: $tauri"

# --- Erlang/OTP 29.1.2 (the BEAM the Elixir backend runs on) ---
# Erlang publishes hashes only for its source tarballs, not for the
# Windows installer - so this gate is exact size + official host,
# disclosed here and in the README.
$ErlDir = "${Drive}:\erlang"
$ErlExe = Join-Path $env:TEMP 'otp_win64_29.1.2.exe'
$ErlSize = 155770072
if ((Test-Path $ErlExe) -and (Get-Item $ErlExe).Length -ne $ErlSize) { Remove-Item $ErlExe -Force }
if (-not (Test-Path $ErlExe)) {
    Write-Host 'Downloading Erlang/OTP 29.1.2...'
    & curl.exe -L --fail -o $ErlExe 'https://github.com/erlang/otp/releases/download/OTP-29.1.2/otp_win64_29.1.2.exe'
    if ($LASTEXITCODE -ne 0) { throw "Erlang download failed (curl exit $LASTEXITCODE)." }
}
if ((Get-Item $ErlExe).Length -ne $ErlSize) { throw 'Erlang installer size mismatch. Aborting.' }
Write-Host 'Erlang installer verified: exact size, official host. Installing silently...'
Start-Process $ErlExe -ArgumentList '/S', "/D=$ErlDir" -Wait
$erlBin = $null
$deadline = (Get-Date).AddSeconds(240)
while (-not $erlBin) {
    $found = Get-ChildItem $ErlDir -Recurse -Filter 'erl.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $erlBin = $found.DirectoryName }
    elseif ((Get-Date) -gt $deadline) { throw 'Erlang install incomplete: erl.exe not found.' }
    else { Start-Sleep -Seconds 5 }
}
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$erlBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$erlBin", 'User')
}
$env:Path = "$env:Path;$erlBin"
$otp = & erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().'
Write-Host "Erlang OK: OTP $otp (bin at $erlBin)"

# --- Elixir 1.20.5 (precompiled for OTP 29) ---
$ExZip = Join-Path $env:TEMP 'elixir-otp-29.zip'
$ExSize = 8643796
$ExSha256 = 'f424d6f0bb710a1d4898f2645d8ad6cab3f5eab8d71848c0dda2579d3a8e8a06'
if ((Test-Path $ExZip) -and (Get-Item $ExZip).Length -ne $ExSize) { Remove-Item $ExZip -Force }
if (-not (Test-Path $ExZip)) {
    Write-Host 'Downloading Elixir 1.20.5...'
    & curl.exe -L --fail -o $ExZip 'https://github.com/elixir-lang/elixir/releases/download/v1.20.5/elixir-otp-29.zip'
    if ($LASTEXITCODE -ne 0) { throw "Elixir download failed (curl exit $LASTEXITCODE)." }
}
if ((Get-Item $ExZip).Length -ne $ExSize) { throw 'Elixir zip size mismatch. Aborting.' }
$exSha = (certutil -hashfile $ExZip SHA256 | Select-Object -Index 1).Trim().ToLower()
if ($exSha -ne $ExSha256) { throw "Elixir zip SHA256 mismatch ($exSha). Aborting." }
Write-Host 'Elixir zip verified: exact size and SHA256.'
$ExDir = "${Drive}:\elixir"
$staging = "${Drive}:\elixir-staging"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
if (Test-Path $ExDir) { Remove-Item $ExDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $staging | Out-Null
& tar.exe -xf $ExZip -C $staging
if ($LASTEXITCODE -ne 0) { throw 'Elixir extraction failed.' }
$bat = Get-ChildItem $staging -Recurse -Filter 'elixir.bat' | Select-Object -First 1
if (-not $bat) { throw 'elixir.bat not found in the extracted zip.' }
Move-Item $bat.Directory.Parent.FullName $ExDir
Remove-Item $staging -Recurse -Force
$exBin = Join-Path $ExDir 'bin'
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$exBin*") {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$exBin", 'User')
}
$env:Path = "$env:Path;$exBin"
$exVer = & elixir --version
Write-Host "Elixir OK: $($exVer | Select-Object -Last 1)"

Write-Host 'PREREQUISITES OK: Git, Build Tools, WebView2, Rust, the Tauri CLI, Erlang/OTP and Elixir are installed.'
