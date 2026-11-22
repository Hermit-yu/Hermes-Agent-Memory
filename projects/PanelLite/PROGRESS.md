# PanelLite 构建进度

## 决策（哥哥拍板 2026-11-23）
- 授权 **AGPL-3.0-only**（可读/复用 KPanel 源码，成品开源；推翻原计划"不抄码保持MIT"）
- 范围：先做扎实内核（经典面板 7 模块），桌面窗口模式后置
- 旧橘猫面板保留在线冻结，新面板可用后切流量删旧

## 已完成 —— 7 大内核模块全部交付 ✅
代码在 /opt/PanelLite，git 主干 11 commits，37 Go 文件 9782 行，build/vet/test 全绿。

| 模块 | 端点 | 实测真数据 |
|------|------|-----------|
| 概览 | /api/overview | CPU双采样/内存/磁盘/网络 |
| 认证 | login/logout/session | Argon2id+session+限速, 未登录401 |
| 系统 | processes/services/hostinfo | 50真实进程/65服务/真实时区 |
| 网站 | sites/nginx-status | 8真实站点+证书路径核对 |
| Docker只读 | docker/{containers,images,networks,volumes,stats} | 13容器+13镜像 |
| Docker写 | POST containers/{id}/action | 独立容器实测stop/start+白名单+401 |
| 文件 | /api/fs/* | 穿越攻击拦截+根锚定+mkdir/delete |
| 终端PTY | /api/terminal/* | creack/pty+30min空闲/8h硬+审计+全鉴权 |
| AI助手 | /api/ai/chat+sessions | 双provider真实回答+诚实降级+只读分析 |

## 团队分工（6 profile，全员 sensenova 绕 agnes 限流）
- 朴智妍(CTO)：统筹/派卡/端到端验收实测/worker卡死时代收尾
- 含恩静(架构)：内核架构文档+网站+文件+AI
- 朴素妍(全栈)：编译修复+命名规范化+系统管理
- 朴孝敏(测试)：系统管理(自审修复前端排序缺陷,真实浏览器复测)+Docker只读
- 李居丽(安全)：认证登录+Docker写+终端PTY
- 全宝蓝(DevOps)：Makefile install/docker-image+systemd unit模板

## CTO 端到端实测汇总（全真实数据，非造假）
- 认证：401→Argon2id→登录→真实数据全链
- Docker写：独立临时容器实测 stop(Exited137)/start(Up)/白名单拦rm/401，未碰生产
- 文件：/home/web/../../etc/passwd 穿越攻击正确拦截
- 网站：证书路径核对软链真实

## 待做
- 桌面窗口模式（后置）
- 二进制部署/切流量删旧橘猫面板
- 记忆仓库 code 快照（当前只同步文档）

## 排坑记录
- worker profile config 无 sensenova provider 定义 → 4 次崩溃 → 全员写 custom_providers
- agnes 免费档 429 → 全员切 sensenova
- 同 workspace 并行两卡互挤 → 改串行（link 父子依赖）
- 全栈朴素妍连续空转 → 改派其他成员
- worker 频繁 timed_out(18-25min) 但代码完整 → CTO 实测代收尾成常态
- CTO 误 go get 致 inconsistent vendoring → go mod vendor 修
