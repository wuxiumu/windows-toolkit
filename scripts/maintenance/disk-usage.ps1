<#
.SYNOPSIS
    磁盘占用扫描（只读）
.DESCRIPTION
    输出各盘剩余空间、用户目录大文件夹、AppData 缓存大头、临时目录占用。
    只读扫描，不删除任何文件。
#>

Write-Host "`n========== 磁盘占用扫描（只读） ==========" -ForegroundColor Cyan

Write-Host "`n-- 各分区空间 --"
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    $pct = [math]::Round($_.FreeSpace/$_.Size*100,1)
    $color = if ($pct -lt 15) { 'Red' } elseif ($pct -lt 30) { 'Yellow' } else { 'White' }
    Write-Host ("  {0} 总{1}GB 剩余{2}GB ({3}%)" -f $_.DeviceID,
        [math]::Round($_.Size/1GB,0), [math]::Round($_.FreeSpace/1GB,0), $pct) -ForegroundColor $color
}

Write-Host "`n-- 用户目录一级大文件夹 (>1GB) --"
Get-ChildItem $env:USERPROFILE -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $s = (Get-ChildItem $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($s -gt 1GB) { Write-Host ("  {0,-20} {1} GB" -f $_.Name, [math]::Round($s/1GB,1)) }
}

Write-Host "`n-- AppData\Local 缓存大头 (>500MB) --"
Get-ChildItem "$env:LOCALAPPDATA" -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $s = (Get-ChildItem $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($s -gt 500MB) { Write-Host ("  {0,-30} {1} GB" -f $_.Name, [math]::Round($s/1GB,2)) }
}

Write-Host "`n-- 临时目录 --"
$tmp = (Get-ChildItem $env:TEMP -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
Write-Host ("  TEMP = {0} GB" -f [math]::Round($tmp/1GB,2))

Write-Host "`n-- Docker 磁盘占用（若已安装）--"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker system df 2>&1 | Select-Object -First 6
} else { Write-Host "  Docker 未安装" }

Write-Host "`n========== 扫描完毕（未改动任何文件） ==========" -ForegroundColor Cyan
