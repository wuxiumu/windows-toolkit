<#
.SYNOPSIS
    开发环境健康检查（只读）
.DESCRIPTION
    逐一验证六语言命令是否可用并输出版本，检查 scoop 环境变量与 PATH 配置。
    不修改任何东西。
#>

$env:SCOOP = [Environment]::GetEnvironmentVariable('SCOOP','User')
$scoopShims = "$env:USERPROFILE\scoop\shims"
$env:Path = "$scoopShims;" + [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')

Write-Host "`n========== 开发环境健康检查 ==========" -ForegroundColor Cyan

function Check($name, $cmd, $args) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) {
        $v = & $cmd @args 2>&1 | Select-Object -First 1
        Write-Host ("  [OK]   {0,-10} {1}" -f $name, $v)
    } else {
        Write-Host ("  [MISS] {0,-10} 命令未找到" -f $name) -ForegroundColor Red
    }
}

Write-Host "`n-- 语言运行时 --"
Check 'Python' 'python' @('--version')
Check 'Node' 'node' @('--version')
Check 'PHP' 'php' @('--version')
Check 'Java' 'java' @('-version')
Check 'Go' 'go' @('version')
Check 'Ruby' 'ruby' @('--version')

Write-Host "`n-- 版本管理工具 --"
Check 'uv' 'uv' @('--version')
Check 'fnm' 'fnm' @('--version')
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopCli = "$env:USERPROFILE\scoop\bin\scoop.ps1"
    $v = & powershell -NoProfile -ExecutionPolicy Bypass -File $scoopCli --version 2>&1 | Where-Object { $_ -match '^v\d' } | Select-Object -First 1
    Write-Host ("  [OK]   {0,-10} {1}" -f 'scoop', $v)
} else { Write-Host "  [MISS] scoop     命令未找到" -ForegroundColor Red }

Write-Host "`n-- 环境配置 --"
$scoopEnv = [Environment]::GetEnvironmentVariable('SCOOP','User')
Write-Host ("  SCOOP = {0}" -f $(if($scoopEnv){$scoopEnv}else{'未设置 (警告)'}))
$up = [Environment]::GetEnvironmentVariable('Path','User')
Write-Host ("  PATH 含 scoop\shims = {0}" -f ($up -match 'scoop\\shims'))
$profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
Write-Host ("  fnm Profile 存在 = {0}" -f (Test-Path $profile))

Write-Host "`n========== 检查完毕 ==========" -ForegroundColor Cyan
Write-Host "注：若命令显示 MISS，请先新开一个终端再试。" -ForegroundColor DarkGray
