---
name: dev-env-inventory
display_name: 本机开发环境清单
display_name_en: Local Dev Environment Inventory
description: 当用户询问本机安装了哪些开发工具/语言版本、某语言的版本管理方式、工具安装在哪里、如何切换语言版本、如何安装新版本，或需要查阅本机开发环境配置与网络代理要点时使用。提供 meiyo 这台 Windows 11 机器的完整开发环境清单与命令行速查，不执行任何安装或删除操作，仅作事实查询与命令指引。
description_zh: 查询本机开发工具清单、语言版本、安装路径、版本切换命令、scoop/fnm/uv 用法、网络代理配置要点。涉及"装了什么""怎么切版本""工具在哪"等问题时使用。
description_en: Look up locally installed dev tools, language versions, install paths, version-switching commands, and proxy notes on this Windows 11 machine. Read-only reference; performs no installs or deletions.
version: 1.0.0
author: WorkBuddy
agent_created: true
allowed-tools: Read, Grep, Glob
examples_zh:
  - 我这台电脑装了哪些开发工具
  - 怎么切换 PHP / Node / Python 版本
  - Java 和 Go 装在哪、是什么版本
  - Go 怎么装新版本
examples_en:
  - What dev tools are installed on this machine
  - How do I switch Python/Node/PHP versions
  - Where is JDK installed and which version
---

# 本机开发环境清单（meiyo · Windows 11）

本文件是这台机器的开发环境**事实清单**。回答相关问题时优先依据本文件；若怀疑环境已变化，可用只读命令复核（见末尾「复核命令」），不要凭猜测回答。

> **权威来源**：本 skill 是 GitHub 仓库 `windows-toolkit` 的一部分（`skill/dev-env-inventory/SKILL.md`）。仓库中的 `docs/` 目录有更详细的清单、版本管理速查、资源利用指南与网络配置经验。若本机 skill 与仓库文档不一致，以仓库最新版本为准。仓库地址：`git@github.com:wuxiumu/windows-toolkit.git`。

## 一、机器与磁盘

- 主机：Windows 11，用户目录 `C:\Users\meiyo`
- 磁盘：C 326GB（系统+开发工具）、D 203GB（软件盘）、E 202GB（Code）、H 200GB
- 2026-11-21 扩容：C 由 198GB → 326GB（借磁盘尾部未分配空间），D 数据完整迁移

## 二、语言运行时与版本管理（核心）

所有语言均已统一为**命令行版本管理**，删除了旧版绿色安装（Java16 / Go1.16 / phpstudy 自带 PHP / Node v14）。

| 语言 | 当前版本 | 管理工具 | 安装/数据位置 |
|---|---|---|---|
| Python | 3.13.17 | **uv** 0.10.9 | 系统 PATH |
| Node.js | v26.13.1 (LTS) | **fnm** | `C:\Users\meiyo\AppData\Roaming\fnm\node-versions\` |
| PHP | 8.6.0 (ZTS) | **scoop** 0.6.0 | `C:\Users\meiyo\scoop\apps\php\` |
| Java (JDK) | Temurin 21.0.13 LTS | **scoop** (java bucket) | `C:\Users\meiyo\scoop\apps\temurin21-jdk\` |
| Go | 1.27.4 | **scoop** (main bucket) | `C:\Users\meiyo\scoop\apps\go\` |
| Ruby | 4.0.10-1 | **scoop** (main bucket) | `C:\Users\meiyo\scoop\apps\ruby\` |

**PATH 要点：**
- scoop 命令入口：`C:\Users\meiyo\scoop\shims`（已加入用户 PATH）
- scoop 根目录靠用户环境变量 `SCOOP=C:\Users\meiyo\scoop` 定位（**必须保留**，否则 scoop 误判根目录为 C:\ 而报错）
- 新开终端才会加载最新 PATH；旧窗口找不到命令时重开即可

### 版本切换命令速查

**Python（uv）**
```
uv python install 3.11        # 装版本
uv python use 3.11            # 切换
uv python list                # 列出
```

**Node（fnm）**
```
fnm install 22                # 装版本
fnm use 22                    # 切换（当前会话）
fnm default 22                # 设默认
fnm list                      # 列出
```
- 注意：PowerShell Profile 用的是**静态 PATH**（指向 v26.13.1），因为沙箱禁止 Invoke-Expression。若 `fnm use` 后新窗口未生效，需同步改 Profile 里的 PATH 行：`C:\Users\meiyo\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

**PHP / Java / Go / Ruby（scoop）**
```
scoop install php@8.3         # 装指定版本（清单支持时）
scoop list                    # 列出已装
scoop reset php@8.3           # 切换已装版本
scoop update php              # 升级
scoop uninstall php           # 卸载
```

## 三、Scoop 配置（关键：网络代理）

这台机器访问 GitHub 受限，scoop 做过特殊配置，**回答/维护 scoop 相关问题时必须知道**：

- scoop 本体：手动部署（官方 `get.scoop.sh` 在该网络下不通），完整仓库在 `C:\Users\meiyo\scoop`
- 三个 bucket 的 git remote 均已改为代理：`https://gh-proxy.com/https://github.com/ScoopInstaller/{Main,Java}.git`
- **清单 URL 改写**：部分 bucket 清单（如 temurin21-jdk、ruby）里的 GitHub 下载链接被 scoop 判无效，已手动把 `https://github.com/` 前缀改成 `https://gh-proxy.com/https://github.com/`。若新装软件报 "URL is not valid" 或下载失败，按同样方法改对应 `bucket\<包名>.json` 的 url 字段。
- shim 修复：scoop 默认用 kiennq 版 shim.exe，已从仓库 `supporting\shims\scoopcs\shim.exe` 复制到 `apps\scoop\current\supporting\shims\kiennq\shim.exe`；若提示 shim.exe 缺失照此补。
- 环境代理：`HTTP_PROXY/HTTPS_PROXY=http://127.0.0.1:12079`（可用）；`github.com` 直连返回 502，`gh-proxy.com` 与 `windows.php.net` 可访问。
- 用户 `.gitconfig` 里有 `http.https://github.com/.proxy=socks5h://127.0.0.1:11080`（用户自有配置，未启动时失效）——不要随意删除；scoop bucket 已用 gh-proxy 绕过此问题。

## 四、编辑器 / IDE

| 工具 | 版本 | 位置 | 说明 |
|---|---|---|---|
| VS Code | 1.146.0 | C 盘 | 2026-11-21 卸载清空配置后重装，扩展为空 |
| Trae CN | 3.4.17 | C 盘 | 字节 AI IDE |
| ZCode | 3.18.2 | C 盘 | 智谱 AI 编程 |
| OpenCode | 2.2.7 | C 盘 | 开源 AI 编程助手 |

已卸载：PhpStorm（2021.1/2023.2）、phpstudy_pro（含 WWW 站点数据，用户确认删除）。

## 五、容器 / 数据库 / 其他

- Docker Desktop 4.99.0（C 盘，2026-11-21 清空数据后重装，当前无容器镜像）
- WSL 3.0.5.0（Docker 依赖）
- Git 2.56.0
- Navicat Premium 15 / 12
- 本地大模型：Ollama 0.18.3（模型在 `~\.ollama` 约 10.9GB）、LM Studio 0.3.18（模型在 `~\.lmstudio` 约 5GB）——均在 C 盘
- Python AI 栈：numpy / pandas / transformers / fastapi / pydantic / openai / anthropic sdk 等已装

## 六、复核命令（怀疑环境变化时只读执行）

```
# 验证所有语言命令
java -version; go version; ruby --version; php --version; node --version; python --version

# scoop 已装清单
$env:SCOOP='C:\Users\meiyo\scoop'; & 'C:\Users\meiyo\scoop\bin\scoop.ps1' list
```

## 七、回答原则

- 用户问"装了什么/版本多少/在哪" → 直接按本清单回答，标注"截至 2026-11-21"
- 用户问"怎么切版本/装版本" → 给对应工具的命令行，注明 scoop 需新开终端
- 涉及安装/删除/切换的实际操作 → 本 skill 只读，交回主流程按用户确认执行
- 若用户说环境变了 → 用复核命令只读确认后更新本文件
