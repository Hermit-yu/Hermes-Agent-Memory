# PanelLite 构建进度

## 决策（哥哥拍板 2026-11-23）
- 授权 AGPL-3.0-only（可读/复用 KPanel 源码，成品开源）
- 范围：先做扎实内核（经典面板 7 模块），桌面模式后置
- 旧橘猫面板保留在线冻结，新面板可用后切流量删旧

## 已完成（代码在 /opt/PanelLite，git 主干）
1. 双进程骨架 bin/paneld + bin/agent（build/vet 过）
2. 概览真数据闭环：internal/sysinfo 真读 /proc 双采样 → /api/overview → 前端渲染
3. 认证登录：Argon2id + session(HttpOnly/Secure/SameSite) + 登录限速 + 中间件鉴权（auth/store 测试过）
4. 系统管理：agent processes/services/hostinfo 真读 /proc + systemctl（50 进程/65 服务真实）
5. 网站 Nginx 管理：agent sites 真读 /home/web + nginx conf 解析 + 证书检测；/api/sites + /api/nginx-status

## CTO 端到端实测（真实数据，非造假）
- 认证：未登录 401 → Argon2id 登录 → 概览 CPU6.3%/8核/内存8GB → 进程50真实PID → 服务65 → hostinfo真实时区
- 网站：8 真实站点(default/hermes/komari/map/pass/sub/subs/www)，证书路径核对软链真实，诚实 warnings

## 团队分工（6 profile，全员 sensenova 绕 agnes 限流）
- 朴智妍(CTO)：统筹/派卡/验收实测
- 含恩静(架构)：内核架构文档 + 网站模块
- 朴素妍(全栈)：编译修复 + 命名规范化 + 系统管理 + Docker(进行中)
- 朴孝敏(测试)：系统管理(含前端排序箭头自审修复, 真实浏览器复测)
- 李居丽(安全)：认证登录模块
- 全宝蓝(DevOps)：Makefile install/docker-image + systemd unit 模板

## 进行中
- Docker 管理模块（朴素妍，容器/镜像/操作/stats 真读 Docker API）

## 待做
- 文件/终端/AI 模块
- 桌面窗口模式（后置）
