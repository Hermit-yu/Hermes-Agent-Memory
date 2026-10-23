# Laravel 面板在 PHP 容器内用 php -S 做临时验证的坑（云瞳 M3 面板验证实战沉淀）

验证载体定位：仅容器内网 IP + `php -S` 临时壳（路由走 router 脚本到 `public/index.php`，静态文件直出），**不挂公网**；正式落地按目标发行版出独立部署脚本（composer + systemd/apt），不锁定任何单一面板/环境（全域兼容方向）。

## layout 写法：统一 @extends + @yield
- 子页一律 `@extends('partials.layout')` + `@section('title', …)` + `@section('content') … @endsection`；layout 用 `@yield('title', 默认)` / `@yield('content')`。
- 不要混用 `@include('partials.layout', …)` 或组件式 `@component(…)/$slot`：`$slot` 只在组件渲染下注入，`@include` 路径不传 slot → 500 `Undefined variable $slot`；且组件 API 跨 Laravel 版本行为有差异。`@extends` 全版本无歧义，最稳。混写是 500 的常见根因：改 layout 时六页写法必须一次全改齐。
- 改完 layout 或任何 .blade.php 后清编译缓存——**但仅清磁盘不够，见下方 OPcache 一条**。

## 静态资源引用：根相对，别用 asset()
- Laravel `asset('css/x.css')` 会烧入 `APP_URL` 的 scheme。页面走 https、APP_URL 却是 `http://`（或按请求 Host 生成 http）时，`asset()` 产出 `http://…/x.css` → 浏览器按**混合内容**拦截全部 CSS/JS，页面"完全看不了"，而 curl 仍 200（curl 不拦混合内容）。
- 修法：静态资源一律用**根相对路径** `href="/css/x.css"`——浏览器按当前 https origin 自动补全，永不混合内容，也不写死域名（契合全域兼容）。顺带把 `.env` 的 `APP_URL` 对齐正式 https 域名，避免其它 asset 调用再踩雷。

## dev server 生命周期
- `docker exec` 会话退出会带走前台进程：`docker exec php php -S …` 要用 Hermes 后台跟踪（background=true）跑，或容器内 setsid；但别依赖会话内 `&` 自起——验证时就查端口。
- curl 返回 `000` = 连接被拒/进程没起（不是应用错）；`500` 才是应用层。000 时先查容器内 `ss -tlnp | grep <port>` 与 serve 日志再查代码。
- `pkill -f 'php -S'` / `pkill -f 'yuntong-router'` 会匹配**执行 pkill 的 shell 命令行本身**（sh -c 全文含该字样）→ 自身 shell 被 SIGTERM（exit 143），后续命令全不跑。pkill 放独立调用里做、模式避开当前 shell 的完整命令行，或按进程名精确匹配。

## 用 systemd 托管 docker 内 php -S
- unit `ExecStart=/usr/bin/docker exec -w <public 目录> php php -S 0.0.0.0:<port> <router.php>`：
  - **必须带 `-w <public 目录>`**，否则 docroot 不对，router `return false` 时静态 css/js 404。
  - 起 unit **前**先清掉所有手动 spawn 的同端口 `php -S` worker（`systemctl stop` 再 `docker exec php pkill -f router.php`），否则端口被占，unit 卡 `activating (auto-restart)` 循环、一直起不来。用 `ss -tlnp | grep <port>` 确认是 systemd 那份在监听。
- After/Requires=docker.service + Restart=always + `systemctl enable`（开机自启核验见 SKILL.md always-on）。

## OPcache 让改 .blade 不生效（最坑一条）
- PHP 8.x 常开 `opcache.enable=1` + `opcache.enable_cli=1`：编译视图缓存在**运行中 php -S 进程内存**里。改 .blade 源 + 磁盘 `rm -rf storage/framework/views/*` 后，服务仍吐旧页面（旧 CSS 链接、旧 layout）。
- 正确序列：`php artisan view:clear config:clear route:clear cache:clear` → 清光容器内 `php -S` → systemd 重启起全新进程 → 再验。仅清磁盘缓存、不重启 PHP 进程 = 白干。
- 快速判别：`curl 127.0.0.1:<port>`（绕过 nginx 一切）看渲染出的关键标记是不是新版；再查 `docker exec php php -r "echo ini_get('opcache.enable');"`。

## 验收看数据不看码
- 每页 200 只证明渲染通过；必须 grep 页面 HTML 断言真实数据（如 DB 里三台机器的异构发行版字符串、聚合黑名单 IP、kill-switch 状态），数据通了对得上才算『面板接上引擎』。
- 涉及前端资源/JS（图表、样式、交互）时，curl 200 不够：用无头浏览器渲染 + DOM 断言（`document.styleSheets` 数量、`canvas.width>0`、关键选择器 `.side/.kpi` 命中）确认真渲染。截图类临时产物用完即删，不在机器上留多余缓存（用户明确要求）。
- Laravel 500 根因从 `storage/logs/laravel.log` 抓：先看**时间戳/mtime**确认是当前报错还是旧日志残留（日志是追加的，历史异常会一直堆在文件里）；精确抓法 = 请求前记录文件 size，请求后 `tail -c +$((SZ+1))` 只看新写入段。
- 排查顺序：容器内 `php php -r "bootstrap; config('app.url'); url()->asset(...)"` 看运行态实际值，与磁盘源、编译视图三方对账，定位到底哪一层是旧的。