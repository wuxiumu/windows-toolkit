<#
.SYNOPSIS
    一键初始化 Windows 开发环境（可复现环境的核心脚本）
.DESCRIPTION
    按顺序部署：scoop -> buckets -> 六语言运行时 -> 验证。
    所有脚本幂等，可重复运行，不会破坏已有环境。
    无需管理员权限（除虚拟内存等系统级调整，本脚本不涉及）。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1
#>

$ErrorActionPreference = 'Continue'   # 单项失败不中断整体，最后汇总
$repo = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $repo 'install'

function Log($msg) { Write-Host "[bootstrap] $msg" -ForegroundColor Cyan }

Log "开始初始化 Windows 开发环境"
Log "仓库位置: $repo"

# 0. 前置检查
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "缺少 git，请先安装 Git 再运行本脚本。" -ForegroundColor Red
    exit 1
}
Log "前置检查通过"

# 1. scoop 本体
Log "步骤 1/4: 部署 scoop"
& "$scripts\setup-scoop.ps1"

# 2. 软件源
Log "步骤 2/4: 配置 scoop 软件源"
& "$scripts\setup-buckets.ps1"

# 3. 语言运行时（scoop 管理的四个）
$env:SCOOP = [Environment]::GetEnvironmentVariable('SCOOP','User')
$scoopCli = "$env:USERPROFILE\scoop\bin\scoop.ps1"
Log "步骤 3/4: 安装 scoop 管理的语言 (php/java/go/ruby)"
foreach ($app in @('php','temurin21-jdk','go','ruby')) {
    $installed = & powershell -NoProfile -ExecutionPolicy Bypass -File $scoopCli list $app 2>$null | Select-String "^\s*$app\s"
    if ($installed) { Log "$app 已安装，跳过" }
    else {
        Log "安装 $app ..."
        & powershell -NoProfile -ExecutionPolicy Bypass -File $scoopCli install $app
    }
}

# 4. fnm / uv
Log "步骤 4/4: 安装 fnm 与 uv"
& "$scripts\setup-fnm.ps1"
& "$scripts\setup-uv.ps1"

# 5. 验证
Log "初始化完成，运行健康检查..."
& "$repo\scripts\maintenance\env-check.ps1"

Write-Host "`n[bootstrap] 全部完成。请新开一个终端使 PATH 生效。" -ForegroundColor Green
