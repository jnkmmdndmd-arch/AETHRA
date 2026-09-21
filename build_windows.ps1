param([string]$Godot = "godot", [string]$Output = "build/AETHRA-Wildbound.exe", [switch]$CopyToDesktop)
$ErrorActionPreference = "Stop"

$outDir = Split-Path -Parent $Output
if ([string]::IsNullOrWhiteSpace($outDir)) { $outDir = "." }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$godotCommand = Get-Command $Godot -ErrorAction SilentlyContinue
if (-not $godotCommand) { throw "Godot 4.7.2 is required and was not found on PATH." }

$version = (& $Godot --version 2>$null | Out-String).Trim()
if (-not $version.StartsWith("4.7.2")) { throw "Godot 4.7.2 is required. Detected: $version" }

$templateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$templateFile = Join-Path $templateRoot "windows_release_x86_64.exe"
if (-not (Test-Path $templateFile -PathType Leaf)) { throw "Godot 4.7.2 Windows export template is missing: $templateFile" }

# Validate/import the project before exporting.
& $Godot --headless --path . --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot project validation failed." }

# Always export into a clean directory so stale files cannot invalidate the one-file release.
Get-ChildItem -Path $outDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

& $Godot --headless --path . --export-release "Windows Desktop" $Output
if ($LASTEXITCODE -ne 0) { throw "Windows export failed." }
if (-not (Test-Path $Output -PathType Leaf)) { throw "AETHRA-Wildbound.exe was not created." }

$resolvedOutput = (Resolve-Path $Output).Path
$files = @(Get-ChildItem -Path $outDir -File)
if ($files.Count -ne 1 -or $files[0].FullName -ne $resolvedOutput) {
    $names = ($files | Select-Object -ExpandProperty Name) -join ", "
    throw "Standalone release failed: expected exactly one file ($([IO.Path]::GetFileName($resolvedOutput))), found: $names"
}

$sha = (Get-FileHash -Algorithm SHA256 -Path $Output).Hash.ToLowerInvariant()
$shaPath = Join-Path (Split-Path -Parent $outDir) "AETHRA-Wildbound.exe.sha256"
"$sha  $([IO.Path]::GetFileName($Output))" | Set-Content -Encoding ascii $shaPath

if ($CopyToDesktop) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path $desktop)) { throw "Windows Desktop folder could not be resolved." }
    Copy-Item -Force -Path $Output -Destination (Join-Path $desktop "AETHRA-Wildbound.exe")
}

Write-Host "Standalone release ready: $resolvedOutput"
Write-Host "SHA256: $sha"
if ($CopyToDesktop) { Write-Host "Desktop copy: $([IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "AETHRA-Wildbound.exe"))" }
