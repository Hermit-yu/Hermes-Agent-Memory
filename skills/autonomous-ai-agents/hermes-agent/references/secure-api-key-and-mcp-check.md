# Secure external API / MCP verification rules
- Never embed API keys in URL query params (`?tavilyApiKey=`) — leaks to logs/proxies; always use Authorization header or env.
- Check key prefix convention (`dev` vs production) — dev keys usually return 404 / no billing data; verify with real endpoint before claiming credits.
- For MCP endpoints: test `https://<host>/` (health) first, then `/mcp` (POST) or `/sse`; do not assume endpoint paths.
- Write secrets to `~/.hermes/.env` or `/etc/<service>/api_key`, never echo in chat/tool output.
- If a user insists "this is the real key" but HTTP returns 404/empty, report the actual result—do not invent verification data.
