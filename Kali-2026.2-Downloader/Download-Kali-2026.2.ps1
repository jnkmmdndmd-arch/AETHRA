$ErrorActionPreference = 'Stop'

$FileName = 'kali-linux-2026.2-installer-amd64.iso'
$DownloadUrl = "https://cdimage.kali.org/current/$FileName"
$ChecksumsUrl = 'https://cdimage.kali.org/current/SHA256SUMS'

Write-Host ''
Write-Host '=== Kali Linux 2026.2 ISO Downloader ===' -ForegroundColor Cyan
Write-Host ''

$drive = Read-Host 'Enter the USB/download drive letter (default: E)'
if ([string]::IsNullOrWhiteSpace($drive)) { $drive = 'E' }
$drive = $drive.Trim().TrimEnd(':').ToUpper()
$root = $drive + ':\'

if (-not (Test-Path $root)) { throw "Drive $root was not found." }
$target = Join-Path $root $FileName
$checksumFile = Join-Path $root 'SHA256SUMS'
$freeGB = [math]::Round(((Get-PSDrive -Name $drive).Free / 1GB), 2)

Write-Host ('Free space on ' + $root + ' : ' + $freeGB + ' GB') -ForegroundColor Yellow
if ($freeGB -lt 6) { throw 'Not enough free space. Keep at least 6 GB free.' }

Write-Host ('Downloading to: ' + $target) -ForegroundColor Green
& curl.exe -L --fail --retry 8 --retry-all-errors --progress-bar -o $target $DownloadUrl
if ($LASTEXITCODE -ne 0) { throw 'The ISO download failed.' }

Write-Host 'Downloading official SHA256 checksums...' -ForegroundColor Cyan
& curl.exe -L --fail --retry 5 --retry-all-errors --silent --show-error -o $checksumFile $ChecksumsUrl
if ($LASTEXITCODE -ne 0) { throw 'Could not download SHA256SUMS.' }

$line = Select-String -Path $checksumFile -Pattern ([regex]::Escape($FileName)) | Select-Object -First 1
if (-not $line) { throw ('Could not find ' + $FileName + ' in SHA256SUMS.') }
$expected = ($line.Line -split '\s+')[0].ToLower()
Write-Host 'Verifying SHA256...' -ForegroundColor Cyan
$actual = (Get-FileHash -Algorithm SHA256 -Path $target).Hash.ToLower()
if ($actual -ne $expected) { throw 'SHA256 verification FAILED. Do not use this ISO.' }

Write-Host ''
Write-Host 'SUCCESS: Kali 2026.2 ISO downloaded and verified.' -ForegroundColor Green
Write-Host ('ISO: ' + $target)
Read-Host 'Press Enter to close'