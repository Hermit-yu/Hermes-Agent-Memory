# 代理节点超时/不通诊断（mihomo 同内核实测）

适用：客户端（Clash Party / bettbox 等 mihomo/FlClash 内核）节点显示"超时"但用户坚称节点可用。目标：用**同一个 mihomo 内核**在服务器侧实测，区分"显示/测试 URL 问题"与"真不通"，并定位到根因。全程用临时工具，**完成后必须拆干净**（用户硬性要求：保持系统清爽）。

## 流程
1. **拉客户端实际在消费的 mihomo 配置**：`curl -s https://subs.taoque.top/share/file/<name>`（不是 /share/sub 裸 ClashMeta 输出——客户端用的是带组的那份）。
2. **注入测试端口**：在配置前加 `external-controller: 127.0.0.1:9090`、`external-controller-unix: /tmp/mihomo-test.sock`、`secret: ""`、`allow-ipv6: false`，存 /tmp/mihomo-test.yaml。9090/7890 若已被占用，换注入的端口号。
3. **下载内核**（GitHub release）：
   - `curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest` → assets 里找 `mihomo-linux-amd64-v<ver>.gz`（**后缀 .gz 不是 .zip**；用资产全名精确匹配，带 go 版本的别名行不要选）。
   - `curl -L -o mihomo.gz <url> && gzip -d mihomo.gz && chmod +x mihomo`，`./mihomo -v` 验证（应显示 Mihomo Meta vX.Y.Z）。
4. **启动**：terminal `background=true` 跑 `./mihomo -d /tmp -f /tmp/mihomo-test.yaml > /tmp/mihomo-test.log 2>&1`（前景命令里写 `&` 会被 harness 拒绝）。sleep 3-4s 后看日志："Mixed(http+socks) proxy listening at: 127.0.0.1:7890" + 各 provider 启动 = 配置解析成功；有 unsupported/invalid 行 = 配置本身有问题。
5. **列节点**：`curl -s http://127.0.0.1:9090/proxies` — 看 proxies 各条的 `type` 字段（Hysteria2/Vless/Vmess 是真实节点；Selector/URLTest/Compatible/Direct 是组/保留词）。
6. **延迟测试**（逐节点，URL 编码组名/节点名）：
   `curl -s "http://127.0.0.1:9090/proxies/<enc>/delay?timeout=8000&url=https://www.google.com/generate_204"`
   → `{"delay":N}` 通；`{"message":"An error occurred in the delay test"}` 不通。
7. **真实流量确认**（排除"只是 delay 测试打不过去"的假超时）：PUT 切 selector 组到目标节点（`curl -s -X PUT http://127.0.0.1:9090/proxies/<enc-组名> -H 'Content-Type: application/json' -d '{"name":"<节点>"}'`，sleep 1），再 `timeout 15 curl -s -o /dev/null -w '%{http_code}' -x http://127.0.0.1:7890 https://www.google.com/generate_204` → 204 真通，000 真不通。延迟与真实流量结论一致才可下"节点真有问题"的判断。
8. **根因定位**（对每个 000 的节点）：
   - DNS：`dig +short @1.1.1.1 <节点服务器域名> A`（再用 @8.8.8.8/@223.5.5.5 交叉验证）→ 全无 A 记录 = 域名解析不到，客户端必超时（根因在域名侧，补 A 记录）。
   - TCP 连通：`timeout 5 bash -c 'exec 3<>/dev/tcp/<host>/<port>'`；UDP 协议（hysteria2）探测不准，以第 7 步真实流量为准。
   - TLS 层：`echo | openssl s_client -connect <ip>:<port> -servername <sni>` 看握手是否成。
   - 协议字段：回看节点 URI，查实验性字段（mlkem 后量子加密、vmess 无 TLS 等）——服务端 TCP/TLS 通但真实流量 000，嫌疑落在内核不支持该协议字段。
   - 节点服务器是自己机器时：`ss -tlnp` / `ss -ulnp` 查 xray 入站是否真在监听该端口、进程在不在。
9. **拆除（必做）**：按精确 PID 杀测试进程（先 `ps -eo pid,cmd | grep mihomo` 确认，pgrep -f 会匹配到含同字样的 shell 自身导致误杀当前会话）；`rm` 二进制、yaml、log、`/tmp/mihomo-test.sock`、`geoip.metadb`；复验 9090/7890 已释放、测试物无残留、业务服务（sub-store 等）仍 active。

## 判定表
| 现象 | 结论 / 处置 |
| delay=N 且真实流量 204 | 节点本身通，"超时"是客户端测试 URL 问题 → 配置 test-url/url-test url 换 google generate_204，用户重拉 |
| delay 错 + 000 + 无 A 记录 | 域名解析不到 → 补 DNS A 记录 |
| delay 错 + 000 + TCP/TLS 通 | 协议字段内核不支持 → 服务端去实验字段或换协议 |
| delay 错 + 000 + TCP 未监听 | 服务端入站没起来 → 查服务器 xray 进程/端口 |
