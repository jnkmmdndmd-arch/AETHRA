param(
    [string]$Output = "build/AETHRA-Wildbound.exe",
    [switch]$CopyToDesktop
)
$ErrorActionPreference = "Stop"
$GodotVersion = "4.7.2"
$GodotRoot = Join-Path $PSScriptRoot ".tools\godot-$GodotVersion"
$GodotExe = Join-Path $GodotRoot "Godot_v$GodotVersion-stable_win64.exe"
$GodotZip = Join-Path $GodotRoot "Godot_v$GodotVersion-stable_win64.exe.zip"
$TemplatesDir = Join-Path $env:APPDATA "Godot\export_templates\$GodotVersion.stable"
$TemplatesTpz = Join-Path $GodotRoot "Godot_v$GodotVersion-stable_export_templates.tpz"

New-Item -ItemType Directory -Force -Path $GodotRoot | Out-Null

if (-not (Test-Path $GodotExe)) {
    $url = "https://github.com/godotengine/godot-builds/releases/download/$GodotVersion-stable/Godot_v$GodotVersion-stable_win64.exe.zip"
    Write-Host "Downloading Godot $GodotVersion..."
    Invoke-WebRequest -Uri $url -OutFile $GodotZip
    Expand-Archive -Force -Path $GodotZip -DestinationPath $GodotRoot
}

if (-not (Test-Path $GodotExe)) {
    $found = Get-ChildItem -Path $GodotRoot -Filter "*.exe" -Recurse | Where-Object { $_.Name -like "Godot_v$GodotVersion-stable_win64.exe" } | Select-Object -First 1
    if ($found) { $GodotExe = $found.FullName }
}
if (-not (Test-Path $GodotExe)) { throw "Godot $GodotVersion Windows editor executable was not installed." }

$version = (& $GodotExe --version 2>$null | Out-String).Trim()
if (-not $version.StartsWith($GodotVersion)) { throw "Expected Godot $GodotVersion, detected: $version" }

if (-not (Test-Path (Join-Path $TemplatesDir "windows_release.x86_64.exe"))) {
    $url = "https://github.com/godotengine/godot-builds/releases/download/$GodotVersion-stable/Godot_v$GodotVersion-stable`_export_templates.tpz"
    Write-Host "Downloading Godot export templates..."
    Invoke-WebRequest -Uri $url -OutFile $TemplatesTpz

    New-Item -ItemType Directory -Force -Path $TemplatesDir | Out-Null
    $tempZip = Join-Path $GodotRoot "export_templates.zip"
    $tempExtract = Join-Path $GodotRoot "export_templates_extract"
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $tempExtract
    Copy-Item -Force $TemplatesTpz $tempZip
    Expand-Archive -Force -Path $tempZip -DestinationPath $tempExtract
    $templateSource = Join-Path $tempExtract "templates"
    if (-not (Test-Path $templateSource)) { throw "Export template archive has an unexpected layout." }
    Copy-Item -Force -Recurse (Join-Path $templateSource "*") $TemplatesDir
}

if (-not (Test-Path (Join-Path $TemplatesDir "windows_release.x86_64.exe"))) {
    throw "Windows x86_64 export template was not installed."
}

& $GodotExe --headless --path $PSScriptRoot --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot project validation failed." }

$absoluteOutput = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $Output))
$projectOutDir = Split-Path -Parent $absoluteOutput
if ([string]::IsNullOrWhiteSpace($projectOutDir)) { $projectOutDir = $PSScriptRoot }
New-Item -ItemType Directory -Force -Path $projectOutDir | Out-Null
Get-ChildItem -Path $projectOutDir -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse

& $GodotExe --headless --path $PSScriptRoot --export-release "Windows Desktop" $absoluteOutput
if ($LASTEXITCODE -ne 0) { throw "Windows export failed." }
if (-not (Test-Path $absoluteOutput -PathType Leaf)) { throw "AETHRA-Wildbound.exe was not created." }

$releaseFiles = @(Get-ChildItem -Path (Split-Path $absoluteOutput) -File)
if ($releaseFiles.Count -ne 1 -or $releaseFiles[0].FullName -ne $absoluteOutput) {
    throw "Standalone release check failed. Expected one EXE only."
}

$sha = (Get-FileHash -Algorithm SHA256 -Path $absoluteOutput).Hash.ToLowerInvariant()
$shaPath = Join-Path (Split-Path $absoluteOutput -Parent) "AETHRA-Wildbound.exe.sha256"
"$sha  AETHRA-Wildbound.exe" | Set-Content -Encoding ascii $shaPath

if ($CopyToDesktop) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    Copy-Item -Force $absoluteOutput (Join-Path $desktop "AETHRA-Wildbound.exe")
}

Write-Host ""
Write-Host "AETHRA-Wildbound Windows release ready:"
Write-Host $absoluteOutput
Write-Host "SHA256: $sha"
