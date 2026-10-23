# 鉴权态 × 端点的期望码决策表（按你的 gate 策略改）

通用形态：数据/写路由要登录会话；账号管理要 admin；canary + 登录入口公开；机器侧回推走 Bearer token（非用户会话）。

| 请求 | 期望 | 说明 |
|---|---|---|
| `GET /health` | 200（公开） | canary 探活，不鉴权 |
| `POST /auth/login` | 200/401 | 入口；错密码=401 |
| `GET /auth/me`（带/不带 session） | 200/401 | 会话自检 |
| `GET /machines`（不带 session） | 401 | 数据路由必须登录 |
| `GET /machines`（带 session） | 200 | |
| `POST /killswitch`（不带 session） | 401 | 写路由必须登录 |
| `GET /auth/accounts`（非 admin） | 403 | admin-only |
| `GET /auth/accounts`（admin） | 200 | |
| `POST /push`（正确 Bearer） | 200 | 机器侧回推，非用户会话 |
| `POST /push`（错误 Bearer） | 401 | |
| `GET /events/stream`（不带 session） | 401 | 鉴权 SSE 也要闸 |
| `GET /events/stream?session=…` | 200/SSE | token 走 query |

要点：
- 负向用例（401/403/404）和正向（200）一样打，缺负向 = 鉴权闸可能没生效而没发现。
- 登出后（`POST /auth/logout`）用旧 token 再打应回 401，证明会话真失效、不是恒放行。
- 面板 token 校验常见「常量时间比较 + SHA-256」；错 Bearer 必须是 401 而非 500/404。
