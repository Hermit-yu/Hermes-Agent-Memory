---
name: service-e2e-shell
description: "E2E-verify multi-process services via a shell harness."
version: "1.0.0"
author: 朴智妍 / Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [e2e, integration, go, services, shell, verification, auth, sse]
    related_skills: [systematic-debugging, dogfood, vps-web-deploy]
---

# 多进程服务端到端验证（shell harness）

## When to Use
- 要证明一套**跨进程**的东西真能工作：控制面↔agent 的 socket 协议、登录/会话闸、出站回推(`/push`)、远端机登记、授权闸——这类**无法用单测覆盖**、必须起真进程 curl 真端点才能证实的链路。
- 一次验证多个端点 + 多种鉴权态（带/不带 token、admin/非 admin、错误 Bearer）→ 逐个断言具体 HTTP 状态码。

Class task: 把「起 N 个进程 → 打 M 个端点 → 对每个断言期望状态码」写成**一个自包含 `.sh`**，一条命令跑完，全绿才报成。

## 为什么必须是独立 `.sh` 文件（关键约束）
Hermes 的 terminal 工具**拒绝内联 `&` 后台**：`cmd &` 在 foreground 命令里会直接报错（"Foreground command uses '&' backgrounding. Re-send without '&' as background=true"）。而 E2E harness 需要**同时**跑多个常驻进程（面板 + 一个或多个 agent）再 curl 它们。解法：把所有进程编排（起 `&`、curl、kill）写进一个 `.sh` 文件，用 terminal **foreground 跑 `bash harness.sh`**——`&` 在脚本文件内是合法的。这是本类任务的标准姿势，别试图在 terminal 里逐条 `&` 起进程。

## 标准流程（template 在 `templates/e2e-harness.sh`）
1. `set -euo pipefail`；`cd` 到项目根。
2. **构建到临时目录**：`go build -o /tmp/yt/x ./cmd/x`（或复用已编译 binary）；别用源码树里的旧 binary。
3. **清理残留**：`pkill -f '/tmp/yt/x/yuntongd' || true`（见 Pitfall 1/2）。用**唯一 state dir + 唯一端口**隔离本次运行，互不串。
4. **起进程**：面板 & agent 各一个 `&`；`sleep 0.3~0.8` 等 bind。
5. **先拿登录态**：从首次自举产物（如 0600 `admin-password.txt` 第 2 行）取密码 → `POST /auth/login` → `sed -n 's/.*"token":"\([^"]*\)".*/\1/p'`（或 `jq -r '.token'`）抽 token。
6. **逐端点 curl + 断言状态码**：`curl -s -o /dev/null -w '%{http_code}'`（或带 body 时 `curl -s`），对**带会话/不带会话/admin/非 admin/错 Bearer** 各态分别打，打印 `-> <实际>`。期望：无会话数据/写路由=401，带会话=200，非 admin 打 admin 路由=403，错 Bearer=401。决策表见 `references/assertions.md`。
7. **`kill $PANEL $AG`**；末尾 echo `=== DONE ===`。
8. 跑法：`bash harness.sh > out.log 2>&1; echo "exit=$?"; cat out.log`。**全绿才报成**；半红逐项列 + 指 journalctl/进程日志定位（对齐用户可验证交付要求）。

## Pitfalls（规则 + 为什么）
1. **`pkill -f` 的 pattern 必须用完整 binary 绝对路径，且绝不匹配到 terminal wrapper 自身。** 宽 pattern（如 `'/tmp/yt_state'`、裸 `'yuntong'`）会命中 Hermes terminal 启动命令行里含该串的进程 → 本 session 被 SIGTERM 打断（exit -15）。写死到 `'/tmp/yt_x/yuntongd'` 这种只匹配目标 binary 的路径。
2. **`set -e` 下 `pkill` 无匹配返回 1 → 脚本第一行就 die。** 每个 `pkill ...` 末尾必须 `|| true`（清理类命令天然可无匹配）。
3. **进程要「真在跑」才能 curl：`systemctl is-active` / 进程活着 ≠ 服务在听对端口。** canary 以 `curl <endpoint>` 的实际 HTTP 码为准（同 vps-web-deploy canary 原则）。起进程后 `sleep 0.3~0.8` 再打，别打 bind 前的竞态空窗。
4. **出站/回推类链路（agent → 面板 `/push`）验证法**：先手动 `POST /push`（正确 Bearer）断言 200 + 端点能看到登记，再断言错误 Bearer=401——把「agent 是否真的推成功」与「面板接收逻辑对不对」解耦，快速定位是哪一侧。面板侧给 `pushHandler` 入口打一行接收日志（收没收到 / 鉴权是否过），agent 侧给推成功/失败各打一行，双侧日志一对照就定位。
5. **鉴权 gate 下测长连接（SSE）**：浏览器 `EventSource` 带不了自定义 header，token 只能走 query（`/events/stream?session=…`）；E2E 侧 curl SSE 也要用 `curl -N '<url>?session=$TOKEN'`（`timeout` 限 1~2s 防挂），别用 `-H`。未带 session 的 SSE 应回 401。
6. **每态断言「期望码 vs 实际码」，不止 200。** 负向用例（无会话 401、非 admin 403、错 Bearer 401、未知资源 404）和正向一样关键——只测 200 会漏掉整个鉴权闸没生效。
7. **长连接端点（SSE）的状态码断言要两端都配好。** 服务端：连接建立时先 flush 一个初始帧（如 `: connected\n\n` 注释帧）再进 diff 循环——否则探活 curl 拿不到响应头，`-w '%{http_code}'` 只能输出 000。客户端：curl 超时/失败时已打印 000 且返回非零，**禁止 `|| echo 000` 兜底双拼**（拼出 `000000` 还会在 set -e 下杀死脚本）——用 `$(curl … || true)` 单源取值，然后断言「非 401」（带鉴权 200/000 都算连上，401 才是鉴权闸没生效）。
8. **状态型循环（值守 tick / 滚动基线）的故障注入轮：先轮询等前置条件成立再注入，窗口按实测节奏 sizing。** 例：基线要等首轮全量采集完（实测采集耗时可能远超 tick 间隔，先探针量一次再定窗口）才落盘，开端口早于建基线 → 故障被吸进基线、事件永不触发（假红但难查）；注入端口先 `ss -Htln` 预检空闲，忙了直接失败报「端口被占」而不是走到断言才假红。判定用文件/审计 grep 轮询（如 `wait_audit(){ for i in $(seq 1 N); do grep -q pat file && return 0; sleep 1; done; return 1; }`），不用固定 sleep。
9. **探针拿到 401/异常先取证实测值，别直接报产品 bug。** 工具层/显示层可能把 URL 里的 token 变量掩成字面 `***`——写进文件再回读的行可能已经不是你写的那行。取证法：`grep -c 'session=\*\*\*' file` 数磁盘上的字面星号；终极地面真值用 in-repo 临时 Go 程序（`url.Values` 构造 query + `httptest` 打真实 handler，build 进仓、跑完删）——能同时排除 shell 引号、掩码、stale binary 三层假象。本轮实例：SSE query 401 查到底全是探针锅，产品 header/query/SSE 三通道全 200。
10. **重跑变红先查环境串台，再查产品。** 上轮残留的旧进程（双 agent 抢同一 socket 文件、僵尸端口 holder）、被复用/删除的 state dir（每 tick 走「首检建基线」、diff 永不触发）都会让第二次跑红得莫名其妙。干净姿势：state dir 每次 `rm -rf` 重建、`rm -f` 陈旧 unix socket、按 **精确 binary 绝对路径** 杀旧进程、注入前 `kill -0 $PID` 确认测试端口 holder 还活着、面板 503/unavailable 先读 error body 里的 socket 路径再定位。串台修掉后多数「产品 bug」自证清白。
11. **断言键名先向真响应求证，再用 python 取 JSON。** `grep -o '"key":...'` 靠猜键名（`tcp_ports` vs `open_tcp_ports`）+ `grep -o '[a-z_]*$'` 这类恒匹配空串的锚点写法，会把全绿的被测系统打出一片假红。开跑前 curl 一次端点 `python3 -m json.tool` 看真实键名；提取一律 `sed -n 's/.*"state":\\"\\([a-z_]*\\)\\".*/\\1/p'` 捕获组或直接 python `json.load`，不靠 `grep -o + $` 拼接。
12. **审计日志要逐条读语义，不止数 result 字符串。** 通过轮次里 `grep '"result":"event_fired"'` 命中就 OK；但把审计全文 cat 出来看：恢复信号（info 级）被记成开单告警、模板占位符未渲染就落审计、一条开/关周期混出 3 条不同语义——这类**证据诚实性 bug** 只有通读审计内容才看得见，绿断言全绿也会漏。
13. **行为与当前源码矛盾 → 先怀疑部署的是旧二进制，别急着改代码。** 部署目录（如 `/opt/…/bin`）里的 binary 可能早于某次修复/新特性的提交编译；症状「同 token，header 通、query 401」但源码里明明有 query 回退时，隔离法：`go build -o /tmp/fresh/<svc> ./cmd/<svc>` 用当前源码重编到干净目录、起在干净端口/干净 state，对同一端点分别打 header/query 两种鉴权——fresh 全 200 而部署版 401 即坐实 binary 过期（重编替换 + `systemctl restart` 收口），fresh 也 401 才是真源码/逻辑 bug。对照实验前先 `git log -S '<改动串>' -- <file>` 确认该特性确实已合入，再比 `/opt` 与源码二进制的构建时间戳。

## 验证产物
打印每端点的 `-> 实际码`、PASS/FAIL 汇总；全绿报成，半红逐项列 + 给定位命令（`journalctl -u <svc>` / 进程 stderr 日志路径）。
