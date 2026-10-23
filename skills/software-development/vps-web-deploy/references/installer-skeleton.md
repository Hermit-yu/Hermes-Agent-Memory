# 一键 polyglot 安装器（Python API + Node web）跨 distro 安装器骨架 + 坑

适用：把 云瞳 这类「FastAPI + Next.js standalone + 常驻 node + cron watcher」整包，一键装到目标机（本机内网 / 远端 VPS，可 airgapped，x86_64 或 aarch64）。目标路径/架构/包管理器都不假设，靠 bundle 内预烘焙的依赖 + 按机探测。

## bundle 布局
```
yuntong-bundle/
  engine/            # watcher/fixer/scanner（python，跑在 cron）
  api/               # main.py auth.py requirements.txt
  web/.next/standalone/  # next build -o standalone 产物（build 机产出）
  node/bin/node      # 静态 node 运行时（按架构），非 apt
  wheels/            # 多 ABI 平铺池：cp310+cp313… 混放，pip --no-index 按目标机 Python 标签自动挑匹配 C 扩展；纯 py 轮共用
  install.sh
```
build 机先 `YUNTONG_API_HOST=<网关IP> YUNTONG_API_PORT=8891 npm run build`（rewrite 目标 build 时烘焙，见主 SKILL pitfall 11），再把 standalone 打进去。

## install.sh 关键节（骨架）
```bash
set -euo pipefail
BASE=/opt/yuntong                 # 目标机可不同；下面所有消费者都读它
export YUNTONG_HOME=$BASE         # ★ 引擎/systemd/cron/CLI 一律读这个，别硬编码路径
# HERE = bundle 根：install.sh 有两种布局——bundle 根布局（与 watcher/api/web 平级）或源仓布局（在 deploy/ 子目录）。
# 自判：脚本目录含 watcher+api+web → HERE=脚本目录；否则 HERE=父目录。写死 script_dir/.. 会让 bundle 根布局查不到
# $HERE/node / $HERE/wheels → 静默掉进 apt/NodeSource 兜底（见坑 6）。
VPY=$BASE/api/venv/bin/python
NODE=$BASE/node/bin/node

# 1) preflight：包管理器探测 + python 版本 + 架构匹配 + 端口空闲 + /opt 空闲
#    ★ 这些检查发货前先在目标机实跑一遍（含嵌套 python -c 版本守卫），
#      set -euo pipefail 下任一条写坏会在每台都死在 preflight。

# 2) 拷代码 + chmod +x $NODE（tar/zip 常掉 exec 位）+ 验 $NODE --version
#    拷 web 后、起服务前：按目标机 API 绑址 sed 重写 standalone 两个 manifest 的 rewrite destination
#    （中心机 build 烤死的是中心机网关 IP，见主 SKILL pitfall 11★ 多机发货 / 本参考坑 8）
#    ★ 别 rm -rf $BASE/data（运行时状态=客户数据，升级/重装只 mkdir -p + 缺则 seed，见坑 9）
# 3) venv 自愈：python3 -m venv $BASE/api/venv
#    在线：$VPY -m pip install -r requirements.txt
#    离线：$VPY -m pip install --no-index --find-links $HERE/wheels -r requirements.txt
#          （wheels=多 ABI 平铺池；缺目标 ABI 的 C 扩展 → 报『按目标 cpXX 重新 pip download』补救而非裸 fail；
#           发货前必在真实目标 ABI 上临时 venv 干跑复验，见坑 7）
# 4) 数据目录引导（cases.json=reputation.json 缺则建空）
# 5) systemd yuntong-api/web.service：ExecStart 用绝对路径的 $VPY / $NODE，
#    加 Environment=YUNTONG_HOME=$BASE（否则引擎读不到 base，静默指向旧 /root 路径）；
#    serve SSE 的单元加 TimeoutStopSec=15（restart 不卡 90s 排干长连接，见坑 10）
# 6) cron /etc/cron.d/yuntong-watcher：watcher/metrics 行都带 YUNTONG_HOME 前缀或 env
# 7) systemctl enable --now + daemon-reload
# 8) canary：curl -fsS http://127.0.0.1:8891/api/health 断言 payload 标记
```

## 坑（规则 + 为什么；1-5 首发，6-10 多机/离线/升级补充）
1. **引擎代码禁硬编码 base 路径。** 目标机 base 可变（/opt vs /root），架构可变。引擎全树 grep 掉 `/root/yuntong` 之类的字面量，改读 `$YUNTONG_HOME`（安装器导出，systemd `Environment=`、cron 行、CLI 启动都带上）。硬编码 `BASE="/root/yuntong"` 会在任何非 /root 目标上静默指到错误/不存在的数据目录——bundle 发货前 grep 全 engine 树确认无残留字面路径。
2. **node 用 bundle 内静态 binary，不 `apt install nodejs`。** apt 的 node 版本/特性随 distro 变，常 < `next build` 需要；静态 binary（node-vX-linux-x64|arm64）可复现。解包后必 `chmod +x`（归档常掉 exec 位）；用 `uname -m` 匹配架构，不匹配就拒（别 fallback）；装完验 `node --version`。跨机：x86 bundle 别给 aarch64 用，要么按架构出 bundle 要么该架构 `apt` 兜底。
3. **venv 装期自建，离线用 --no-index。** 别假设目标机 python == build 机 python（版本/deps 都不同）。airgapped 目标机 `pip install --no-index --find-links <bundle>/wheels`，bundle 里带 wheels；能联网就 `-r requirements.txt`。缺 wheels 时离线机会在 venv 步骤 fail——离线场景必须预先 build wheels 进 bundle。
4. **canary 探健康端点，不探进程态。** `systemctl is-active` 只证明进程活着，证明不了服务在听对端口/拿到对 env。canary 用 `curl -fsS http://127.0.0.1:<apiport>/api/health` 并断言 payload 里的标记（如 `"api_ok":true` / 机群在线数），curl 失败=安装失败。这能抓出「进程 up 但 base env 没导对/端口绑错」这类 is-active 永远抓不到的错。装完顺带 `curl -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/_next/static/chunks/<任一chunk>.js` 验静态资源 200（配合主 SKILL pitfall 12 的 static 补拷）。
5. **`set -euo pipefail` 下的 preflight 必须先对目标机实跑。** preflight 里的嵌套逻辑（尤其 python `-c` 的版本比较守卫、`ss -tln | grep` 端口探测、`df` 磁盘）一旦写坏，整台都会在 preflight 就 die，且症状像「装到一半莫名其妙退」。发货前在最低配目标机（Debian 13 / 无 node / /opt 空）实跑一次 preflight，确认每条探测分支都过。
6. **HERE 按双布局自判，别写死 `script_dir/..`。** install.sh 既从源仓 `deploy/` 跑、也从 bundle 根跑。若脚本目录含 watcher+api+web → HERE=脚本目录，否则 HERE=父目录。写死在新布局下让 `$HERE/node`、`$HERE/wheels` 查不到 → 明明 bundle 有 node 却静默去 apt 装 node。
7. **离线 wheels 用多 ABI 平铺池，发货前在真实目标 ABI 干跑复验。** C 扩展（pydantic_core/uvloop/httptools）锁 ABI：`pip download --python-version 3.13` 只出 cp313，给 3.10 目标机 no-candidate。正确姿势：按目标机各 Python 版各出一套 `cpXX` wheels **平铺**进同一 `wheels/` 池，pip 离线按目标机标签自动挑匹配 C 扩展（纯 py 轮共用）；缺目标 ABI → install.sh 报『按目标 cpXX 重新 pip download』而非裸 fail。发货前必在真实目标机建临时 venv `pip install --no-index --find-links <pool> -r requirements.txt` 干跑一次，`import` 关键包自检通过才算离线可用（用完删临时目录，别碰在跑服务）。
8. **中心 build 的 standalone 装到目标机后，按目标机绑址重写 manifest。** build 时烤死的 rewrite 目标=build 机网关 IP，`scp` 到每台目标机后仍指向 build 机（目标机 /api 代理全死、面板卡会话）。安装器拷 web 后 sed 重写 `.next/standalone/.next/routes-manifest.json` + `required-server-files.json` 的 `http://…/api/:path*` destination（主 SKILL pitfall 11★）。
9. **升级/重装保留 data/（运行时状态=客户数据）。** 代码目录可 `rm -rf` 重拷；`data/`（cases/reputation/events.db/metrics.db/auth）只 `mkdir -p` + 缺则 seed。`rm -rf $BASE/data` 在重装时=删客户库。
10. **airgapped 目标机预置静态 node，别指望 NodeSource 外网。** 系统 node < 18.18（Ubuntu 22.04 apt node=12.x）且无外网时 NodeSource `curl … | bash` 会 fail。治本：把 nodejs.org 的静态 node 20 tarball 解包进 bundle 的 `node/`（自带 libnode，比只拷单 binary 稳），static-binary 分支即通；apt/NodeSource 只做有外网机器的回退。

## 验收（对齐用户要求：可验证的最终反馈）
装完汇报：发行版、base 路径、API/Web service 状态、`/api/health` 结果、静态 chunk 200、node 版本、cron 行。全绿才算装完，半红逐项列出并给 `journalctl -u yuntong-api/web` 定位。卸载对称：`systemctl disable --now` + 删 systemd/cron，数据目录可留。
