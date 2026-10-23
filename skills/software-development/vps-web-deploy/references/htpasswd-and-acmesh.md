# nginx basic auth（htpasswd）配方 + acme.sh 替代 certbot

## htpasswd for nginx auth_basic
生成（openssl 是可靠的哈希源；PHP 的 crypt 模块 3.13 起被移除，别用 PHP 验证）：
```bash
PW="<明文>"
H=$(openssl passwd -5 -salt <user> "$PW")   # SHA-512 crypt
echo "user:$H" > /home/web/html/.htpasswd-<name>
chmod 644 /home/web/html/.htpasswd-<name>
```
三坑（都踩过）：
- 格式必须 `user:hash` — 冒号前带空格（`user : hash`）nginx 解析不出来，正确密码也一律 401。
- 算法必须 glibc crypt 可解：SHA-512（`openssl passwd -5`）。htpasswd 默认生成 bcrypt（$2y$），nginx 不认 → 每个密码都 401 且无任何日志。
- 权限 644：nginx worker 非 root，600 时每个请求 500，`docker exec nginx tail /var/log/nginx/error.log` 报 `[crit] open() ".../.htpasswd" failed (13: Permission denied)`。文件内只有哈希无明文，644 安全。
- 文件必须放在 nginx 容器的挂载目录里（/home/web/html → 容器 /var/www/html）。
排查阶梯：无凭证 401 = 认证生效且文件可读（好信号）；有凭证 500 + error.log crit open = 权限/路径；正确密码恒 401 = 哈希算法或格式错。conf 里：`auth_basic "X"; auth_basic_user_file /var/www/html/.htpasswd-<name>;`。

## acme.sh（宿主 certbot 坏时的替代，已验证可用）
宿主 certbot 会因 OS Python 升级坏掉（`OpenSSL.crypto` 的 `GEN_EMAIL` AttributeError，报各种 import 错误但签不出证）：
```bash
curl -sS https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh install -m
# 签发（webroot 走 80 口 ACME 挑战目录）
/root/.acme.sh/acme.sh --issue -d <domain> -w /home/web/letsencrypt --keylength 2048 --server letsencrypt
# 安装证书 + 续期钩子（新目录：/root/.acme.sh/<domain>/）
cat > /root/.acme.sh/<domain>/installed.sh <<'EOF'
#!/usr/bin/env bash
D=$(dirname $(realpath $0))
cp "$D/fullchain.cer" /home/web/certs/<domain>_cert.pem
cp "$D/<domain>.key" /home/web/certs/<domain>_key.pem
chmod 644 /home/web/certs/<domain>_cert.pem; chmod 600 /home/web/certs/<domain>_key.pem
docker exec nginx nginx -t 2>/dev/null && docker exec nginx nginx -s reload
EOF
chmod +x /root/.acme.sh/<domain>/installed.sh
/root/.acme.sh/acme.sh --install-cert -d <domain> \
  --key-file /root/.acme.sh/<domain>/<domain>.key \
  --fullchain-file /root/.acme.sh/<domain>/fullchain.cer \
  --reloadcmd 'bash /root/.acme.sh/<domain>/installed.sh'
/root/.acme.sh/acme.sh --install-cronjob   # 自动续期
```
参数陷阱：未知参数直接整条失败 — `--no-cache` 已不存在；`--install-hook` 被新版拒绝（改用 `--reloadcmd`）；`-fullchain-file` 单横线报 Unknown parameter，必须 `--fullchain-file`。签发成功输出 "Your cert is in: ..." 才算过，失败时不要往 /home/web/certs/ 里 cp（不存在的文件只会让 nginx -t 挂掉）。
