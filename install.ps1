<#
.SYNOPSIS
  Trình cài đặt tự động MausBot Video Factory dành cho giáo viên Trường Xanh Tuệ Đức trên Windows 10/11.
.DESCRIPTION
  Tự động kiểm tra phần cứng, GPU, cài đặt và sao chép FFmpeg vào thư mục cài đặt độc lập,
  thiết lập môi trường ảo Python venv với đầy đủ thư viện đồ họa & TTS, tạo file config.json cấu hình hệ thống
  và kích hoạt skill xtd-video-factory cho OpenMausBot mà giáo viên không phải gõ lệnh phức tạp.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File install.ps1
#>
param(
    [switch]$Silent,
    [string]$TargetDir = "$env:LOCALAPPDATA\MausBotVideoFactory"
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PSScriptRoot_Safe = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogFile = Join-Path $PSScriptRoot_Safe "install.log"

function Log($msg, $color = "Cyan") {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$time] $msg"
    Write-Host $line -ForegroundColor $color
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function LogSuccess($msg) { Log "✅ $msg" "Green" }
function LogWarn($msg)    { Log "⚠️ $msg" "Yellow" }
function LogError($msg)   { Log "❌ $msg" "Red"; exit 1 }

Clear-Host
Log "==================================================================" "Green"
Log "   MAUSBOT VIDEO FACTORY — TRÌNH CÀI ĐẶT TỰ ĐỘNG CHO GIÁO VIÊN   " "Green"
Log "         TRƯỜNG XANH TUỆ ĐỨC (TRUONGXANH.EDU.VN)                 " "Green"
Log "==================================================================" "Green"

# 1. TẠO THƯ MỤC CÀI ĐẶT ĐỘC LẬP
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
$binDir = Join-Path $TargetDir "bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
Log "1. Thư mục cài đặt độc lập: $TargetDir"

# 2. KIỂM TRA PHẦN CỨNG & DUNG LƯỢNG Ổ ĐĨA
Log "2. Kiểm tra cấu hình máy tính..."
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$disk = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 } | Select-Object -First 1
$diskFreeGB = [math]::Round($disk.Free / 1GB, 1)

Log "   • Hệ điều hành: $($os.Caption) (RAM khả dụng: $freeGB GB)"
Log "   • Ổ đĩa $($disk.Name): Dung lượng trống: $diskFreeGB GB"

if ($diskFreeGB -lt 5) {
    LogError "Ổ đĩa $($disk.Name) chỉ còn trống $diskFreeGB GB (yêu cầu tối thiểu 5 GB trống để cài đặt và dựng video)."
}

$gpus = Get-CimInstance Win32_VideoController
$hasNvidia = $false
foreach ($gpu in $gpus) {
    Log "   • Card màn hình: $($gpu.Name)"
    if ($gpu.Name -match "NVIDIA|RTX|GTX") {
        $hasNvidia = $true
    }
}

if ($hasNvidia) {
    LogSuccess "Phát hiện GPU NVIDIA -> Kích hoạt tăng tốc dựng video bằng phần cứng (CUDA/NVENC)."
} else {
    LogWarn "Không phát hiện GPU NVIDIA -> Hệ thống sẽ chạy ở chế độ CPU."
}

# 3. THIẾT LẬP FFMPEG & FFPROBE VÀO THƯ MỤC BIN ĐỘC LẬP
Log "3. Thiết lập bộ công cụ FFmpeg độc lập trong $binDir..."
$targetFFmpeg = Join-Path $binDir "ffmpeg.exe"
$targetFFprobe = Join-Path $binDir "ffprobe.exe"

if (-not (Test-Path $targetFFmpeg) -or -not (Test-Path $targetFFprobe)) {
    $sysFFmpeg = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
    $sysFFprobe = Get-Command "ffprobe" -ErrorAction SilentlyContinue

    if ($sysFFmpeg -and $sysFFprobe) {
        Log "   • Sao chép FFmpeg từ hệ thống vào thư mục cài đặt độc lập..."
        Copy-Item -Path $sysFFmpeg.Source -Destination $targetFFmpeg -Force
        Copy-Item -Path $sysFFprobe.Source -Destination $targetFFprobe -Force
    } else {
        Log "   • Chưa có FFmpeg, đang tự động cài qua winget..."
        if (Get-Command "winget" -ErrorAction SilentlyContinue) {
            winget install --id Gyan.FFmpeg -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
            $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
            $newFFmpeg = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
            $newFFprobe = Get-Command "ffprobe" -ErrorAction SilentlyContinue
            if ($newFFmpeg -and $newFFprobe) {
                Copy-Item -Path $newFFmpeg.Source -Destination $targetFFmpeg -Force
                Copy-Item -Path $newFFprobe.Source -Destination $targetFFprobe -Force
            }
        }
    }
}

if (Test-Path $targetFFmpeg) {
    LogSuccess "FFmpeg độc lập sẵn sàng tại: $targetFFmpeg"
} else {
    LogError "Không thể thiết lập FFmpeg độc lập tại $binDir."
}

# 4. KIỂM TRA PYTHON VÀ THIẾT LẬP MÔI TRƯỜNG ẢO PYTHON VENV
Log "4. Kiểm tra Python và thiết lập môi trường ảo..."
$pyCmd = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pyVer = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ([double]$pyVer -ge 3.10) { $pyCmd = "python" }
}
if (-not $pyCmd -and (Get-Command "py" -ErrorAction SilentlyContinue)) {
    $pyCmd = "py"
}

if (-not $pyCmd) {
    LogWarn "Chưa có Python 3.10+. Đang tự động cài qua winget..."
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install --id Python.Python.3.11 -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        $pyCmd = "python"
    }
}

$venvDir = Join-Path $TargetDir ".venv"
$venvPython = Join-Path $venvDir "Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Log "   • Tạo môi trường ảo tại $venvDir..."
    & $pyCmd -m venv $venvDir
}

if (Test-Path $venvPython) {
    LogSuccess "Python venv sẵn sàng: $venvPython"
    Log "   • Đang cài đặt/cập nhật thư viện: Pillow, numpy, scipy, vieneu..."
    & $venvPython -m pip install -q --upgrade pip
    & $venvPython -m pip install -q pillow numpy scipy vieneu
} else {
    LogError "Không thể tạo Python venv tại $venvDir."
}

# 5. XUẤT TỆP CẤU HÌNH CONFIG.JSON
$configFile = Join-Path $TargetDir "config.json"
$config = @{
    "target_dir" = $TargetDir
    "python"     = $venvPython
    "ffmpeg"     = $targetFFmpeg
    "ffprobe"    = $targetFFprobe
    "installed_at" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "config_type" = "local_zero_cost"
} | ConvertTo-Json -Depth 3

Set-Content -Path $configFile -Value $config -Encoding UTF8
LogSuccess "Đã tạo tệp cấu hình độc lập: $configFile"

# 6. KÍCH HOẠT SKILL CHO OPENMAUSBOT
Log "6. Kích hoạt Skill xtd-video-factory cho MausBot..."
$openMausSkillsDir = "$env:USERPROFILE\.openmausbot\skills\xtd-video-factory"
$skillSource = Join-Path $PSScriptRoot_Safe "skill"

try {
    New-Item -ItemType Directory -Force -Path $openMausSkillsDir | Out-Null
    Copy-Item -Path (Join-Path $skillSource "*") -Destination $openMausSkillsDir -Recurse -Force
    LogSuccess "Đã gắn thành công Skill vào OpenMausBot: $openMausSkillsDir"
} catch {
    LogWarn "Không thể chép skill vào ${openMausSkillsDir}: $($_.Exception.Message)"
}

# 7. HOÀN TẤT
Log "==================================================================" "Green"
Log "✅ CÀI ĐẶT THÀNH CÔNG MAUSBOT VIDEO FACTORY!" "Green"
Log "   • Cấu hình đã kích hoạt: Cấu hình 1 (Local / Miễn phí 100%)" "Green"
Log "   • Python: $venvPython" "Green"
Log "   • FFmpeg: $targetFFmpeg" "Green"
Log "   • Config: $configFile" "Green"
Log "==================================================================" "Green"
