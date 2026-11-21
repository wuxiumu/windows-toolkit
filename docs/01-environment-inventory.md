# 开发环境清单

> 本文件是开发机环境的**权威事实来源**（截至 2026-11-21）。配套 Skill 依据此文件回答「装了什么、版本多少、在哪」类问题。
> 环境变化后，用 `scripts/maintenance/env-check.ps1` 只读复核，再更新本文件。

## 一、语言运行时与版本管理

所有语言统一为**命令行版本管理**，已清除旧版绿色安装（Java16 / Go1.16 / phpstudy 自带 PHP / Node v14）。

| 语言 | 当前版本 | 管理工具 | 安装位置 |
|---|---|---|---|
| Python | 3.13.17 | **uv** 0.10.9 | 系统 PATH（uv 管理的解释器） |
| Node.js | v26.13.1 (LTS) | **fnm** | `$env:APPDATA\fnm\node-versions\` |
| PHP | 8.6.0 (ZTS) | **scoop** | `$env:USERPROFILE\scoop\apps\php\` |
| Java (JDK) | Temurin 21.0.13 LTS | **scoop**（java bucket） | `$env:USERPROFILE\scoop\apps\temurin21-jdk\` |
| Go | 1.27.4 | **scoop**（main bucket） | `$env:USERPROFILE\scoop\apps\go\` |
| Ruby | 4.0.10-1 | **scoop**（main bucket） | `$env:USERPROFILE\scoop\apps\ruby\` |

**PATH 要点：**
- scoop 命令入口：`$env:USERPROFILE\scoop\shims`（已加入用户 PATH）
- 用户环境变量 `SCOOP=<用户目录>\scoop` **必须保留**，否则 scoop 会误判根目录为 `C:\` 并报错
- 新开终端才会加载最新 PATH；旧窗口找不到命令时重开即可

## 二、编辑器 / IDE

| 工具 | 版本 | 位置 | 说明 |
|---|---|---|---|
| VS Code | 1.146.0 | C 盘 | 卸载清空配置后重装，扩展为空（全新状态） |
| Trae CN | 3.4.17 | C 盘 | AI IDE |
| ZCode | 3.18.2 | C 盘 | AI 编程工具 |
| OpenCode | 2.2.7 | C 盘 | 开源 AI 编程助手 |

已移除：PhpStorm、phpstudy_pro（连同其 WWW 站点数据）。

## 三、容器 / 数据库 / 命令行

- **Docker Desktop** 4.99.0（C 盘，清空数据后重装，当前无容器镜像）
- **WSL** 3.0.5.0（Docker 依赖）
- **Git** 2.56.0
- **Navicat** Premium 15 / 12
- 7-Zip、FileZilla 等常用工具

## 四、本地大模型

| 工具 | 版本 | 模型位置 | 说明 |
|---|---|---|---|
| Ollama | 0.18.3 | `~\.ollama`（约 10.9GB） | 本地模型运行框架 |
| LM Studio | 0.3.18 | `~\.lmstudio`（约 5GB） | 图形化本地模型 |

Python AI 栈已装：numpy、pandas、transformers、fastapi、pydantic、openai/anthropic SDK 等，适合自建 Agent 与 LLM 应用。

## 五、磁盘布局

| 分区 | 容量 | 空闲 | 定位 |
|---|---|---|---|
| C: | 326GB | ~150GB | 系统 + 工具程序 |
| D: | 203GB | ~171GB | 应用数据 + 虚拟内存 |
| E: | 202GB | ~87GB | 代码仓库 + Docker 数据 |
| H: | 200GB | ~93GB | 大模型 + 冷数据 |

> 说明：C 盘原为 198GB，2026-11-21 利用磁盘尾部 203GB 未分配空间扩容至 326GB；D 盘数据完整迁移，盘符与软件路径未变。
