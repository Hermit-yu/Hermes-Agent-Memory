# 宿主 LDNMP PHP 站部署配方（/home/web/html + php-fpm socket）

针对本机 LDNMP（nginx + php + mysql 容器，挂载 /home/web/{html,conf.d,certs,letsencrypt}）。SKILL.md 的『宿主格式 PHP 站』节是主流程；本文件是可照抄的具体配方。

## 目录/权限基线
- 站点目录 `/home/web/html/<domain>/`，属主 `82:82`（宿主 uid 82 = 容器 www-data；动手前 `docker exec php id` 复核）。
- 普通文件 644、目录 755；`config/.env` 单独 `640`（含 DB root 密码）。
- 容器视角路径：`/var/www/html/<domain>/`；vhost 里 fastcgi 写容器路径。

## vhost 骨架（照抄改域名）
```nginx
server {                      # 80：ACME + 跳转
    listen 80; listen [::]:80;
    server_name <domain>;
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt; default_type "text/plain"; try_files $uri =404;
    }
    location /config/ { deny all; }
    location ~ ^/(migrations|deploy|docs|\.git)/ { deny all; }
    location / { return 301 https://$host$request_uri; }
}
server {                      # 443：证书签发后才加进来（见 pitfall 18）
    listen 443 ssl; listen [::]:443 ssl; http2 on;
    server_name <domain>;
    ssl_certificate     /etc/nginx/certs/live/<domain>/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/<domain>/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3; ssl_session_timeout 1d; ssl_session_cache shared:SSL:10m;
    location ^~ /.well-known/acme-challenge/ { root /var/www/letsencrypt; default_type "text/plain"; try_files $uri =404; }
    location /config/ { deny all; }
    location ~ ^/(migrations|deploy|docs|\.git)/ { deny all; }
    root /var/www/html/<domain>;
    index index.html;
    location /api/ {
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME /var/www/html/<domain>/api/public/index.php;
        include fastcgi_params;
    }
    location / { try_files $uri $uri/ /index.html; }
    client_max_body_size 10m;
}
```
- 前端控制器用 `$_SERVER['REQUEST_URI']` 解析路由时，**不要**在 nginx 里 `rewrite ^/api/(.*) …`，fastcgi_params 透传即可（nginx -T 后 curl 一个带路径的 API 验证 200）。
- vhost 改完：`docker exec nginx nginx -t`（失败会报悬空证书等）→ `docker exec nginx nginx -s reload`。

## 证书
- 签发：`certbot certonly --webroot -w <webroot> -d <domain> --non-interactive --agree-tos`（宿主 certbot；webroot 与账号照 `/etc/letsencrypt/renewal/*.conf` 现有配置抄，别猜）。
- 同步宿主副本：`cp -L /etc/letsencrypt/live/<domain>/{fullchain,privkey}.pem /home/web/certs/live/<domain>/`（+ archive 一起 `cp -a`；`cp -P` 会拷出悬空链接）。
- 续签钩子：`/etc/letsencrypt/renewal-hooks/deploy/zz-<domain>-sync.sh`（cp -L 两文件 + `docker exec nginx nginx -s reload`，chmod +x）。

## 数据库
- 容器内 PHP 连 docker 网络的 mysql：`DB_HOST=mysql`（服务名可解析）。
- 上线前容器内测连：
```bash
P=$(grep '^DB_PASSWORD=' /home/web/html/<domain>/config/.env | cut -d= -f2)
docker exec -e YT_P="$P" php php -r '$p=getenv("YT_P");new PDO("mysql:host=mysql;dbname=yuntong","root",$p);echo "OK\n";'
```
- 迁移文件幂等（IF NOT EXISTS / INSERT IGNORE），灌库带 `--default-character-set=utf8mb4`，连跑两遍 exit=0 才算幂等。

## 种子管理员
- bcrypt 是单向可入库的（非明文）：`docker run --rm <php镜像> php -r "echo password_hash('初始密码', PASSWORD_BCRYPT);"` 生成 hash 放进迁移，用条件更新做幂等（hash 已是该值则不动，用户改密后重跑不覆盖）。
- 迁移里别放占位 hash 就提交——占位 hash 导致登录永远 401，这是假成功的坑。

## 验收清单（全过才算上线）
- [ ] 本机：`curl -H "Host: <domain>" http://127.0.0.1/`（80→301）+ `https://127.0.0.1/` 首页字节数 = 前端 index.html 大小 + `/api/health` 200
- [ ] 外网：`curl https://<domain>/` `ssl_verify_result=0`、health 200、登录 200
- [ ] `https://<domain>/config/.env` → 403
- [ ] 既有站点带原 Host 头回归码不变
- [ ] git：.env 未跟踪（`git ls-files | grep config/.env` 为空）；vhost + sync 脚本入库防分叉
