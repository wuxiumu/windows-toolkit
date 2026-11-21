# 六语言版本管理速查

统一原则：**装版本 → 切版本 → 列版本**，全部命令行完成，不修改系统全局 PATH（工具自动管理 shim）。

---

## Python —— uv

```powershell
uv python install 3.11        # 安装指定版本
uv python use 3.11            # 切换当前使用的版本
uv python list                # 列出所有可用/已装版本
uv python uninstall 3.11      # 卸载版本
```

uv 同时是包管理器：`uv add <pkg>`、`uv sync`、`uv run`，速度远超 pip。

## Node.js —— fnm

```powershell
fnm install 22                # 安装 Node 22
fnm use 22                    # 切换到 22（当前会话）
fnm default 22                # 设为默认版本
fnm list                      # 列出已装版本
fnm uninstall 22              # 卸载
```

> **本机特别说明**：fnm 的官方初始化用了 `Invoke-Expression`，在受限环境下被禁用，因此采用**静态 PATH** 方案——在 PowerShell Profile 里直接写入当前 Node 路径。
> Profile 位置：`$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
> 若 `fnm use` 后新窗口未生效，需同步修改该 Profile 中的 PATH 行。

## PHP / Java / Go / Ruby —— scoop

```powershell
scoop list                          # 列出所有已装软件
scoop install php@8.3               # 安装指定版本（清单支持时）
scoop reset php@8.3                 # 切换到已装的某个版本
scoop update php                    # 升级到清单最新版
scoop uninstall php                 # 卸载
scoop info php                      # 查看软件详情
```

**可用版本查询：**
```powershell
scoop search temurin17-jdk    # 搜 JDK 版本
scoop info temurin-lts-jdk    # 看 LTS 版本详情
```

**JDK 版本选择建议**：日常开发用 Temurin 21 LTS；需要新特性可装 25 LTS；生产对齐用项目指定版本。

---

## 通用注意事项

1. **新开终端**：PATH 变更在新开的 PowerShell 中才生效。
2. **多版本共存**：scoop 的 `reset` 只是切换 shim 指向，多个版本可同时安装、随时切换。
3. **不污染系统**：所有版本经工具管理，不要用安装包覆盖系统 PATH，避免冲突。
4. **健康检查**：`scripts/maintenance/env-check.ps1` 会逐一验证六个命令是否可用。
