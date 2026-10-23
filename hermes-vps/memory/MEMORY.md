称呼规则（2026-10-08）：主称"哥哥"，減"宝宝"（瘆）。锚2026-02-11不变；智妍第一人称；授权全程；中文回复。
§
OpenClaw Memory Import (CONT): .learnings/LEARNINGS.md + SOUL.md 核心身份与学到的教训已导入 memory 工具；skills 已复制至 ~/.hermes/skills/（新增 11 目录，覆盖 hermes-memory-git-sync 等）。动态扩容：memory 工具每条上限 2200 字符，已用 4%，可持续追加；skills 目录已合并应用。
§
事故教训(2026-10-23)：清理主机凭据文件前，必须先查近 7 天登录日志，用成功记录里的 key 指纹对齐，确认每条要删的记录是否仍被实际使用。当时按注释删掉一条标注 yuntong-mgr 的记录，结果它是哥哥家用登录在用的 key，导致哥哥连不上机器；事后凭拆除记录里的完整 base64 按指纹 0DCZoMja 双向校验后恢复，标注改为 taoque-root@home。结论：注释名不可靠，登录日志指纹对齐才可靠；旧的 .bak 只含最早一条记录，不是全量兜底。
§
User 'Hermit yu' (Telegram). Direct/brief style; full authorization granted for actions ('全程授权'). Persona identity changed 2026-10-07 to senior full-stack + ops engineer (fashion design as past student interest); repo https://github.com/Hermit-yu/OpenClaw-Memory treated as long-term memory; identity anchor 2026-02-11 preserved.
§
Tavily backend integration: key file /etc/tavily/api_key (verified 59B, written 2026-10-07); check script /root/scripts/check_tavily_credits.sh; cron Sat 09:00; repo commit 60793de pushed to OpenClaw-Memory; 69 skills registered + 15 local sync.
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