<#
.SYNOPSIS
    安装 fnm 并配置 Node LTS
.DESCRIPTION
    通过 winget 安装 fnm，装 Node LTS，并在 PowerShell Profile 写入静态 PATH。
    注：官方 fnm 初始化用 Invoke-Expression，受限环境被禁，故用静态 PATH 方案。
#>

function Log($m){ Write-Host "[setup-fnm] $m" -ForegroundColor Cyan }
$fnmExe = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Schniz.fnm_Microsoft.Winget.Source_8wekyb3d8bbwe\fnm.exe"

if (Test-Path $fnmExe) {
    Log "fnm 已安装，跳过"
} else {
    Log "通过 winget 安装 fnm..."
    winget install --id Schniz.fnm --exact --accept-source-agreements --accept-package-agreements 2>&1 | Select-Object -Last 5
    # 尝试解析实际安装路径
    if (-not (Test-Path $fnmExe)) {
        $found = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter fnm.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $fnmExe = $found.FullName }
    }
}

$env:FNM_DIR = "$env:APPDATA\fnm"
if (Test-Path $fnmExe) {
    Log "安装 Node LTS..."
    & $fnmExe install --lts 2>&1 | Select-Object -Last 3

    # 写静态 PATH 到 Profile
    $profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $dir = Split-Path $profile
    if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
    $nodeBase = "$env:APPDATA\fnm\node-versions"
    $latest = Get-ChildItem $nodeBase -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($latest) {
        $content = @(
            '# fnm / Node.js (static PATH)',
            "`$env:FNM_DIR = `"$env:APPDATA\fnm`"",
            "`$env:PATH = `"$($latest.FullName)\installation;`" + `$env:PATH"
        ) -join "`n"
        $existing = if (Test-Path $profile) { Get-Content $profile -Raw } else { '' }
        if ($existing -notmatch 'FNM_DIR') {
            Add-Content $profile $content -Encoding utf8
            Log "已写入 Node PATH 到 PowerShell Profile"
        }
    }
} else {
    Write-Host "fnm 未找到，请检查 winget 安装结果" -ForegroundColor Red
}
Log "fnm 配置完成（新开终端生效）"
