<#
.SYNOPSIS
    手动部署 scoop（绕开失效的官方安装脚本 get.scoop.sh）
.DESCRIPTION
    在国内网络下 get.scoop.sh 常常不通。本脚本直接下载 scoop 仓库部署，
    走 gh-proxy 中转，并修复 shim.exe 缺失问题。幂等：已安装则跳过。
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$scoopDir = "$env:USERPROFILE\scoop"
$repo = 'https://gh-proxy.com/https://github.com/scoopinstaller/scoop/archive/refs/heads/master.zip'

function Log($m){ Write-Host "[setup-scoop] $m" -ForegroundColor Cyan }

if (Test-Path "$scoopDir\bin\scoop.ps1") {
    Log "scoop 已存在，跳过部署"
} else {
    Log "下载 scoop 仓库..."
    $zip = Join-Path $env:TEMP 'scoop-master.zip'
    $extract = Join-Path $env:TEMP 'scoop-extract'
    Invoke-WebRequest $repo -OutFile $zip -UseBasicParsing
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force -Confirm:$false }
    Expand-Archive $zip -DestinationPath $extract -Force

    Log "部署到 $scoopDir ..."
    New-Item $scoopDir -ItemType Directory -Force | Out-Null
    Copy-Item "$extract\Scoop-master\*" $scoopDir -Recurse -Force
    'shims','apps','buckets','cache','persist' | ForEach-Object {
        New-Item "$scoopDir\$_" -ItemType Directory -Force | Out-Null
    }

    # 创建命令入口 shim
    $shimPs1 = @'
$path = Join-Path $PSScriptRoot "..\bin\scoop.ps1"
if ($MyInvocation.ExpectingInput) { $input | & $path @args } else { & $path @args }
exit $LASTEXITCODE
'@
    [System.IO.File]::WriteAllText("$scoopDir\shims\scoop.ps1", $shimPs1)
    $shimCmd = @"
@echo off
powershell -noprofile -ex unrestricted -file "$scoopDir\bin\scoop.ps1" %*
"@
    [System.IO.File]::WriteAllText("$scoopDir\shims\scoop.cmd", $shimCmd)
}

# SCOOP 环境变量（关键）
if ([Environment]::GetEnvironmentVariable('SCOOP','User') -ne $scoopDir) {
    [Environment]::SetEnvironmentVariable('SCOOP', $scoopDir, 'User')
    Log "已设置 SCOOP 环境变量"
}
$env:SCOOP = $scoopDir

# PATH
$up = [Environment]::GetEnvironmentVariable('Path','User')
if ($up -notlike "*$scoopDir\shims*") {
    [Environment]::SetEnvironmentVariable('Path', "$up;$scoopDir\shims", 'User')
    Log "已把 scoop\shims 加入用户 PATH"
}

# 修复 shim.exe 缺失
$shimSrc = "$scoopDir\supporting\shims\scoopcs\shim.exe"
$shimDst = "$scoopDir\apps\scoop\current\supporting\shims\kiennq"
if ((Test-Path $shimSrc) -and -not (Test-Path "$shimDst\shim.exe")) {
    New-Item $shimDst -ItemType Directory -Force | Out-Null
    Copy-Item $shimSrc "$shimDst\shim.exe" -Force
    Log "已补齐 shim.exe"
}

Log "scoop 部署完成。新开终端后可用 scoop 命令。"
