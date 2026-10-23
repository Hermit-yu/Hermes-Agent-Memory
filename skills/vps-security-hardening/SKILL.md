---
name: vps-security-hardening
description: VPS 安全加固与机群统管：审计、SSH/ufw 加固、统一密钥、canary 验证、防锁死。
---

# VPS 安全加固 / 机群统管（云瞳标准流程）

适用：加固单台或批量加固、新机器接入统一密钥管理、被锁死后的解锁恢复。用户有多台 VPS，本类任务反复发生，标准就是云瞳产品的 MVP 流程。

## 永远先审计，再动手
1. 跑探测：本地 `bash /root/.hermes/skills/vps-security-hardening/scripts/audit.sh`；远端 `ssh -i <key> -p <port> -o BatchMode=yes root@host 'bash -s'` 后重定向审计脚本。
2. 审计结果按 高危/中危/良好 分级先汇报，再逐项执行修复。绝不盲改。

## 防锁死铁律（最高优先级）
- 禁密码认证前，必须实测至少一条密钥通道可用：目标机 authorized_keys 已登记公钥 + 用对应私钥 `ssh -i <key> -o BatchMode=yes root@host 'echo ok'` 真的成功。跨机必须真密钥实测，本机回环测试只算初步验证。
- 动 authorized_keys / sshd_config 前先 cp 备份。
- 查公钥是否已登记：grep 该 key 的 base64 主体（`awk '{print $2}'` 提取），不要 grep 密钥类型字段（`ssh-ed25519` 等永远匹配——曾因此误判“已登记”，锁死后才发现根本没登记）。
- 每个 L1 变更当场记录回滚命令（用户要求“可回滚”）。
- 删 authorized_keys 行前（哪怕以“清项目遗留”名义）逐行审计：对每条待删 key 查近 7 天 sshd 日志 `grep 'Accepted publickey' /var/log/auth.log`，用 `ssh-keygen -l` 指纹对齐确认该 key 是否仍被实际登录使用；key 的注释/标注常与真实归属不符（项目 key 可能是用户日常登录 key）。删完当场用自己的 key canary 连一次。
- 旧 .bak 可能只含最早一条 key，不等于全量备份——动 authorized_keys 前必须重新 `cp` 整个现行文件，删后恢复只能靠新备份或日志/拆除记录里留存的 base64 主体（指纹对得上才可写回）。
- 临时恢复通道（开密码登录）必须明示“临时”，恢复后立刻上锁并复验。

## 防火墙改动必须 canary 验证（不可跳过）
任何 ufw/iptables 改动后，依次验证，全部通过才许汇报“完成”：
1. `ufw status` 显示 **active**——规则写进去 ≠ 防火墙启用（`ufw enable` 的确认提示会被管道吞掉，或逐条 allow 静默失败，只剩默认策略；实测发生过锁死事故）。
2. 放行规则在 ufw 规则列表 / iptables·nft 里真实可见。
3. **外部视角**探测公网 IP：允许端口通、非放行端口拒（从另一台机器 `timeout 4 bash -c 'exec 3<>/dev/tcp/IP/PORT'`，或一次性容器 `docker run --rm curlimages/curl:latest curl ...`）。
4. 密钥 SSH 复测成功。
任一失败 → 立刻回滚（`ufw disable` 保留规则 / 删除坏规则），禁止“命令跑完就算数”。
- UDP 放行规则不能靠 TCP 连接验证：从另一台机器发几个 UDP 探测包（`python3 -c "import socket;s=socket.socket(8,2);s.sendto(b'\\x00'*16,('IP',PORT))"`），再在远端 `journalctl -k --since "1 min ago" | grep -c "DPT=PORT,PROTO=17"` 查内核 DROP 计数——修复前同包必然产生 DROP 记录、修复后计数 0 即规则生效；能看目标服务自身连接日志则更可靠。

## 探测陷阱
- **收紧防火墙前必须先全量扫监听（TCP+UDP 双扫）：`ss -tulnp`，把已有对外服务（hysteria/3xui 类 QUIC-UDP、代理）逐个对应到放行规则。两次实测翻车：139:57689 和 167:57698 的 hysteria2（纯 UDP）在启用 ufw 收紧后全部断联，因为只查了 TCP 监听，UDP 服务被默认策略静默丢弃，用户侧无任何报错，直到人工报障才被发现。
- 收口或白名单化某台的公网端口前，先查该端口是不是谁的回传数据通道：`ss -tnp | grep :PORT` 看入站 ESTAB 连接的来源 IP 是否含机群成员，并确认 agent/上报目标（如监控面板 :8008 接收各机 agent 回报）是否指向这台——防火墙一改可能同时断掉跨机数据链路，症状是节点全部离线而非仅面板打不开。
- 本机 127.0.0.1 回环测试绕过 ufw（lo 不走 INPUT 链）——外部可达性必须跨机/跨容器探测。
- Docker 发布端口走 FORWARD 链，不受 ufw INPUT 默认策略约束：面板类端口（8008、3xui 24167/44624 等）即使 ufw 全拒仍可外部直连，收口要改绑 127.0.0.1 或做 IP 白名单。
- `ufw status` 在部分机器会挂起，超时后改用 iptables/nft 视角。

## ufw 命令兼容（Ubuntu 22.04/24.04、Debian）
- `ufw allow X/tcp` / `ufw default deny incoming`：**不要**加 `--force`（报 Invalid syntax）。
- headless 启用：`ufw --force enable`（`--force` 只对 enable/disable 有效）。
- 启用后必查 `ufw status | head -12` 确认 active。
- **删除规则必须镜像当初加规则的方向/措辞**：随手拼的 `ufw delete allow 8901/tcp from 172.18.0.0/16` 会报 `Wrong number of arguments`；先 `grep PORT /etc/ufw/user.rules` 读 `### tuple ###` 行拿真实方向（如 `allow tcp 8901 0.0.0.0/0 any 172.18.0.0/16 in` = 只来自 172.18 网段的入向放行），再用对应句式删（`ufw delete allow from 172.18.0.0/16 to any port 8901 proto tcp`），删后 `grep -c PORT /etc/ufw/user.rules` 应为 0。

## 全量拆除一个「项目 + 在线服务」的清单（用户要求连线上一起删干净）
先盘点再动手，逐项核对归属，只删确认属于该项目的资源：
1. **盘点五件套**：systemd unit（`systemctl is-active/is-enabled`）→ 进程（`ps -eo pid,cmd | grep 项目名`）→ 目录（源码仓 + 部署目录，`du -sh`）→ 反向代理（grep 站点 conf）→ 防火墙（`ufw status`）；agent 类项目再加两条：被监控机与本机的 crontab 推送行、token 文件与被管机脚本目录（如 /etc/<项目>-agent/、/opt/<项目>-agent/）。
2. **删 crontab 行别用 `grep -v <项目名>` 一把梭**：同前缀名字可能挂着别家服务的 cron（监控/计时类），grep-v 连坐误删且被删行无报错（静默）。做法：先 `crontab -l` 列全行，逐行看目标路径——agent 推送行指向 agent 脚本（删），站点 cron.php 行指向仍在跑的站点目录（留）；删完把幸存行原样回灌（写临时文件再 `crontab 临时文件`）逐行核对。远端机同理，先 `crontab -l > /tmp/cron.bak` 备份再滤删。
3. **归属核对**：共享基础设施（nginx 容器、80/443、别家 app 端口如 8008）先 `ss -tlnp` 看监听者是谁，**不是本项目的绝不动**；域名证书/续签任务只删本项目的 acme 目录，不动公共 80/443 放行。
4. **备份默认做，但用户明确说「不需要备份 / 之前做的不满意」就跳过**——删旧炉子开新炉子时备份会变成「误以为能从备份续做」的诱导，尊重指令直接删。
5. 执行顺序：`systemctl disable --now <units>` → 删 unit 文件 + `systemctl daemon-reload` → `rm -rf` 源码/部署目录 → 删 nginx vhost 后 `docker exec nginx nginx -t` 再 reload（conf 在坏不能盲删到 reload）→ 删本项目证书 + acme 目录 → 删 ufw 规则（镜像句式见上节）；删 docker 镜像前 `docker ps -a` 确认无容器挂该镜像、无回滚锚点 tag 才许 `docker rmi`；留可复现锚点用悬空 tag 法——旧镜像 `docker tag <旧ID> <name>:rollback-<date>` 后再 `pull` 刷新同 tag，旧 ID 失去 tag 转悬空但仍可 pull，比留着旧 tag（下次 pull 会覆盖、锚点漂移）干净。
6. **总验收**：`systemctl is-active` 全 inactive、`ss -tln` 无项目端口、curl 域名/端口无响应、`ls -d` 各路径不存在、`grep -rli 项目名 /home/web/conf.d /etc/systemd/system` 无残留、无残留进程。
7. **深扫**：`find / -maxdepth 6 -iname '*项目名*'`（排除 /proc /sys、刻意保留的备份与 skill 文档目录）——浅扫会漏 `/etc/systemd/system/multi-user.target.wants/` 悬空 symlink、certbot renewal-hooks、go-build 内容哈希缓存里的旧产物；共享服务（nginx/php/mysql 容器）只摘本项目配置、不整停，摘完 `nginx -t` + reload 验证其他站点无损。
8. **terminal 会话的 cwd 留在已删目录后，后续命令会 126 / getcwd 报错**：下一条显式 `cd /root` 或给 workdir。

## 统一管理密钥模式（fleet）
- 主 VPS 持有管理密钥对（如 `/root/.ssh/yuntong-mgr_ed25519`），每台机器 authorized_keys 登记同一把管理公钥 → 一把 key 进所有机器。
- 用户本地密钥也逐台登记（用户要“统管所有机器”）。
- 新机器无钥匙时：公钥给到用户（公钥非机密，可发聊天）→ 用户经面板终端或现有密码通道添加 → agent 实测连通 → 审计 → 加固 → 回执。私钥永不进聊天。
- 远端追加公钥用显式 `echo '$KEYBODY' >> file`（先 grep -qF 防重复），不要用 heredoc `cat >> file` 后紧跟其他脚本文本（会被吃进 key 文件写坏）。
- 部分机器 `PubkeyAuthentication` 默认关闭：密钥被拒先看 `sshd -T | grep -i pubkey`，开 yes + `systemctl reload ssh` 即可，与公钥是否登记无关。

## 回执格式（用户强制要求“最终反馈”）
每个操作批次完成后输出：**做了什么 / 执行了什么命令 / 达到什么效果**，并附验证证据（`Accepted publickey ...` 日志行、`ufw status` 输出、端口探测矩阵、`sshd -T` 生效值）。
- 登录/事件时间戳一律换算**北京时间（UTC+8）**再汇报——服务器日志是 UTC，直接报 UTC 会被用户当作“搞错时区”。
- 远程登录验证采用双确认：用户操作 + agent 查 auth.log/journalctl 出示证据。
