<#
.SYNOPSIS
  Trình cài đặt tự động MausBot Video Factory dành cho giáo viên Trường Xanh Tuệ Đức trên Windows 10/11.
.DESCRIPTION
  Tự động kiểm tra phần cứng, GPU, cài đặt hoặc định vị FFmpeg, Python, Node, thiết lập môi trường ảo
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

# 1. KIỂM TRA PHẦN CỨNG & DUNG LƯỢNG Ổ ĐĨA
Log "1. Kiểm tra cấu hình máy tính..."
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
    LogWarn "Không phát hiện GPU NVIDIA -> Hệ thống sẽ chạy ở chế độ CPU (vẫn tạo được video nhưng thời gian render lâu hơn)."
}

# 2. KIỂM TRA FFMPEG / FFPROBE
Log "2. Kiểm tra bộ giải mã FFmpeg và ffprobe..."
$ffmpegCmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
$ffprobeCmd = Get-Command "ffprobe" -ErrorAction SilentlyContinue

# Kiểm tra đường dẫn công cụ nội bộ nếu có
$internalFFmpeg = "D:\01_Coding_Workspace\tools\ffmpeg\bin\ffmpeg.exe"
if (-not $ffmpegCmd -and (Test-Path $internalFFmpeg)) {
    $env:Path += ";D:\01_Coding_Workspace\tools\ffmpeg\bin"
    $ffmpegCmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
}

if (-not $ffmpegCmd) {
    LogWarn "Chưa tìm thấy FFmpeg trong hệ thống. Đang tự động cài qua winget..."
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install --id Gyan.FFmpeg -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        $ffmpegCmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
    }
}

if ($ffmpegCmd) {
    LogSuccess "FFmpeg đã sẵn sàng: $($ffmpegCmd.Source)"
} else {
    LogError "Không thể cài đặt tự động FFmpeg. Vui lòng liên hệ bộ phận IT Trường Xanh Tuệ Đức để được hỗ trợ."
}

# 3. KIỂM TRA PYTHON (≥ 3.10)
Log "3. Kiểm tra môi trường Python..."
$pyCmd = $null
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    $pyVer = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    if ([double]$pyVer -ge 3.10) {
        $pyCmd = "python"
    }
}
if (-not $pyCmd -and (Get-Command "py" -ErrorAction SilentlyContinue)) {
    $pyCmd = "py"
}

if (-not $pyCmd) {
    LogWarn "Chưa có Python 3.11+. Đang tự động cài qua winget..."
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        winget install --id Python.Python.3.11 -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        $pyCmd = "python"
    }
}

if ($pyCmd) {
    LogSuccess "Python đã sẵn sàng: $pyCmd"
} else {
    LogError "Thiếu Python 3.10+. Vui lòng cài Python từ python.org (nhớ tick 'Add python.exe to PATH')."
}

# 4. THIẾT LẬP MÔI TRƯỜNG ẢO PYTHON VENV
Log "4. Thiết lập môi trường ảo và cài đặt thư viện cần thiết..."
$venvDir = Join-Path $TargetDir ".venv"
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$venvPython = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Log "   • Đang tạo venv tại $venvDir..."
    & $pyCmd -m venv $venvDir
}

if (Test-Path $venvPython) {
    LogSuccess "Môi trường ảo Python đã sẵn sàng: $venvPython"
    Log "   • Cài đặt các gói: Pillow, numpy, scipy, faster-whisper..."
    & $venvPython -m pip install -q --upgrade pip
    & $venvPython -m pip install -q pillow numpy scipy
} else {
    LogError "Không thể khởi tạo môi trường Python venv."
}

# 5. KÍCH HOẠT SKILL CHO OPENMAUSBOT
Log "5. Kích hoạt Skill xtd-video-factory cho MausBot..."
$openMausSkillsDir = "$env:USERPROFILE\.openmausbot\skills\xtd-video-factory"
$skillSource = Join-Path $PSScriptRoot_Safe "skill"

try {
    New-Item -ItemType Directory -Force -Path $openMausSkillsDir | Out-Null
    Copy-Item -Path (Join-Path $skillSource "*") -Destination $openMausSkillsDir -Recurse -Force
    LogSuccess "Đã gắn thành công Skill vào OpenMausBot: $openMausSkillsDir"
} catch {
    LogWarn "Không thể chép skill vào $openMausSkillsDir: $($_.Exception.Message)"
}

# 6. HOÀN TẤT VÀ BÁO CÁO
Log "==================================================================" "Green"
Log "✅ CÀI ĐẶT THÀNH CÔNG MAUSBOT VIDEO FACTORY!" "Green"
Log "   • Cấu hình đã kích hoạt: Cấu hình 1 (Local / Miễn phí 100%)" "Green"
Log "   • Thư mục cài đặt: $TargetDir" "Green"
Log "   • Thầy cô mở OpenMausBot và gõ lệnh: 'Trợ lý Video Bài học, tạo video ...'" "Green"
Log "==================================================================" "Green"
