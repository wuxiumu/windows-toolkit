# 网络受限环境下的 scoop 配置经验

> 在国内网络下，scoop 官方安装脚本和 GitHub 直连常常失败。本文记录已验证的绕行方案，供复现和排错。

---

## 一、问题现象与根因

| 现象 | 根因 |
|---|---|
| `get.scoop.sh` 报「基础连接已关闭」 | 该短域名在本地网络不通 |
| git 拉 GitHub 报 `CONNECT tunnel failed 502` | 环境代理对 github.com 的 CONNECT 隧道不通 |
| git 报 `socks5h://127.0.0.1:11080` 连不上 | 用户 gitconfig 里配置了未启动的本地代理 |
| scoop 安装报 `URL is not valid` | bucket 清单里的 GitHub 下载链接被 scoop 判无效 |

**关键结论**：`github.com` 直连不通，但**代理中转站 `gh-proxy.com` 可用**，`windows.php.net` 等软件源也可用。所有 GitHub 相关操作都走中转。

---

## 二、手动部署 scoop（绕开失效安装脚本）

官方 `get.scoop.sh` 的本质是下载安装脚本再执行。既然它不通，直接下载 scoop 仓库手动部署：

```powershell
# 1. 下载 scoop 仓库（走中转）
Invoke-WebRequest 'https://gh-proxy.com/https://github.com/scoopinstaller/scoop/archive/refs/heads/master.zip' -OutFile scoop.zip

# 2. 解压到用户目录
Expand-Archive scoop.zip -DestinationPath $env:TEMP
Copy-Item "$env:TEMP\Scoop-master\*" "$env:USERPROFILE\scoop" -Recurse -Force

# 3. 建标准目录
'shims','apps','buckets','cache','persist' | ForEach-Object {
  New-Item "$env:USERPROFILE\scoop\$_" -ItemType Directory -Force | Out-Null
}

# 4. 设 SCOOP 环境变量（必须，否则 scoop 会把根目录误判为 C:\）
[Environment]::SetEnvironmentVariable('SCOOP', "$env:USERPROFILE\scoop", 'User')

# 5. 把 shims 加入用户 PATH
$p = [Environment]::GetEnvironmentVariable('Path','User')
[Environment]::SetEnvironmentVariable('Path', "$p;$env:USERPROFILE\scoop\shims", 'User')
```

`scripts/install/setup-scoop.ps1` 已封装以上步骤。

---

## 三、shim.exe 缺失修复

scoop 默认用 kiennq 版 shim，但仓库里该二进制可能缺失，导致装软件时报 `shim.exe 找不到`。修复：

```powershell
$src = "$env:USERPROFILE\scoop\supporting\shims\scoopcs\shim.exe"
$dst = "$env:USERPROFILE\scoop\apps\scoop\current\supporting\shims\kiennq"
New-Item $dst -ItemType Directory -Force | Out-Null
Copy-Item $src "$dst\shim.exe" -Force
```

之后对已装软件执行一次 `scoop reset <包名>` 重建命令入口即可。

---

## 四、添加软件源（走中转）

```powershell
$buckets = @{
  main = 'https://gh-proxy.com/https://github.com/ScoopInstaller/Main.git'
  java = 'https://gh-proxy.com/https://github.com/ScoopInstaller/Java.git'
}
foreach ($name in $buckets.Keys) {
  git clone --depth 1 $buckets[$name] "$env:USERPROFILE\scoop\buckets\$name"
  git -C "$env:USERPROFILE\scoop\buckets\$name" remote set-url origin $buckets[$name]
}
```

---

## 五、修复清单里的失效下载链接

有些包（如 `temurin21-jdk`、`ruby`）的清单 URL 会被 scoop 判无效。把 GitHub 下载链接改写为中转地址：

```powershell
# 以 temurin21-jdk 为例
$f = "$env:USERPROFILE\scoop\buckets\java\bucket\temurin21-jdk.json"
$raw = Get-Content $f -Raw
$fixed = $raw -replace 'https://github\.com/', 'https://gh-proxy.com/https://github.com/'
[System.IO.File]::WriteAllText($f, $fixed)
```

> ⚠️ 这样改会导致 `scoop update` 时该清单被远程覆盖，需要重改。这是网络受限环境的权衡；网络通畅的机器不必做此改写。

---

## 六、关于用户自己的 git 代理

用户 gitconfig 里可能配置了指向本地代理（如 `socks5h://127.0.0.1:11080`）的 github 规则。**不要随意删除**——那是用户自有配置，代理软件启动时有效。scoop 的 bucket 已通过改用中转 remote 绕开此问题，两者互不干扰。

如需临时绕过做测试：
```powershell
git -c 'http.https://github.com/.proxy=' ls-remote https://github.com/xxx
```

---

## 七、环境代理速查

- 环境变量 `HTTP_PROXY` / `HTTPS_PROXY` = `http://127.0.0.1:<端口>`（由运行环境注入，端口可能变化）
- 可用中转：`gh-proxy.com`、`windows.php.net`、`api.github.com`
- 不通：github.com 直连（502）、get.scoop.sh
