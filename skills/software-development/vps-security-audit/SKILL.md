---
name: vps-security-audit
description: "VPS 安全体检/加固/值守审计（云瞳 M0）：基线采集、分级处置、复扫验证、回执。"
version: "1.0.0"
author: 朴智妍 / Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [security, audit, vps, hardening, yuntong, remediation]
    related_skills: [vps-web-deploy, ziyan-governance, systematic-debugging]
---

# VPS 安全审计与加固（云瞳 M0）

## When to Use

- 用户要求安全体检/加固/值守（云瞳产品类任务）。
- 部署/卸载服务后想确认暴露面与残留（“检查有没有端口裸挂”、“卸载干净了吗”）。
- 用户要求“做了什么/什么命令/什么效果”式处置回执（本技能的回执格式即云瞳用户侧反馈标准）。

本类任务默认按 ziyan-governance 分级：L0 自动、L1 带审批、L2+ 不动只报告。

Class task: 给本机或客户 VPS 做安全体检 + 分级加固 + 持续值守。卖结果不卖工具——交付物是「体检报告 + 处置回执」，不是面板。
云瞳项目家：`/root/yuntong/`（scanner / data / docs / fixer / watcher），第一台机器 = 用户自己的 VPS（taoque, 38.14.254.100）。

## Always-on 规则
- 证据优先：每个结论附产生它的命令的真实输出；绝不编造端口/进程/日志状态。
- 分级处置：L0 自动（非破坏：fail2ban、封 IP、杀进程）；L1 需回执里写回滚（配置变更、启用防火墙）；L2+（包升级、容器网络隔离、影响业务）列进「未动项」等用户审批，不擅自做。
- 白名单先行：fail2ban 的 ignoreip 必含 127.0.0.1/8 ::1 + 用户自己的来源 IP（从 `grep Accepted /var/log/auth.log` 提取），先确认不会把自己锁死。
- 启用 default-deny 防火墙后，逐站点（带正确 Host 头）+ 外部视角验证既有服务仍可达，不能只测裸 `/`。
- 禁用密码登录前，先 `ssh-keygen -lf /root/.ssh/authorized_keys` 确认非空，并在回执里提醒用户「以后必须带密钥」。

## 步骤
1. **采集基线**：`bash <skill>/templates/collect-baseline.sh [输出目录]`（默认 /root/yuntong/data/）。覆盖：ss -tlnp、sshd -T 关键项、ufw/iptables、fail2ban、docker 暴露面、apt 待更新、登录失败统计。JSON 生成必须走 python3（pitfall 1）。
2. **分诊**：高危 = 公网裸挂面板/SSH 密码登录+爆破中/残留进程/DB 端口公网；中危 = 容器共享网络内 DB、包更新积压；良好面也要写（127.0.0.1 正确绑定的服务是正面基线）。
3. **L0 处置**：装 fail2ban → `/etc/fail2ban/jail.d/ssh.local`（sshd jail：maxretry 5, findtime 10m, bantime 1h, ignoreip 白名单）→ `systemctl enable --now fail2ban` → `fail2ban-client status sshd` 看 `Currently banned`。杀残留进程必须 `ps -p PID` 复验消失。
4. **L1 处置**：
   - SSH 加固：写 `/etc/ssh/sshd_config.d/yuntong-hardening.conf`（PermitRootLogin prohibit-password / PasswordAuthentication no / X11Forwarding no / LoginGraceTime 30）→ `sshd -t` 校验 → `systemctl reload ssh` → `sshd -T` 复验。回滚 = 删该 conf + reload。
   - 防火墙：`ufw default deny incoming` + 逐条 `ufw allow 22/80/443/tcp`（每条确认 Rule added）+ `ufw --force enable`。回滚 = `ufw disable`。
5. **外部验证**：`docker run --rm curlimages/curl:latest curl -s -o /dev/null -w "%{http_code}" --max-time 5 http(s)://<公网IP>[:port]/`（host 自己 curl 公网 IP / 127.0.0.1 不经过 INPUT 链，不算数）。
6. **复扫 + 回执**：重跑 collect-baseline.sh，确认高危项「复扫变绿」；按回执格式输出。

## 回执格式（用户固定要求）
每个操作一条：`操作 N · 标题（风险级）` → 使用的命令 → 效果（证据）→ 回滚方法（如有）；末尾「未动（待审批）」+「遗留提醒」（如 SSH 已禁密码）。用户已明说这就是他家云瞳平台用户侧反馈标准，三要素（做了什么/什么命令/什么效果）缺一不可。

## Pitfalls
1. **shell heredoc 手拼 JSON 必坏**：多行变量含控制字符会让 `python3 -m json.tool` 报错。原始文本一律走环境变量传给内嵌 python3，列表构造/转义/写文件全在 python3 里做（json.dump, ensure_ascii=False, indent=2）。
2. **本机 curl 公网 IP ≠ 外部视角**：loopback/本机流量绕过 ufw INPUT 链，测试结果不可信；用一次性容器（自带出口流量走宿主）近似外部。80/443 返回空响应（curl exit 52）先查 vhost 是否只认特定 Host 头，再怀疑防火墙。
3. **只删文件不等于卸载**：删二进制不杀运行中 daemon，残留进程会活很多天。卸载后必查 `ps -eo pid,etime,cmd | grep <bin>` 并 kill + 复验。
4. **ufw 批量 + 重定向时出错定位困难**：报错源不明时逐条执行、看「Rule added」确认；`--force` 仅在 enable/disable 用。
5. **爆破统计带轮换日志**：`grep -c 'Failed password' /var/log/auth.log*`（含 .1/.gz）作背景量；fail2ban 的 `Currently banned` 才是当前生效信号。
6. **80/443/22 之外的面板端口（如 8008）**：ufw 收紧后公网自动被拒，但不必为此保留监听——最终方案是面板改绑 127.0.0.1，ufw 只是兜底。
7. **CVE 应急（高危通告+官方未出补丁）**：先按「机群逐台盘点 → 官方支持分支/EOL 分级 → 引用关系判定」走，决策表见 `references/cve-triage.md`。停容器后必查 restart 策略（always 会复活）；能通的机先出结果，认证卡住的单列，不硬试。