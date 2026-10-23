# 宿主裸进程服务接入 nginx 容器反代（FastAPI/Next.js 终局载体配方）

## 场景
服务跑在宿主裸进程（systemd 托管），nginx 反代在 docker 容器里——容器默认到宿主端口被 ufw 全拒。适用：FastAPI/Node/Python 直接跑在宿主不想再套容器的场景。

## 步骤
1. **查 nginx 容器真实网络**：`docker inspect nginx --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{"\n"}}{{end}}'` + `docker network inspect <net> --format '{{.IPAM.Config}}'` 拿宿主侧网关 IP（如 172.20.0.1）。宿主侧多网桥（docker0/br-*）各管一段，**别假设是 172.17.0.1**，用哪个桥以 nginx 实际挂载为准。网关 IP 是 docker 内部地址，不上公网（公网口 ens* 上没有它）。
2. **宿主服务绑该网关 IP**（systemd 单元 ExecStart `--host 172.20.0.1`，Next.js 用 `Environment=HOSTNAME=172.20.0.1`）。不绑 127.0.0.1（容器内 127.0.0.1 是容器自己）。
3. **ufw 限源段放行**：`ufw allow from <网段> to any port <ports> proto tcp`（不加 `in on <iface>`——ufw 按源段匹配，加接口反而易绑错到 ens* 公网口而容器流量永远走 br- 接口）。**当场 canary**：`docker exec nginx wget -O- http://<网关>:<port>/health` 通即生效；不通查 `ufw status` 规则是否落在正确匹配。
4. **nginx conf**：proxy_pass 直接写字面网关 IP（`http://172.20.0.1:8891`），**不要用 `use;`/`resolver` 动态解析 127.0.0.1 的写法**（`use` 在 server 块非法，nginx -t 直接挂；且容器内 127.0.0.1 ≠ 宿主回环）。
5. 验证闭环：`docker exec nginx nginx -t` → reload → 正式域名 curl canary（带 basic auth）→ 浏览器侧验证。

## 本宿主已验证事实（2026-10-13）
- nginx 容器 = `kjlion/nginx:alpine`，挂多网络；yuntong 用 `beszelbridgedashboard_defaultweb_default`，宿主侧网关 **172.20.0.1**（br-1a3bb5e23411 接口）。
- 旧 PHP 面板走 `172.18.0.3:8890`（php 容器 IP，容器对容器直达）。
- 终局载体绑定：yuntong-api `172.20.0.1:8891`（uvicorn），yuntong-web `172.20.0.1:3000`（Next.js standalone），ufw 规则 `3000,8891/tcp ALLOW 172.20.0.0/16`。公网不可达：端口只绑 docker 桥 IP + ufw 源段双重限制。
- 自启动：`/etc/systemd/system/yuntong-api.service` + `yuntong-web.service`（均 enabled，Restart=always）。

## 坑（按翻车顺序）
1. **hermes 管的 python 建 venv 会装飞**：`python3 -m venv` 若 PATH 指向 hermes 自带 python（如 3.14），`pip install` 可能落到 hermes 管理环境而非 venv 的 site-packages（venv/bin 里连 pip/uvicorn 入口都没有）。修复：显式 `/usr/bin/python3 -m venv`（系统 3.12）重建 + `/usr/bin/python3 -m pip install --target=<venv>/lib/python3.x/site-packages fastapi 'uvicorn[standard]'`。验收：`env -i <venv>/bin/python -c 'import uvicorn'`（干净环境 = systemd 视角）必须过。systemd 单元 ExecStart 用 `venv/bin/python -m uvicorn`（console script 可能不存在，203/EXEC 就是它）。
2. **Next.js standalone 静态布局**：`output:'standalone'` 后产物在 `.next/standalone/`，需 `mkdir -p .next/standalone/.next && cp -r .next/static .next/standalone/.next/static`（注意是 `.next/standalone/.next/`，不是 `.next/standalone/static`）。systemd 的 WorkingDirectory=`.next/standalone`，ExecStart=`node server.js`，`Environment=PORT/HOSTNAME` 控制监听。
3. **node 真实路径**：`which node` 在交互 shell 里可能是 hermes 路径；systemd 单元里要写 `readlink -f $(which node)` 的绝对路径（本宿主 `/root/.hermes/tools/node-*/bin/node`）。
4. **浏览器 basic-auth 测试载体假象**：把凭据塞进 URL（`https://user:pw@host/`）时，页面内 `fetch('/api/...')` 会抛 `Request cannot be constructed from a URL that includes credentials` → 数据全卡"载入中"。真实用户浏览器走原生弹窗后自动带凭据，无此问题。自验时用 CDP `Network.setExtraHTTPHeaders` 注入 Authorization + 干净 URL 导航，别把测试载体假象当产品 bug。
5. **terminal 误判拦截**：`pkill -f` 匹配含自身 shell 的模式会自杀（SIGTERM 15）；`fuser -k`/`systemctl restart` 前缀的组合可能触发"long-lived server"误判——用 `ss -tlnp` 查 pid + 精确 `kill <pid>`，systemctl 操作单独一条发。
6. **ufw `in on ens17` 是陷阱**：容器流量走宿主 br-* 桥接口进 INPUT，`ufw allow in on ens17 from ...` 永远匹配不到；正确写法按源段 `ufw allow from 172.20.0.0/16 to any port X`。改完必须当场 canary（规矩）。
7. **venv 里跑 uvicorn 的 WorkingDirectory**：uvicorn 要能找到 main.py/模块，单元里 WorkingDirectory 必须指到应用目录，否则 `-m uvicorn main:app` 报 No module named main。
8. **域名没有对应 server 块 → 请求落 `default_server`（常挂一个远期自签占位证书）→ 浏览器报「连接不安全」，但真实 LE fullchain 其实有效、key 也匹配。** 根因不是证书坏，是 vhost 不存在。诊断顺序：先 `openssl s_client -connect <host>:443 -servername <域名> | openssl x509 -noout -subject -issuer -dates` 看解析出来的是谁的证书（自签占位 vs 该域名的 LE CA），再查 `/home/web/conf.d/` 里有没有该域名的 conf。修：给域名写独立 vhost（80 301 到 443；443 ssl 挂 LE fullchain+key，`proxy_pass` 指网关 IP），`nginx -t` + reload。canary 双验：`openssl s_client` 显示该域名 CA 且 `Verification: OK`，浏览器侧 `window.isSecureContext === true`。
9. **SSE 长连接挂在反代后要 `proxy_buffering off` + `proxy_http_version 1.1` + `Upgrade`/`Connection`（`$connection_upgrade` map）+ 抬 `proxy_read_timeout`/`proxy_send_timeout` 到分钟级**，否则实时流停在「连接中」、探活只能拿 000。EventSource 带不了自定义 header，token 只能走 `?session=`；服务端连接建立先 flush 一帧注释帧（`: connected`）让探活即时拿到 200/401。改 conf 后 `docker exec nginx nginx -t && nginx -s reload` 再 canary 首帧。

## 回滚
PHP 面板保留在 `172.18.0.3:8890`（yuntong-php systemd 服务），nginx 配置备份在 `/home/web/conf.d/yuntong.taoque.top.conf.php-backup-YYYYMMDD`。回滚 = 恢复备份 conf + `docker exec nginx nginx -s reload`，全程不停 PHP 服务。
