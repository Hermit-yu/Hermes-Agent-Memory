---
name: vps-web-deploy
description: "VPS 自托管 web 服务挂域名+SSL（nginx 容器反代、certbot、compose 端口坑、验收两件套）。"
version: "1.0.0"
author: 朴智妍 / Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [deploy, nginx, ssl, certbot, docker-compose, vps]
    related_skills: [vps-security-audit, ziyan-governance]
---

# VPS Web 部署（本机既有 nginx 容器 + certbot）

## When to Use

- 用户要把 web 服务挂到 *.taoque.top 域名 + SSL（如 multica、honcho 及后续自托管服务）。
- 既有站点 nginx 容器反代配置、Let's Encrypt 签发/续期、compose 端口绑定问题。
- 完全卸载上述部署（逆向步骤见“卸载流程”）。

Class task: 把任意 web 服务挂到用户域名（*.taoque.top），走本机既有 nginx docker 容器反代 + Let's Encrypt，与现有站点并存。

## Always-on 规则
- 不破存量：并存部署，nginx 只 `docker exec nginx nginx -s reload`，不重启容器、不动其他站点。
- 验收两件套：新域名 `curl -w "%{http_code}" https://<domain>/` 不用 `-k` 返回 200（证书真实有效）；既有站点带原 Host 头复测仍返回原状态码。
- 用户要求部署完成后通过域名可正常访问才算完；部署后必须实际 curl 验证再报完成。
- 开机自启动核验：部署收尾必须盘全链 — 宿主 systemd 单元 `systemctl is-enabled`（enabled 才算数）+ 相关容器 RestartPolicy（always/unless-stopped）。跑起来 ≠ 重启后还在；宿主侧裸 `docker exec` 服务用 systemd unit 托管（After/Requires=docker.service + Restart=always），别靠会话跟踪进程。这是用户明令的基础项，漏一项就白部署。
- 浏览器级验收：curl 200 只证明服务端渲染成功，查不出混合内容拦截、资源被 block、JS 报错。用户报告"页面打不开/没样式"时，用无头浏览器真实渲染（截图 + DOM 断言：`document.styleSheets` 数量、canvas 是否画出、关键选择器命中）再下结论，别信 curl。用户偏好：截图/临时校验产物用完即删，不在机器上留多余缓存。

## 主机事实（已验证）
- web 网关 = `nginx` docker 容器（不是宿主 nginx）：站点配置 `/home/web/conf.d/*.conf`；证书 `/home/web/certs/`；ACME webroot `/home/web/letsencrypt`（= 容器内 `/var/www/letsencrypt`）。
- 宿主 `apt install certbot` 得到的 certbot 是宿主工具，直接可用；宿主自己的 nginx 包是旧容器镜像，不参与反代，别混淆。
- 宿主 docker 网桥 IP `172.17.0.1` = 容器→宿主网关，upstream 指向宿主服务时用 `172.17.0.1:<port>`。**但前提：nginx 容器必须连在 docker0 上**。nginx 容器实际可能在专用桥（如 br-* 172.20.0.1/16），此时 172.17.0.1 不可达。先 `docker inspect nginx` 查它挂的网络 + 网关 IP，宿主服务绑该网关节点，再 `ufw allow from <该网段> to any port <port>`（容器→宿主端口流量进 ufw INPUT，默认全拒；规则别加 `in on ens17`，流量走 br- 接口 + 源段匹配）。见 `references/host-service-via-nginx-container.md`。
- nginx 容器挂载映射（conf 必须写容器内路径）：/home/web/conf.d→/etc/nginx/conf.d，/home/web/certs→/etc/nginx/certs，/home/web/letsencrypt→/var/www/letsencrypt，/home/web/html→/var/www/html；htpasswd 等辅助文件放挂载目录内才对容器可见。
- 应用若在 nginx 同用户网络（web_default）的另一个容器里，upstream 可直连该容器 IP（先 `docker exec nginx curl http://<ip>:<port>` 验通），不必绕宿主 172.17.0.1。
- 站点代码也可直接放宿主 `/home/web/html/<domain>/`：该目录同时挂载进 nginx（→/var/www/html）与 php 容器，改文件即生效、**不用重建容器**；宿主 web 目录属主 uid 82 = 容器内 www-data（先 `docker exec php id` 确认实际 uid），新建站点目录要 `chown -R 82:82`。PHP 站走 fastcgi：`fastcgi_pass unix:/run/php/php-fpm.sock` + `fastcgi_param SCRIPT_FILENAME …/index.php`（照宿主既有站 conf 抄格式，如 www.taoque.top.conf）。

## 步骤
1. 应用服务（docker compose）：确认 healthy + 端口绑到 `0.0.0.0`（127.0.0.1 绑定其他容器不可达，见 pitfall 1）。
2. 写 `/home/web/conf.d/<domain>.conf`：upstream（172.17.0.1:port）+ 443 ssl 块（证书路径占位 /home/web/certs/<domain>_cert|key.pem）+ 80 块（ACME location root /var/www/letsencrypt + 其余 301）；WebSocket 路径加 `proxy_http_version 1.1` + `flush_interval -1`。避免同端口重复 server_name（会报 conflicting server name）。
3. 自签占位证书（openssl req -x509，1 天）放进 /home/web/certs/ 让 `docker exec nginx nginx -t` 通过 → reload。
4. `certbot certonly --webroot -w /home/web/letsencrypt -d <domain> --non-interactive --agree-tos --email <user>` → `cp /etc/letsencrypt/live/<domain>/fullchain.pem privkey.pem` 到 /home/web/certs/（cert 644 / key 600）→ reload。宿主 certbot 可能因 OS Python 升级而坏（OpenSSL `GEN_EMAIL` AttributeError）：改走 acme.sh 替代路径，配方见 `references/htpasswd-and-acmesh.md`。
5. 应用侧 .env 的公开地址三件套（FRONTEND_ORIGIN / app URL / public URL 同类变量）指向 https://<domain>，改后 `docker compose up -d`（保留卷）使新 env 生效。
6. 验收两件套 + 既有站点回归。

## 宿主格式 PHP 站（/home/web/html 站点 + php-fpm socket，零容器重建）

适用：PHP 后端（PDO + 静态 vanilla 前端）挂到既有 LDNMP 的 *.taoque.top，不动 docker compose、不重建 nginx/php 容器。

1. 建站点目录 `/home/web/html/<domain>/{index.html,app.js,style.css,api/,config/.env}`，`chown -R 82:82`；**.env 含 DB 密码必须单独收紧 `chown 82:82 && chmod 640`**（nginx worker 与 www-data 常同 uid，644 = 可被同 uid 进程或误配直接读）。
2. vhost 写 `/home/web/conf.d/<domain>.conf`（照宿主既有站格式）：80 块 = ACME location（root /var/www/letsencrypt）+ 其余 301 https；443 块 = ssl 证书 + `location /api/ { fastcgi_pass unix:/run/php/php-fpm.sock; fastcgi_param SCRIPT_FILENAME /var/www/html/<domain>/api/public/index.php; include fastcgi_params; }` + 静态 try_files。前端控制器靠 `REQUEST_URI` 路由时**不要**在 nginx 里 rewrite 路径，fastcgi_params 原样透传即可。
3. **必加 `location /config/ { deny all; }`**（挡 .env 被 HTTP 直接下载；uid 相同时这是真漏洞）；migrations/docs/.git 类目录一并 deny。验收时 `curl <域名>/config/.env` 必须 403。
4. DB 连接 host 用容器网络服务名（如 `DB_HOST=mysql`）：php-fpm 跑在 web 网络里，能解析 docker 网络名。上线前容器内测连一次（`docker exec -e P="$(grep '^DB_PASSWORD=' 站点.env | cut -d= -f2)" php php -r '新 PDO 连 mysql…'`）；DB 密码一律从容器 env（`docker exec mysql printenv MYSQL_ROOT_PASSWORD`）或 .env 读，不回显、不进 git。
5. 证书顺序（见 pitfall 18）：80 ACME 块先上 → `certbot certonly --webroot -w <webroot> -d <domain>`（宿主 certbot，webroot 路径照现有 renewal 配置抄）→ 证书实体同步进 /home/web/certs（见 pitfall 16/17）→ 加 443 块 → reload。
6. 验收：本机 `curl -H "Host: <domain>" https://127.0.0.1/`（含 /api/health 经 fastcgi socket）→ 外网真实域名 curl（`ssl_verify_result` 为 0）→ 既有站点回归 → .env 403。代码源仍留 git 仓库，`/home/web/html` 只是部署副本；配一个 sync 脚本（拷代码 + reload）防两处分叉。

## 卸载流程
删 conf + certs → `nginx -t` + reload → `docker compose down -v`（删卷）→ 删部署目录/CLI/宿主配置 → 专用 DB `DROP DATABASE` → **kill 残留进程并 ps 复验**（同 vps-security-audit pitfall 3）。

彻底拆除（单节点或多节点全删，如产品重写前清场）追加两条：
- **删前归档**：部署目录 + 系统配置（systemd unit、nginx conf、ufw 规则快照、服务运行时状态）tar 到中心机备份目录——「删」不等于「不可回滚」，大版本重写前必须有完整 tarball 兜底。
- **删后逐节点 canary**：`ss -tlnp` 与 `ss -ulnp`（TCP+UDP 都要扫，别漏隧道类 UDP 服务）确认目标端口已放、该节点上的**无关**服务（hysteria/VPN 等）未受影响、目录无残留；未过 canary 不算删完。

## Laravel/Blade 面板验证（临时验证载体）
在 PHP 容器里用 `php -S` + router 脚本验证 Laravel 面板的坑，全在 `references/laravel-panel-verification.md`：layout 统一用 `@extends + @yield`（最通用、跨版本零歧义，符合『全域兼容』方向）；改 layout 后必须清编译缓存；curl 000 先查进程；`pkill -f` 模式别匹配自身 shell；验收要看页面 HTML 里的真实数据而不只是 200。

## 自托管 Sub-Store（Node bundle 后端 + PWA 前端）
sub-store-org 是双 repo 栈：后端（Sub-Store，release 出自包含 node bundle，`runtime-manifest.json` 的 `npm:[]` = 零依赖，内置 node:sqlite）+ 独立 PWA 前端（Sub-Store-Front-End，Vite，`.env.production` 的 `VITE_API_URL` build 时烘焙）。后端仓库里没有前端，别找错。部署形态：bundle 跑 systemd 绑 nginx 容器所在网络网关（不露公网），前端 dist → `/home/web/html/<domain>/`，nginx 反代 `/api`/`/download`/`/share` 到网关 + 静态 + SPA 兜底，ufw 放行网关 /16 → 端口并从 nginx 容器内 canary，certbot webroot 签发 + 续签 deploy 钩子。完整配方、环境变量表、探活端点（`/api/utils/env`）与 PWA 强刷提醒见 `references/sub-store-node-stack.md`。

## Polyglot 自托管安装器（one-command bundle，跨 distro）
用于把 Python API + Node web 的整包一键装到目标机（本机 / 远端 VPS，可能 airgapped、x86_64 或 aarch64）。可复用安装器骨架 + 已踩过的 5 个坑（引擎硬编码路径、bundle 内静态 node、venv 自愈/离线、健康探测做 canary、preflight 必须真跑）见 `references/installer-skeleton.md`。要点：目标目录跨机不同（/opt vs /root），引擎代码一律读安装器导出的 base env（`YUNTONG_HOME`），systemd `Environment=`、cron 行、CLI 都要带上它；node 用 bundle 内按架构匹配的静态 binary（不 `apt install nodejs`），解包后 `chmod +x` 并验 `node --version`；venv 装期自建，离线机 `pip --no-index --find-links <bundle>/wheels`；canary 以 `curl /api/health` 断言 payload 标记（如 `"api_ok":true`），不是 `systemctl is-active`（进程活着 ≠ 服务对）；`set -euo pipefail` 下的 preflight 先对目标机实跑一遍再发货，嵌套 python `-c` 版本守卫写坏会每台都在 preflight 死。

## Pitfalls
1. compose `"127.0.0.1:3000:3000"` 让 nginx 容器打不到应用：127.0.0.1 只绑宿主回环；改 `0.0.0.0` 绑定后 `up -d`，再验证 `docker exec nginx curl http://172.17.0.1:<port>`。
2. 容器内 curl `localhost` / `host.docker.internal` 都不通宿主服务：用 172.17.0.1。
3. `docker compose restart <容器名>` 会报 no such service：compose 命令按服务名（查 `docker compose ps` / yml services 节，通常不带项目前缀）。
4. 只删文件不等于卸载（同 vps-security-audit）：二进制删了，daemon 进程还活着；卸载后 `ps` 复核。
5. 80 端口 ACME 挑战要求 80 块内 `location ^~ /.well-known/acme-challenge/` 与 301 并存，否则 certbot 验签失败。
6. nginx auth_basic 的 htpasswd 三坑：格式 `user:hash`（冒号前带空格 → 一律 401）；哈希用 `openssl passwd -5`（SHA-512 crypt，htpasswd 默认 bcrypt 不被 nginx 的 glibc crypt 识别 → 静默 401）；文件权限 644（worker 非 root，600 → 每请求 500，error.log 报 `open() failed (13: Permission denied)`）。排查阶梯与完整配方见 `references/htpasswd-and-acmesh.md`。
7. 写 /etc/ 下的系统文件（systemd unit 等）走 terminal heredoc：write_file 工具对 protected 路径直接拒写。
8. acme.sh 遇到未知参数会整条命令失败：新版无 `--no-cache`、无 `--install-hook`（hook 用 `--reloadcmd 'bash …'`），`--key-file`/`--fullchain-file` 必须双横线长参数。
9. OPcache 让清编译视图失效：PHP 进程内 opcache（`opcache.enable=1` + `enable_cli=1`）把编译好的 .blade 视图缓存在进程里，改源后磁盘 `rm -rf storage/framework/views/*` **不生效**，页面仍渲染旧内容。必须 `php artisan view:clear config:clear route:clear` **并**重启承载 PHP 的进程（systemd restart / 清光 `php -S` worker）让 opcache 拿不到旧编译件，再验证。症状：源正确、清过 views、curl 却仍是旧输出。
10. 混合内容静默打白页面：Laravel `asset()` 把 APP_URL 的 scheme 烧进 URL；https 页面里若生成为 `http://…/x.css`，浏览器按混合内容拦截 → CSS/JS 全失效、页面"完全看不了"，但 curl 照样 200（curl 不拦混合内容）。静态资源一律用**根相对路径** `/x.css`（浏览器按当前 https origin 自动补全，永不混合内容，也不写死域名）；顺手把 `.env` 的 `APP_URL` 改成正式 https 域名。
11. Next.js standalone 自托管（node server.js 常驻）：`rewrites` 的代理目标在 **build 时烘焙**进 server.js——上游地址必须用 env 注入（如 `YUNTONG_API_HOST`）且在 `npm run build` 时 export，事后改 env/重启无效，改地址要重 build。上游真实监听地址先 `ss -tln` 核实（宿主 docker 网桥网关 IP ≠ 127.0.0.1）；接反的症状是前端所有代理 API 路由 5xx、页面卡"验证会话…"，而 curl 直打 API 正常，极易误诊成前端 bug。★ **多机发货**：中心机 build 出的 standalone 把中心机网关 IP 烤死在产物里，`scp` 到每台目标机后仍指向中心机（目标机 /api 代理全 404/5xx、面板卡会话）。安装器在拷完 web、起服务**前**按目标机 API 实际绑址 `sed -i -E "s|http://[0-9.]+(:[0-9]+)?/api/:path\\*|http://$HOST:$PORT/api/:path*|g"` 重写 `.next/standalone/.next/routes-manifest.json` 与 `required-server-files.json` 的 rewrite destination（build 时已冻结，运行时 env 无效）。
12. Next.js standalone 部署缺 `.next/static`：`output: 'standalone'` 产物本身不含客户端 JS（静态 chunk 留在 `.next/static/`，不被拷进 standalone），直接跑 standalone/server.js 时所有 `/_next/static/**` 全部 404 → 前端拿不到任何脚本 → 页面永久停在服务端渲染的初始态（登录门卡"验证会话…"），而 curl 页面 HTML 仍 200，极易误诊成前端 JS bug。部署/安装器必须补拷：`cp -a .next/static standalone/.next/`（有 public 的也拷 `public/`），并在 systemd 的 WorkingDirectory 下验证 `curl /_next/static/chunks/任一chunk.js` 返回 200 才算静态资源到位。
13. 客户端会话门（鉴权 gate 的 fetch）必须带超时 + 失败态重试：服务重启/重建窗口里半死的 fetch 没有 timeout 会无限转圈，把全站卡在"验证中"。fetch 加 `AbortSignal.timeout(10000)`，网络失败渲染明确错误 + 重试按钮而非静默放行；重 build 重启后让用户强刷（旧 404 chunk 会被浏览器缓存住）。
14. SSE/长连接服务的 systemd 单元必加 `TimeoutStopSec=15`。uvicorn 提供 SSE 时 `systemctl restart` 卡在 'Waiting for connections to close'（排干长连接），systemd 默认 90s 才 KILL → 每次重启吊 90s、期间旧进程还占端口。任何 serve SSE/WebSocket/长 keep-alive 的常驻服务都配 `TimeoutStopSec`，到点强杀。
15. 安装器『全新装』安全 ≠『升级/重装』安全：deploy 段别 `rm -rf` 运行时状态目录（data/、auth.db、events/metrics db、cases.json）——重装一次=删客户库。代码目录（watcher/fixer/api/web）可 rm 重拷；状态目录只 `mkdir -p` + 缺则 seed（`[ -f x ] || echo '[]' > x`）。
16. 证书同步到 /home/web/certs 若用符号链接复制（`cp -P /etc/letsencrypt/live/…`）会拷出**悬空链接**（`../../archive/<domain>/…` 在宿主副本里不存在）→ `nginx -t` 失败 'cannot load certificate'。用 `cp -L` 解引用成实体文件（cert 644 / key 600），或连 `archive/` 一起 `cp -a` 后再 cp -P。
17. certbot 续签钩子的真目录是 `/etc/letsencrypt/renewal-hooks/deploy/`（宿主 cron 定期 `certbot renew` 自动执行）；`/home/web/certs/renewal-hooks/` 只是挂载树里的同名文件夹，certbot 不读——钩子写错目录等于没写。钩子内容照 pitfall 16 用 `cp -L` 同步实体 + `docker exec nginx nginx -s reload`。
18. 443 块引用新域名证书前必须先完成：80 块（含 ACME location）→ `nginx -t` + reload → certbot 签发。证书没签发前 443 块进不了配置（nginx -t 失败时 reload 被拒、旧配置继续跑——站不炸但部署卡住，且容易误判成其它问题）。
19. 验收脚本里 `curl -w 'HTTP=%{http_code}'` 输出是带前缀的整串，拿它和 `"200"` 直接 `==` 比对恒假（报红但实际成功）：要比对就用 `-w '%{http_code}'` 拿纯码。
20. 宿主格式 PHP 站改完代码同步后必须刷 OPcache：宿主 php-fpm 若设 `validate_timestamps=0`（永不重验文件），同步新代码后旧字节码继续伺服（症状：接口返回旧形状/旧版本、无报错、磁盘文件明明是对的）。同步脚本固化一行 `docker exec php sh -c 'pkill -USR2 -o php-fpm'`——USR2 优雅重载让新 worker 读新码，不中断站点。
21. PHP front controller 的 parse error = 全站死：`index.php` 里任何一处语法错误会让**所有**路由（包括 /api/health、/login）整体 500，整文件解析失败。改完任何 PHP 文件、同步前必须 `docker exec php php -l <容器内全路径>` 全量语法校验；遇 500 风暴先查 parse error（`docker exec php php -l`），别先怀疑业务逻辑。
22. hash 路由 SPA 部署后不重载 JS：浏览器只改 `location.hash` 不会拉新 bundle（内存里旧 bundle 继续跑），前端验收会误判"没生效"。部署/改前端后验收必须整页 `location.reload()` 或开新 tab 再断言页面行为。带 service worker 的 PWA 同理（sw.js 缓存旧 bundle），重新部署前端后验收要强刷/新 tab。
23. Vite 前端的 `VITE_*` 环境变量（如 `VITE_API_URL`）是 **build 时烘焙**进 bundle 的（import.meta.env 替换）——改值必须在 build 时 export，事后改 env / 重启无效（与 pitfall 11 的 Next.js rewrites 同族）。build 完 grep dist/ 确认目标域真的烘焙进去了（若只剩默认官方域，env 没进 build）。
24. mysql CLI 非交互输出会把 DB TEXT 里的真换行（0x0a）转义成字面 `\n` 两字符显示——od/肉眼查"内容里是不是字面反斜杠n"会被骗（本会话曾据此误判 agent 推送数据有 bug，实为显示层转义）。换行真假要用 SQL 算术定论：`LENGTH(col) - LENGTH(REPLACE(col, CHAR(10),''))` = 真换行数；`LENGTH(col) - LENGTH(REPLACE(col, CONCAT(CHAR(92),'n'),''))` = 字面 `\n` 数。解析器依赖换行时先跑这两个数再下结论。
25. 升级 PHP-FPM 镜像（tag 原地换内容）后，验收必须查到下游消费的具体产物而非容器 Up：FPM 走 unix socket 的部署（nginx `fastcgi_pass unix:/run/php/php-fpm.sock` + 共享卷），新版镜像可能把池 listen 回归 TCP 9000 → socket 消失、nginx 侧 502、容器日志却只有正常的 "ready to handle connections"（无错可报，极易误判为站点 bug）。升级后查 `ls` 共享卷里 socket 是否存在；丢了就挂 override 文件进 php-fpm.d（挂载点字母序要排在池配置之后才覆盖 listen）钉回 socket 路径，再 `up -d --force-recreate`。升级前给旧镜像打 tag 留回滚锚点（`docker tag $(docker inspect <c> --format '{{.Image}}') <name>:rollback-<date>`）。