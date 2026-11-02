称呼规则（2026-10-08）：主称"哥哥"，減"宝宝"（瘆）。锚2026-02-11不变；智妍第一人称；授权全程；中文回复。
§
OpenClaw Memory Import (CONT): .learnings/LEARNINGS.md + SOUL.md 核心身份与学到的教训已导入 memory 工具；skills 已复制至 ~/.hermes/skills/（新增 11 目录，覆盖 hermes-memory-git-sync 等）。动态扩容：memory 工具每条上限 2200 字符，已用 4%，可持续追加；skills 目录已合并应用。
§
事故教训(2026-10-23)：清理主机凭据文件前，必须先查近 7 天登录日志，用成功记录里的 key 指纹对齐，确认每条要删的记录是否仍被实际使用。当时按注释删掉一条标注 yuntong-mgr 的记录，结果它是哥哥家用登录在用的 key，导致哥哥连不上机器；事后凭拆除记录里的完整 base64 按指纹 0DCZoMja 双向校验后恢复，标注改为 taoque-root@home。结论：注释名不可靠，登录日志指纹对齐才可靠；旧的 .bak 只含最早一条记录，不是全量兜底。
§
User 'Hermit yu' (Telegram). Direct/brief style; full authorization granted for actions ('全程授权'). Persona identity changed 2026-10-07 to senior full-stack + ops engineer (fashion design as past student interest); repo https://github.com/Hermit-yu/Hermes-Agent-Memory treated as long-term memory; identity anchor 2026-02-11 preserved.
§
Tavily backend integration: key file /etc/tavily/api_key (verified 59B, written 2026-10-07); check script /root/scripts/check_tavily_credits.sh; cron Sat 09:00; repo commit 60793de pushed to Hermes-Agent-Memory; 69 skills registered + 15 local sync.
§
实际操作工作区固定：/root/.hermes/Hermes-Agent-Memory/Workspace/（架构文件在父目录，操作/主题开发在 Workspace）；用户要求先完整阅读参考源码（如 solstice23/argon-theme 克隆至 Workspace/argon-theme-source/）再动手修改，反对直接在 /root 写新文件；当前项目名：墨白 (Ink-White / Mo-Bai)。
§
139.28.232.33 的 hysteria2 走 UDP 57689(QUIC); ufw 已放行 57689/udp。教训: ufw 改防火墙规则后必须当场 canary 验证(本次两次翻车: 139 误全拒/167 的 enable 被管道吞掉未生效), 未验证=未生效。watcher 端口事件需同时扫 TCP+UDP(ss -tlnp 与 -ulnp)。
§
云瞳终局载体上线(2026-10-13): FastAPI=/root/yuntong/api(systemd yuntong-api, venv基于系统py3.12, pip --target装入), Next.js=/root/yuntong/web(standalone, systemd yuntong-web), 均绑宿主docker网关172.20.0.1(非公网), ufw规则 'from 172.20.0.0/16 to any 8891,3000'; nginx conf指向172.20.0.1; PHP面板(172.18.0.3:8890, yuntong-php服务)保留做回滚兜底, 配置备份/home/web/conf.d/yuntong.taoque.top.conf.php-backup-20261012; node真实路径/root/.hermes/tools/node-26.7.0-linux-x64/bin/node。
§
云瞳平台 2026-10-23 本机遗留物整体拆除完毕，且用户要求不留任何后路：数据兜底 /root/backups/yuntong-final-20261023/(全库dump+crontab备份) 与治理 skill personal/yuntong-product-governance 均已按用户指令删除。本机现无任何 yuntong 实物(systemd/nginx/conf/证书/mysql库/cron/SSH密钥/凭据/日志/备份/skill 全清)，全机 find 扫描为空。systemd yuntong-api/web 早已不在本机；139 载体也已死(inactive、/opt/yuntong 不存在)。SSHD 加固 conf 改名 99-hardening.conf 保留(全局安全项，与云瞳无关)。DNS yuntong.taoque.top 仍指向 38.14.254.100，如需彻底下线另改 DNS。共享服务 nginx/php/mysql/redis/vaultwarden/subconv 完好，www/sub/subs/komari/pass 五域名站点正常。
§
方法论/流程/架构类准则默认蒸馏成跨项目底层 skill（现 = software-development/engineering-framework，KPanel 思想级蒸馏，AGPL 不抄码/字段名/JSON shape/文档措辞）；项目专属不变量才下沉项目内（云瞳=/root/yuntong/YUNTONG_RULES.md）。新方法论照此两层分，别锁进单项目 skill。
§
云瞳面板伺服拓扑：yuntongd 用 http.FileServer 直接伺服 web/dist/（无构建链，改源码即时生效、不用重启）；但可交付的 dist-bundle/*.tar.gz 是拷贝，改前端后必须 deploy/build-bundle.sh 重建否则 tarball 脱节。bundle 进 git（M5 先例）。
§
AI已接真模型agnes: 线上.env AI_PROVIDER=agnes/AI_MODEL=agnes-3.0-flash, key取环境变量HERMES_CUSTOM_APIHUB_AGNES_AI_COM_API_KEY, 端点 apihub.agnes-ai.com/v1/chat/completions, 须带浏览器UA绕WAF。审批后端M4(plan/approve/retest,execute fail-closed)。M7防火墙双层检测已交付(commit e17127e, 迁移13_v2_3_firewall.sql): 采集层firewall探针collect_all多层聚合(ufw/iptables/nft/fail2ban能采几层采几层,不短路); firewall_disabled升v2.0.0(任一层在防护即通过,全关才报,采不到不猜); 新增/api/evidence/push(agent token鉴权+类型白名单+5000字截断+服务端脱敏+同内容hash去重+content_b64通道供POSIX sh agent); agent.sh加fw_push; 前端labels加EV_SOURCE/审计字典。38/38测试过; 139真数据#193(ufw active+iptables -P INPUT DROP)喂detector trigger=false正确不报; 本地容器collect_probe(firewall)=unsupported兜底正确。坑: 判换行真假唯一可靠法=SQL LENGTH-LENGTH(REPLACE(content,CHAR(10),''))算真换行+CHAR(92)算字面反斜杠n数, 别信od/CLI肉眼的\n。下一步=第四优先级异常行为分析+隔离执行器验证。
§
PHP RCE(CVE-2026-109618/19)处置完(2026-10-22): 38.14 php容器 8.3.31→8.5.12(kjlion, 坑:新版listen回退TCP 9000, 已挂zz-socket.conf钉回socket); 139 ldnmp-php→8.5.12, compose备份/opt/ldnmp/docker-compose.yml.bak-20261022; 回滚锚点: 本机kjlion/php:8.3.31-rollback-20261022, 139 php:8.4.27-rollback-20261022; php74已stop+restart=no; 167已过期不续费不管了。
§
换机无缝恢复 kit 已封存(2026-10-23, Hermes-Agent-Memory 仓库): ops/RECOVERY-RUNBOOK.md=8步重建手册; 密钥全在 services/vault/hermes-secrets-20261023.tar.gz.enc (AES-256-CBC/PBKDF2, 13项: SSH/Telegram/LLM/acme/DB凭据), 密码离线存 /root/.hermes/cache/scratch/vault-password-20261023.txt(600,不入git); skills32+runtime/config.yaml+ops(systemd/ufw/nginx/ LDNMP compose, 密码已改${VAR})+web-mysql全库dump+honcho快照均已入仓。纪律: 明文密钥永不进git, 提交前 grep D3 全树扫; ufw 改完当场 canary 验证。换机后滚动: 新IP写 ops/dns-notes.txt + 旧私钥 GitHub 撤权。
§
交付质量门（2026-10-26 视频任务确立，跨任务适用）：成品类交付前必须多轮自审+迭代（抽帧/全量对账，修完复验）再交；自行获取的素材（配乐/参考）须核实版权并在成品中署名；成品与参考素材放同一目录、区别命名。
§
vp 工具链（Vite+，/root/.local/share/vite-plus/bin/vp）在哥哥的体系里正式命名为"全栈工具箱"：全栈编程的核心工具链，必须保留，任何时候不得删除（连同 ~/.cache/ms-playwright 浏览器缓存）。装好一次长期复用；删过 580M 的验证项目 vp-demo 但工具箱保留。相关 skill = software-development/vibestart-fullstack-coding（已同步此命名）。
§
仓颉(cangjie-skill)+女娲(nuwa-skill) 两 skill 已装 /root/.hermes/skills/ 全局: 仓颉=拆书/长内容蒸馏成可执行skill的元skill(RIA-TV++流水线, 需PyYAML+jsonschema+tiktoken已装, cangjie.py doctor 全绿); 女娲(huashu-nuwa)=造人/蒸馏人物思维框架的元skill(6-agent调研, quality_check.py/merge_research.py 可跑)。两者互咬: 仓颉产出的eval符合darwin格式。scratch 克隆已清(源: kangarooking/cangjie-skill, alchaincyf/nuwa-skill)。
§
倪海厦蒸馏 skill 完成(2026-10-28): /root/.hermes/skills/ni-haixia-perspective/ (SKILL.md 6/6过质量门 + references/research/01-06六维调研 + references/sources/ 514份一手md共5.7M, 含5部人纪/天纪/梁冬对话/斯坦福演讲/扶阳论坛/汉唐方剂/小编医案 + 医案PDF抽样)。来源=gitee nihaixia/hantang-nihaixia。坑: 质量脚本贪婪正则被正文里重复出现的"诚实边界"字样锁错位, 正文避免复述section名。
§
Skill 表述精简审计（2026-10-28，用 writing-for-agents 的杠杆）：93 个 SKILL.md 全扫。两类真实冗余=description 同义触发词堆叠 + 旧版本沉积。已修 cangjie-skill(511→147)、顶层 humanizer(529→131)；删掉 3 个沉积目录(personal v2.0.0、harness v1.1.0、顶层 humanizer v2.1.1)，备份在 /root/.hermes/skills-archive-20261028/removed-skills-20261028.tgz，creative/humanizer 2.5.1 已上位。假阳性不剪：notion/airtable 的 curl auth 头重复、self-improving 的 **Area** 行三模板共用、各 skill 的"不要/禁止"hard guardrail。writing-for-agents 的关键杠杆：description 是常驻指针每个词都花钱→触发词要 1 分支 1 词、砍同义重复、否定式改正向。
§
sn-* SenseNova技能库安装完成：37个skill放置于 /root/.hermes/skills/sn-*，来源 https://github.com/OpenSenseNova/SenseNova-Skills；共享 .env 在 /root/.hermes/skills/sn-env/.env 软链到每个目录；SN_API_KEY/SN_BASE_URL/SN_IMAGE_GEN_* 指向 apihub.agnes-ai.com/v1，key复用 HERMITES_CUSTOM_APIHUB_AGNES_AI_COM_API_KEY（51字符）。ffmpeg n9.0.1 已装(vp-code-video依赖)；Playwright chromium cache 在 ~/.cache/ms-playwright/（保留）；VP全栈工具箱在 /root/.local/share/vite-plus/bin/vp，禁删。
§
SenseNova-Skills 37个 sn-* skill 已装 /root/.hermes/skills/(2026-10-28): 深研4+分域搜索10+图像6+PPT流水线10+文档3+协作4+数据4。共享 env 在 sn-env/.env(SN_*=现有agnes端点key, 各sn-目录软链), pip依赖全装(httpx/pypdf/pptx/yfinance/mootdx/arxiv/librosa/faster-whisper等, 唯deepxiv-sdk模块名未装成功)。限制: sn-search-image需Serper key未配; 图像生成能否出图看agnes端点能力。长线任务(调研→报告→PPT→视频)优先用 sn- 流水线。
§
模型调用规则(2026-10-31,哥哥立): 主模型固定 agnes-3.0-flash 不变; SenseNova API key 在 hermes 密钥文件的 SENSENOVA_API_KEY 变量, aliases(sensenova/sensenova-flash/sensenova-img, base_url token.sensenova.cn/v1) 已写入 config.yaml。任务中可无需确认直接调 sensenova 聊天接口(sensenova-6.8-flash-lite, 已验证可用), 出图接口(sensenova-u1.5-lite)用时先小测, 用完回到主线 agnes, 不改 model.default。
§
TCP Window Optimizer (当前任务 / 环境事实): 工作目录 `/opt/TCP Window Optimizer/`; 交付文件夹名按项目走 `TCP-Window-Optimizer/`; 代码仓库 `https://github.com/Hermit-yu/taoqe` (main 分支, 提交 ~e7d3635), 与记忆仓库 `Hermes-Agent-Memory` 完全分开 (用户明确要求); 脚本结构: 主入口 `tcp-window-optimizer.sh` + `src/lib/*.sh` (共 9 模块: common/hwdetect/sysdetect/tcpcaps/netdetect/bdp/configmgmt/apply/report); 默认只读 (`--detect`); `--apply` 需 root + 确认 (`--yes`); 回滚仅删自己生成的 `sysctl.d/90-xxx.conf`; 数据源可覆盖 (`TWO_BASE_PROC`/`TWO_BASE_SYS`); 测速默认开启但受限 (curl ≤20MB/30s, `-o /dev/null` 不落盘, 失败不阻断), 关可 `TWO_DISABLE_SPEEDTEST=1` / `--no-speedtest`, 改目标/大小 `--speedtest-url`/`--speedtest-mb`; BDP = bw × rtt × 1000 / 8; 延迟 (`NET[rtt_ms]`) 必须纳入推荐计算并直接写入输出 (如 `延迟=0.8ms 信任度:medium`); 速率计算 `bytes*8/1000000/s` (已修 `/1000` 错误); 所有用户可见信息必须大白话直说, 无 `TCP_NET:` / `%s` 机器格式, 实测值直接嵌入中文句子; `set -e` 禁止, 只用 `set -u`; 每模块写完即 `bash -n` + `shellcheck -S error`; 关联数组引用必须带花括号 `${ARRAY[key]}`; 主脚本必加 `two_load_libs` 硬校验 (缺模块立即退 2 并打印修复指引, 不蒙混); 产物目录固定 `/opt/<TaskName>`, 路径通过 `SCRIPT_DIR` 推导; 测试覆盖 10 轮 (小内存≤512MB/高内存/高带宽/无 cpuinfo/无 meminfo/无 sysctl), 每轮验证报告含计算过程; 安全: MAC 只本地不泄露, `sysctl` 安全顺序不可调换 (备份 → 90- conf → 语法检查 → `sysctl -p` 只加载自己文件 → 逐项验证 → 失败自动回滚); 技能安装 `/root/.hermes/skills/` (169 个可用), `engineering-framework` (含 Bash 模块化参考 `references/bash-modular-sysctl.md`) 已验证覆盖本任务类; 记忆仓库 `Hermes-Agent-Memory` 未被此推修改; `taoqe` 仓库独立存代码.
§
网络优化项目交付标准（2026-11-01）：Network-VNO-AI v2.0 阶段 2 完成交付时，用户强制要求所有功能必须实际运行验证（菜单、CLI、JSON 有效、无机器文、备份/回滚、执行报告）并记录真实结果，不接受骨架/桩冒充交付。新增三项核心要求：实际收益优先（已合理输出 Level 0）；不强制 BBRv3（先检测能力）；性能闭环（基准→诊断→应用→重测→评价）为核心竞争力。测速真实记录（0 Mbps 实际执行，不虚构），记入 recommendations.json 基准参考。文件命名固定 /opt/Network-VNO-AI/（不混淆记忆与代码仓库）。