# 自托管 Sub-Store（Node bundle 后端 + PWA 前端，挂 *.taoque.top + SSL）

适用：本机 LDNMP（nginx 容器反代 + certbot）上部署 Sub-Store 订阅管理面板。已验证配方（subs.taoque.top 先例）。

## 仓库拓扑（必知：前后端是两个独立 repo）
- 后端：`sub-store-org/Sub-Store`（master）。release 资产里的 `sub-store.bundle.js` + `runtime-manifest.json` 是自包含后端 runtime：`npm: []`（零 npm 依赖）、`requiresEval: true`、用内置 `node:sqlite`、testedNode 24.x（Node 26 兼容，直接跑）。`sub-store-0/1.min.js`、`sub-store-parser.loon.min.js`、`cron-sync-artifacts.min.js` 是浏览器侧模块/代理 App 用，不是服务端入口——别拿错文件当后端跑。
- 前端：`sub-store-org/Sub-Store-Front-End`（Vite + Vue PWA，带 sw.js）。**后端仓库里没有前端 dist**（旧版 web/ 目录已拆走）；官方前端是 sub-store.vercel.app，自托管必须自己 build 前端 repo。
- 后端路由挂在根路径：`/api/...`、`/download/...`、`/share/...`；前端 PWA 的 navigateFallbackDenylist 就是这三组前缀——nginx 反代规则照抄这三个前缀。
- 前端默认后端地址来自 `import.meta.env.VITE_API_URL`（.env.production 默认 `https://sub.store`）；用户也可在页面里运行时改（localStorage），烘焙值只是默认。

## 部署配方（按序）
1. 拉 release：`sub-store.bundle.js` → `/opt/sub-store/bin/`（配 runtime-manifest.json），数据目录 `/opt/sub-store/data`（node:sqlite 建在此，勿 rm 重装）。
2. 试跑探活：`SUB_STORE_BACKEND_API_HOST=<网关IP> SUB_STORE_BACKEND_API_PORT=<port> SUB_STORE_DATA_BASE_PATH=... SUB_STORE_CORS_ALLOWED_ORIGINS=https://<domain> node bundle`；`GET /` 返回 200 + 引导 JSON（"后端的响应…"）即后端正常，`/api/utils/env` 是探活端点。
3. systemd unit（走 terminal heredoc，write_file 拒 /etc）：`ExecStart=<node绝对路径> /opt/sub-store/bin/sub-store.bundle.js`（node 在 /root/.hermes/tools/ 下要写绝对路径），`Environment=` 行照上表，`Restart=always`、`After/Requires=docker.service`、`WantedBy=multi-user.target`。node 版本按仓库 .node-version（24.x）核对，本机 node 兼容即可。
4. 绑址：绑 nginx 容器所在网络的**网关 IP**（本机 nginx 在 web_default，网关 172.18.0.1），不绑 127.0.0.1、不露公网。`ufw allow from 172.18.0.0/16 to any port <port> proto tcp`（不带 in on 接口），然后 canary：`docker exec nginx wget -qO- -T5 http://<网关>:<port>/api/utils/env` 出 JSON 才算通。
5. 前端 build：clone 前端 repo → `npm i -g pnpm` → `pnpm install` → `VITE_API_URL=https://<domain> pnpm exec vite build`（直接跑 vite build 可跳过 vue-tsc 类型检查；**VITE_API_URL 必须 build 时 export，烘焙进 bundle**）。build 完 grep dist/ 确认目标域已烘焙、只剩官方域残留说明 env 没进。
6. dist 部署 → `/home/web/html/<domain>/`，`chown -R 82:82`。index.html 资源是根相对路径（/index.js、/favicon.svg），无混合内容。
7. nginx conf（`/home/web/conf.d/<domain>.conf`）：80 块 = ACME location（root /var/www/letsencrypt）+ 301；443 块 = ssl 证书（/etc/nginx/certs/live/<domain>/）+ `root /var/www/html/<domain>` + `location ~ ^/(api|download|share)/ { proxy_pass http://<网关>:<port>; }`（带 X-Forwarded-* + proxy_http_version 1.1）+ 静态扩展名 location 直走本地 + `try_files $uri $uri/ /index.html` SPA 兜底。证书顺序照 SKILL.md pitfall 18：80 块先上 → certbot 签发 → 证书实体 cp -L 进 /home/web/certs/live/<domain>/ → 443 块 → reload。续签 deploy 钩子照 yuntong 先例写 `/etc/letsencrypt/renewal-hooks/deploy/zz-<domain>-sync.sh`（cp -L + chmod + docker exec nginx reload）。
8. 验收：外网 `curl -w ssl_verify_result` 为 0；`/` 200；`/api/utils/env` 经 https 反代返回 status:success；`/index.js` 200；既有站点回归。PWA 带 sw.js：每次重新部署前端后让用户强刷/新 tab（旧 service worker 会伺服旧 bundle）。

## 坑（Sub-Store 专属）
- 后端 `/` 直接返回引导 JSON 而非前端页面——别把它当"前端坏了"，前端是独立 PWA，后端只伺服 API（`/` 的引导文案也明示了这点）。
- 后端 bundle 里 `SUB_STORE_CORS_ALLOWED_ORIGINS` 默认指官方域；自托管必须设成本域，否则前端跨域读后端接口会被 CORS 挡（同源部署时设了也无害）。
- 前后端版本独立演进（后端 2.x bundle vs 前端 2.3x PWA），同 release 周期内互兼容即可；后端 README 有最低前端 API 版本说明，大版本跳变先看 CHANGELOG。
