# ERRORS

## [ERR-20260306-001] cron.run

**Logged**: 2026-03-06T19:24:52+08:00
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
cron(job run) 偶发 gateway websocket timeout

### Error
```
gateway timeout after 30000ms
Gateway target: ws://127.0.0.1:18789
Source: local loopback
Config: /root/.openclaw/openclaw.json
Bind: lan
```

### Context
尝试通过 cron 工具触发 Breakfast+Weather / daily:breakfast-menu 时发生超时。

### Suggested Fix
- 检查 gateway 进程状态与端口监听，必要时 `openclaw gateway restart`。
- 检查 bind/lan 与本机 loopback ws 连接是否被防火墙/网络栈影响。

### Metadata
- Reproducible: unknown
- Related Files: ~/.openclaw/openclaw.json

---
