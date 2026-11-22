# PanelLite 内核后端架构设计

## 1. 总览

PanelLite 的后端采用 **双进程架构**：`paneld`（Web 面板服务）+ `agent`（宿主机 Agent 服务）。两者通过 Unix Socket 进行结构化命令通信，各司其职，形成清晰的安全边界。

- **paneld**（Docker 容器内，非 root）：负责认证、公开 REST API、提供前端静态资源、代理文件下载。它不直接触及 Docker Socket、宿主机根目录或任意 Shell。
- **agent**（systemd/OpenRC 服务，宿主机）：唯一的宿主机管理入口，只监听 `/run/panellite/agent.sock`，不开放 TCP 端口。负责与真实系统交互：Docker Engine API、文件系统、进程监控、终端 PTY、Docker 容器管理等。

> **安全原则**：Web 进程不接触 Docker Socket；Agent 是唯一的宿主机入口，所有真实状态均从实际文件系统和 Docker Engine 读取。

## 2. 进程边界

```
Browser
   │ HTTPS / REST / SSE
   ▼
paneld（Docker，非 root）
   │ HTTP+JSON over Unix Socket
   ▼
agent（宿主机 systemd / OpenRC 服务）
   ├─ /proc 与系统状态
   ├─ Docker Engine API
   └─ /home/web 实际产物
```

### 2.1 paneld 职责

- HTTP 服务（Listen 地址由配置 `listen` 决定，默认 TCP）。
- 认证服务：Argon2id Hasher、Bootstrap Token、Session 管理（TTL、最大登录失败次数）。
- API 网关：将 JSON 请求转发至 Agent via Unix Socket，聚合来自 Docker、文件系统、进程的状态。
- 前端静态资源直接由 paneld 通过 HTTP 提供（构建后不再运行 Node.js）。
- 备份恢复、密码重置、健康检查等运维接口。

### 2.2 agent 职责

- **监听 Unix Socket**：`/run/panellite/agent.sock`，仅接受来自 paneld 的已认证请求。
- **系统状态采集**：CPU、内存、磁盘、网络接口、进程列表、服务状态、Docker 容器状态。
- **Docker 管理**：镜像、容器、网络、卷的生命周期操作（创建、启动、停止、删除、统计）。
- **文件管理**：宿主机目录的读写、打包下载、AI 尾部日志、文件归档。
- **终端管理**：基于 PTY 的 Shell 会话创建、输入/输出、尺寸调整、关闭。
- **应用市场**：应用安装、更新、卸载、图标获取。
- **监控与告警**：历史监控数据存储、实时检查、能力声明。
- **安全加固**：`no_new_privs`、umask、受保护配置、进程组隔离。

## 3. Unix Socket 接口契约

Agent Socket 位于 `/run/panellite/agent.sock`。paneld 通过已认证的 JSON over Unix Socket 与 Agent 通信。核心约束：

| 约束 | 说明 |
|------|------|
| **只读/受权访问** | Agent 从不接收 URL，也不新增公网出站能力。所有操作均基于已授权的系统资源。 |
| **有界字节流** | 远程下载时，paneld 使用只允许公开 HTTP/HTTPS 的专用客户端抓取，DNS 结果在拨号前校验并固定到已验证 IP。有界字节流通过 Unix Socket 上传接口交给 Agent，由文件管理器在目标目录内 `fsync` 并原子发布。 |
| **原子提交** | 取消时立即停止读取并清理尚未提交的暂存文件。完成的文件目录中永不出现可见的半文件。 |
| **认证** | 通过 `Authorization: Bearer <token>`，token 经 SHA-256 哈希比对。token 来源于 paneld 配置的 `Agent Token File`。 |
| **版本协议** | Agent 必须返回 `Agent-Version` 与 `Agent-Protocol-Version`。paneld 通过 `/v1/health` 和 `/v1/agent-healthcheck` 验证一致性。 |
| **流式终端** | PTY 独立授权有界生命周期；在终端 scope 下创建有界 PTY，断线保留最多约 100 秒以便重连。 |

### 3.1 Socket 请求/响应结构

每条 Socket 消息为 JSON 对象，通过现有的 `agentclient.Conn` 传输：

```json
{ "path": "/v1/health", "method": "GET", "params": {}, "id": "req-1" }
{ "path": "/v1/system/summary", "method": "GET", "params": {}, "id": "req-2" }
{ "path": "/v1/terminals", "method": "POST", "params": { "title": "build docker image" }, "id": "req-3" }
```

响应结构示例：

```json
{ "status": "ok", "version": "v0.84.0", "protocolVersion": "v3", "data": { ... } }
{ "status": "error", "code": "agent_unauthorized", "message": "认证失败" }
```

若请求路径不存在，返回 `not_found`；若方法不被允许，返回 `method_not_allowed`；发生业务错误返回对应 `status`/`code`/`title`。

### 3.2 已定义的 Socket 端点（子集）

| 端点 | 方法 | 说明 |
|------|------|------|
| `/v1/health` | GET | Agent 是否就绪，返回版本、协议版本、核心就绪状态、是否只读、原因列表 |
| `/v1/capabilities` | GET | 返回能力清单（`system.read`、`apps.read`、`docker.lifecycle` 等）及支持的 HTTP 方法 |
| `/v1/system/summary` | GET | 系统概览（主机名、OS、内存、CPU、磁盘、网络、SSH 登录事件） |
| `/v1/system/telemetry` | GET | 主机遥测数据（公网IP、负载、磁盘使用率、网络流量、SSH 登录事件） |
| `/v1/system/processes` | GET | 进程列表（支持搜索、排序、限制） |
| `/v1/system/containers` | GET | Docker 容器列表 |
| `/v1/docker/summary` | GET | Docker 摘要（镜像数、容器数、网络、卷） |
| `/v1/files` | GET | 文件列表（受保护目录过滤） |
| `/v1/files/write-policy` | GET | 文件操作策略（受保护路径、只读虚拟路径） |
| `/v1/terminals` | POST | 打开新终端会话 |
| `/v1/terminals/{id}` | GET/POST/PUT/DELETE | 终端操作（输入、输出、调整尺寸、关闭） |
| `/v1/system/actions` | POST | 系统级操作（进程信号、重启服务、BBRv3 等） |
| `/v1/system/resource-actions` | POST | 资源级操作（磁盘分区、包管理等） |
| `/v1/backups` / `v1/backups/{path}` | GET/POST/POST /recover | 备份与恢复（Docker Socket 访问受限） |
| `/v1/monitoring/history` | GET | 历史监控数据（按时间范围） |
| `/v1/monitoring/checks` | GET/PUT | 监控检测配置 |

所有端点均需要有效的 Bearer token；未授权请求返回 `401 Unauthorized` 并设置 `WWW-Authenticate: Bearer realm="panellite-agent"`。

## 4. REST API 设计（panelled 对外 HTTP API）

paneld 通过 HTTP 监听地址（配置 `listen`，示例 `127.0.0.1:8080`）提供公开 API。所有响应均使用 JSON，遵循统一错误格式。

### 4.1 认证

- Header: `Authorization: Bearer <token>`，token 由 `Agent Token File` 中的 32+ 字节经 SHA-256 哈希比对。
- 无效 token 返回 `401` 并带 `WWW-Authenticate`。

### 4.2 通用响应格式

```json
{ "status": "ok", "code": "ok", "title": "成功", "data": { ... } }
```
或错误形式：
```json
{ "status": "error", "code": "invalid_token", "title": "认证失败", "detail": "..." }
```

### 4.3 关键端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/health` | GET | 灵健康检查（向后兼容，转发至内部 `/v1/health`） |
| `/api/v1/agent-healthcheck` | GET | Agent 版本/协议一致性检查 |
| `/api/v1/capabilities` | GET | 返回能力清单（同 Agent `/v1/capabilities` 的简化视图） |
| `/api/v1/system/summary` | GET | 系统概览 |
| `/api/v1/monitoring/history` | GET | 历史监控数据 |
| `/api/v1/files` | GET/POST | 文件列表/上传（受权过滤） |
| `/api/v1/docker/containers` | GET/POST | Docker 容器管理 |
| `/api/v1/docker/images` | GET | 镜像列表 |
| `/api/v1/docker/networks` | GET | 网络列表 |
| `/api/v1/docker/volumes` | GET | 卷列表 |
| `/api/v1/docker/jobs` | GET | 任务列表 |
| `/api/v1/docker/tasks` | POST | 执行 Docker 任务 |
| `/api/v1/sites` | GET/POST | 网站列表/创建 |
| `/api/v1/apps` | GET/POST | 应用列表/操作 |
| `/api/v1/diagnostics` | GET | 体检服务目录 |

### 4.4 错误处理

- `400 Bad Request`：参数格式错误、RawPath/RawQuery 不为空。
- `401 Unauthorized`：缺失或无效 Bearer token。
- `403 Forbidden`：操作被禁用（如不可达的服务）。
- `404 Not Found`：资源不存在、路径错误。
- `405 Method Not Allowed`：不支持的 HTTP 方法。
- `409 Conflict`：资源冲突、并发修改。
- `415 Unsupported Media Type`：请求体非 JSON。
- `429 Too Many Requests`：速率限制（备份忙、存储使用忙、监控查询繁忙）。
- `503 Service Unavailable`：后端服务不可达（Docker、文件系统、Agent）。
- `500 Internal Server Error`：意外异常。

### 4.5 速率限制

关键端点受内部令牌桶限制，防止滥用：

- **备份相关**：`backup_busy`（备份恢复正在处理）。
- **存储使用**：`storage_usage_busy`（另一分析正在运行）。
- **监控查询**：`monitoring_busy`（历史监控查询繁忙）。
- **进程采样**：`process_metrics_busy`（另一进程样本正在运行）。

## 5. internal 前置包划分（内部模块边界）

Agent 的 `internal/` 目录下的每个子包对应一个 **领域边界**，遵循单一职责原则。以下是主要子包及其边界：

| 包 | 边界职责 | 关键类型/接口 |
|----|----------|----------------|
| `agent` | Agent 核心服务器、HTTP 请求调度、认证、能力声明 | `Server` struct、`Config`、`authorized()`、`capabilities()`、`health()` |
| `contract` | 共享协议定义（Agent Health、Monitoring History、Capability、SSHLoginEvent 等） | `AgentHealth`、`MonitoringHistory`、`Capability`、`SSHLoginEvent` |
| `monitoring` | 实时监控数据采集与历史存储 | `CheckSnapshot`、`MonitoringHistory`、历史查询接口 |
| `dockerx` | Docker Engine 封装，仅暴露安全的子集 API | `Client`、`Ping`、`ContainerList`、`ContainerStats`、`ImageList` |
| `filemanager` | 受保护的文件系统浏览、读写、打包、AI 尾部日志 | `Manager`、`fileList`、`fileEntry`、`fileContent`、`fileUpload`、`fileTrashList` |
| `terminal` | PTY 终端会话管理、输入/输出、尺寸调整 | `Manager`、`terminalOpen`、`terminalOperation`、`terminalInput` |
| `systeminfo` | 系统级信息（CPU、内存、磁盘、网络、进程、服务） | `Collector`、`ProcessSnapshot`、`HostTelemetry` |
| `systemmanage` | 系统管理操作（重启服务、BBRv3、端口管理） | `Manager`、`Execute`、错误类型（`ErrInvalidInput`、`ErrDisabled` 等） |
| `sites` | 网站（PanelLite Web）的创建、更新、删除、配置 | `Discoverer`、`Manager`、`ScriptSiteInput`、`SiteSummary` |
| `appmarket` | 应用市场：安装、更新、卸载、图标获取 | `Service`、`InstallInput`、`AppJob`、`AppJobOutput` |
| `diagnostics` | 系统体检：体检任务生命周期、结果输出 | `Service`、`Job`、`Catalog`、`Terminal` |
| `auth` | 认证服务：Argon2id Hasher、Bootstrap Token、Session 管理 | `Service`、`Hasher`、`EnsureBootstrapToken` |
| `store` | JSON Store（账户、Session、登录限速、审计） | `Store`、`User`、`Session`、原子读写 |
| `notification` | Shoutrrr 工人（邮件、Telegram、Server酱等） | `RunShoutrrrWorker` |

每个包均**仅暴露接口**（函数/结构体），内部实现细节隐藏。paneld 仅通过已定义的 Unix Socket 接口或 HTTP 端点与这些包交互，不直接访问内部字段。

## 6. 数据存储与持久化

- **JSON Store**（`internal/store`）：单个 `paneld` writer 独占，保存账户、Session、登录限速和审计。采用进程锁和原子落盘，防止并发写入损坏。
- **Agent 独立状态**：任务、监控历史、集群状态分别使用独立且有界的持久化文件，不与 JSON Store 共享写入入口。
- **资源版本**：每个资源包含基于实际产物计算的 `resourceVersion`；更新必须携带预期版本，版本变化时返回冲突，不静默覆盖。
- **未来迁移**：若多 Panel 共享写入、主动高可用或多租户控制面，可评估迁移至 SQLite；但任何迁移都不得改变 Agent 安全边界。

## 7. 部署与编译

- **paneld**：编译为无 CGO 的单文件 Linux 二进制，`go build -o paneld ./cmd/paneld`。作为 Docker 容器运行，非 root 用户，挂载必要只读目录。
- **agent**：同一 Go 源码树不同入口，`go build -o agent ./cmd/agent`。作为 systemd 或 OpenRC 服务运行，监听 `/run/panellite/agent.sock`。
- **编译参数**：`CGO_ENABLED=0`、`-ldflags "-s -w"`、`-trimpath`，产物体积小、启动快。
- **配置文件**：JSON 格式，包含 `listen`、`config` 路径、`dataDir`、`storePath`、`agentSocket`、`agentTokenFile`、`sessionTTL` 等。

## 8. 安全边界概览

| 边界 | 说明 |
|------|------|
| **Web ↔ Agent** | 通过 Unix Socket 进行有界、已认证的 JSON 通信；Agent 不监听 TCP。 |
| **Agent ↔ 宿主机** | 仅通过已授权的 API（Docker Engine、文件系统、进程监控）访问；不直接执行 Shell、不 source 函数。 |
| **文件下载** | 远程下载经 DNS 校验并固定 IP 的专用客户端完成；Agent 仅接收已验证的字节流。 |
| **终端 PTY** | 独立授权、有界生命周期；创建有界 PTY，断线保留最多约 100 秒。 |
| **备份** | 使用专用的 Docker Socket 通道（默认 `/var/run/docker.sock`），受 `backupMutationMu` 互斥锁保护。 |
| **审计** | 所有写操作记录在 JSON Store 的 audit 字段；版本字段防止并发静默覆盖。 |
| **配置隔离** | systemd 使用 unit namespace/mount/capability 沙箱；OpenRC 使用固定 root:group、no_new_privs、umask、受保护配置。 |

## 9. 与 KICKOFF-PanelLite.md 决策的对照

| 决策 | 对应架构实现 |
|------|--------------|
| **AGPL-3.0-only** | 所有新代码遵循 AGPL-3.0-only；复用 KPanel 源码时保留其版权声明（AGPL传染），自研部分归 PanelLite。 |
| **范围**：先做扎实内核 = 经典面板（概览/系统/网站/Docker/文件/终端/AI），真数据绑定；桌面窗口模式后置。 | 后端先实现上述 7 大模块的真实数据绑定；UI 窗口模式后置。 |
| **旧橘猫面板**：保留在线但冻结，不投新功能；PanelLite 可用后再切流量删旧。 | PanelLite 后端完全独立，旧面板通过 API 标识冻结，不再接受新功能开发。 |
| **真实优先：无真实数据源的模块诚实标“依赖未就绪”，绝不造假。** | 各模块（Docker、文件、进程、系统状态）均直读真实源；若服务不可达返回 `503` 或 `degraded` 状态，不返回 mock 数据。 |
| **安全门禁：Web非特权、Agent走Unix socket结构化命令、PTY独立授权有界生命周期、审计。** | 已在进程边界、Unix socket 契约、终端管理、数据存储中体现。 |
| **交付摘要写 /home/coding team/reports/。** | 参见下文“交付物”。 |

## 10. 交付物

- `/home/coding team/docs/architecture.md`—— 本文档（已写入）。
- `/home/coding team/reports/panel-lite-backend-architecture-summary.md`—— 简要交付摘要（见下）。