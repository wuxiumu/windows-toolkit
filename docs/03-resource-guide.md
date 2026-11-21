# 硬件资源利用指南

> 针对本机硬件（i5-12500 / 24GB RAM / RX 560 4GB / 四块 SSD/HDD 共约 900GB）的优化方案。
> 核心判断：**CPU 强、内存大、独显弱、盘位多** —— 所以计算靠 CPU+内存，存储靠多盘分流，不赌独显算力。

---

## 一、先摸清家底（只读）

```powershell
# CPU / 内存
Get-CimInstance Win32_Processor | Select Name, NumberOfCores, NumberOfLogicalProcessors
Get-CimInstance Win32_ComputerSystem | Select @{n='RAM_GB';e={[math]::Round($_.TotalPhysicalMemory/1GB,1)}}

# 各盘空间
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select DeviceID,
  @{n='TotalGB';e={[math]::Round($_.Size/1GB,0)}},
  @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,0)}}

# 找出 C 盘占用大头
Get-ChildItem "$env:USERPROFILE\AppData\Local" -Directory | ForEach-Object {
  $s=(Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
  if($s -gt 1GB){ '{0} = {1} GB' -f $_.Name, [math]::Round($s/1GB,1) }
}
```

`scripts/maintenance/disk-usage.ps1` 已封装上述扫描，只读、可放心运行。

---

## 二、存储分层：四块盘各司其职

### 推荐布局

| 盘 | 定位 | 放什么 | 理由 |
|---|---|---|---|
| **C:** | 系统 + 程序 | Windows、scoop/uv/fnm 管理的程序 | 系统盘优先保证速度，只装程序本体 |
| **D:** | 应用数据 + 虚拟内存 | pagefile.sys、应用数据、下载 | 把虚拟内存移出 C 盘可释放十余 GB |
| **E:** | 代码 + 容器数据 | Git 仓库、Docker 数据目录 | 代码和容器 IO 密集，独立盘避免与系统抢 IO |
| **H:** | 大模型 + 冷数据 | Ollama/LM Studio 模型、归档 | 模型体积大但访问不频繁，容量盘最合适 |

### 立竿见影的三步

1. **本地大模型迁到 H 盘**（释放约 16GB）
   - Ollama：设置环境变量 `OLLAMA_MODELS=H:\ollama\models`，把 `~\.ollama\models` 整个搬过去，模型不用重新下载。
   - LM Studio：应用内修改模型目录到 `H:\lmstudio\models`。

2. **Docker 数据迁到 E 盘**（释放约 15GB）
   - Docker Desktop → Settings → Resources → Advanced → Disk image location，改到 `E:\docker`。
   - 或迁移 WSL 发行版：`wsl --export docker-desktop <path>` → `wsl --import docker-desktop <新位置> <path>`。

3. **虚拟内存迁到 D 盘**（释放约 14GB）
   - 系统属性 → 高级 → 性能设置 → 高级 → 虚拟内存 → 取消「自动管理」→ C 盘设小值或系统管理、D 盘设自定义大小。

> ⚠️ 涉及虚拟内存和 Docker 的变更需要管理员权限，且改完要重启。操作前确保有备份。

---

## 三、计算协同：把 12 线程和 24GB 内存用满

### 本地 AI：CPU + 内存推理为主

RX 560 只有 4GB 显存，跑不动 7B 以上模型；但 24GB 内存足够流畅跑 7B/14B 的量化模型。

```powershell
# Ollama 走 CPU + 内存，控制并发避免挤爆
$env:OLLAMA_NUM_PARALLEL = 2        # 并发请求数
$env:OLLAMA_MODELS = 'H:\ollama\models'
$env:OLLAMA_HOST = '0.0.0.0:11434'  # 需要局域网访问时才设

# 推荐模型规格：7B/8B 用 q4_k_m 量化（约 4-5GB），14B 用 q4（约 8-9GB）
ollama run qwen2.5:7b-q4_k_m
```

**与 Docker 协同**：同时跑容器和本地模型时，给 Docker 限内存（Settings → Resources → Memory 设为 12GB 左右），留一半给模型，避免 OOM。

### 并行构建：吃满多核

```powershell
# C/C++ 编译
make -j12

# MSBuild
msbuild /m:12

# Node 生态（pnpm 默认并行，可显式指定）
pnpm -r --parallel run build

# Python 并行任务
uv run python -m pytest -n auto    # pytest-xdist
```

### 内存富余的用途

24GB 内存日常开发通常只用一半，富余部分可以：
- 把临时目录/构建缓存指向内存盘（需第三方 RAMDisk 工具），加速编译。
- 给 Docker/虚拟机多分配内存，减少磁盘交换。
- 跑多个本地服务（数据库、Redis、向量库）而不卡。

---

## 四、环境一致性：所有语言走版本管理

Python→uv、Node→fnm、PHP/Java/Go/Ruby→scoop 的价值在于**可复现**：

- 项目要什么版本就切什么版本，不污染全局。
- `scoop reset` / `fnm use` 秒级回退，升级不怕翻车。
- 新机器跑 `bootstrap.ps1` 自动装齐，换机成本趋近于零。

配合本文的「存储分层」和「计算协同」，这台机器的资源就能被充分且稳定地利用。

---

## 五、健康检查清单（建议每月一次）

```powershell
# 1. 环境是否完好
powershell -File scripts\maintenance\env-check.ps1

# 2. 磁盘是否告急（低于 15% 该清理了）
powershell -File scripts\maintenance\disk-usage.ps1

# 3. 本地模型是否在预期位置
echo $env:OLLAMA_MODELS
Get-ChildItem H:\ollama\models -ErrorAction SilentlyContinue

# 4. Docker 磁盘占用
docker system df
```

发现 C 盘空间再次吃紧时，优先检查：Temp 目录、npm/uv/gradle 缓存、Docker 镜像、模型目录，按 `docs/04-network-and-scoop.md` 的思路清理。
