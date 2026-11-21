<#
.SYNOPSIS
    安装 uv 并用它管理 Python
.DESCRIPTION
    uv 是 Python 版本与包管理器，速度远超 pip。本脚本通过 winget 安装 uv，
    并可选安装一个常用 Python 版本。幂等。
#>

function Log($m){ Write-Host "[setup-uv] $m" -ForegroundColor Cyan }
$uv = Get-Command uv -ErrorAction SilentlyContinue

if ($uv) {
    Log "uv 已安装: $($uv.Source)"
} else {
    Log "通过 winget 安装 uv..."
    winget install --id astral-sh.uv --exact --accept-source-agreements --accept-package-agreements 2>&1 | Select-Object -Last 5
    $env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + $env:Path
    $uv = Get-Command uv -ErrorAction SilentlyContinue
}

if ($uv) {
    Log "uv 版本: $(uv --version)"
    Log "可用 Python 版本:"
    uv python list 2>&1 | Select-Object -First 6
    Log "提示: 用 'uv python install 3.11' 安装指定版本，'uv python use 3.11' 切换"
} else {
    Write-Host "uv 未找到，请检查 winget 安装结果" -ForegroundColor Red
}
Log "uv 配置完成"
