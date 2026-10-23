#!/usr/bin/env bash
# 云瞳 collect-baseline: VPS 安全基线采集 → 标准 JSON（python3 保证 JSON 合法）
# 用法: bash collect-baseline.sh [输出目录]   默认 /root/yuntong/data
set -u
OUTDIR="${1:-/root/yuntong/data}"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/$(date +%Y%m%d_%H%M%S)_$(hostname).json"

PORTS=$(ss -tlnp 2>/dev/null | awk 'NR>1 {print $4" "$7}' | sort -u)
SSH_CFG=$(sshd -T 2>/dev/null | grep -E '^(permitrootlogin|passwordauthentication|port|logingracetime|maxsessions|x11forwarding) ' || true)
FWRULE=$( { command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | head -8; } || iptables -L INPUT -n 2>/dev/null | head -15 || echo "无防火墙工具")
SSHF=$(grep -c 'Failed password' /var/log/auth.log 2>/dev/null || echo 0)
DOK=$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null || echo "docker 不可用")
PKGS=$(apt-get -s upgrade 2>/dev/null | grep -E '^[0-9]+ upgraded' | head -1 || echo "未知")
F2B=$(fail2ban-client status sshd 2>/dev/null | head -12 || echo "fail2ban 未运行")
ACCEPTED=$(tail -200 /var/log/auth.log 2>/dev/null | grep 'Accepted' | tail -5 || true)

PORTS="$PORTS" SSH_CFG="$SSH_CFG" FWRULE="$FWRULE" SSHF="$SSHF" DOK="$DOK" \
PKGS="$PKGS" F2B="$F2B" ACCEPTED="$ACCEPTED" OUT="$OUT" python3 <<'PYEOF'
import json, os, socket, datetime
env = os.environ
lines = lambda v: [l for l in v.splitlines() if l.strip()]
data = {
  "host": socket.gethostname(),
  "os": lines(open('/etc/os-release').read())[0].split('=')[1].strip('"'),
  "ts": str(datetime.datetime.now().astimezone()),
  "listening": lines(env['PORTS']),
  "ssh": lines(env['SSH_CFG']),
  "firewall": lines(env['FWRULE']),
  "fail2ban_sshd": lines(env['F2B']),
  "ssh_failed_attempts": int(env['SSHF'] or 0),
  "recent_accepted_logins": lines(env['ACCEPTED']),
  "docker_exposure": lines(env['DOK']),
  "apt_pending": env['PKGS'].strip(),
}
json.dump(data, open(env['OUT'], 'w'), ensure_ascii=False, indent=2)
print("采集完成:", env['OUT'])
PYEOF
