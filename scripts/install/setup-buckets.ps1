<#
.SYNOPSIS
    添加 scoop 软件源并修复失效下载链接
.DESCRIPTION
    走 gh-proxy 中转克隆 main/java 两个 bucket，并把清单里被判无效的
    GitHub 下载链接改写为中转地址。幂等。
#>

$env:SCOOP = "$env:USERPROFILE\scoop"
$env:GIT_TERMINAL_PROMPT = '0'
$buckets = @{
    main = 'https://gh-proxy.com/https://github.com/ScoopInstaller/Main.git'
    java = 'https://gh-proxy.com/https://github.com/ScoopInstaller/Java.git'
}
# 需要修复下载链接的包（清单路径 bucket / 包名）
$fixUrls = @(
    @{ bucket='java'; name='temurin21-jdk' },
    @{ bucket='main'; name='ruby' }
)

function Log($m){ Write-Host "[setup-buckets] $m" -ForegroundColor Cyan }

foreach ($name in $buckets.Keys) {
    $dir = "$env:SCOOP\buckets\$name"
    if (Test-Path "$dir\.git") {
        Log "$name bucket 已存在，跳过克隆"
    } else {
        Log "克隆 $name bucket..."
        git clone --depth 1 $buckets[$name] $dir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "  $name 克隆失败" -ForegroundColor Red; continue }
        git -C $dir remote set-url origin $buckets[$name] 2>&1 | Out-Null
    }
}

Log "修复失效下载链接..."
foreach ($f in $fixUrls) {
    $path = "$env:SCOOP\buckets\$($f.bucket)\bucket\$($f.name).json"
    if (Test-Path $path) {
        $raw = Get-Content $path -Raw
        if ($raw -match 'https://github\.com/' -and $raw -notmatch 'gh-proxy\.com/https://github') {
            $fixed = $raw -replace 'https://github\.com/', 'https://gh-proxy.com/https://github.com/'
            [System.IO.File]::WriteAllText($path, $fixed)
            Log "  已修复 $($f.name).json"
        } else {
            Log "  $($f.name).json 无需修复"
        }
    }
}
Log "软件源配置完成"
