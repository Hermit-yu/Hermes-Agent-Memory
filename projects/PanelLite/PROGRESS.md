# PanelLite 构建进度

## 决策（哥哥拍板 2026-11-23）
- 授权 AGPL-3.0-only（可读/复用 KPanel 源码，成品开源）
- 范围：先做扎实内核（经典面板：概览/系统/网站/Docker/文件/终端/AI），桌面模式后置
- 旧橘猫面板保留在线冻结，新面板可用后切流量删旧

## 已完成（代码在 /opt/PanelLite，git 主干）
1. 双进程骨架 bin/paneld + bin/agent（build/vet 过）
2. 概览真数据闭环：internal/sysinfo 真读 /proc 双采样 → /api/overview → 前端渲染
3. 认证登录：Argon2id + session(HttpOnly/Secure/SameSite) + 登录限速 + 中间件鉴权
4. 系统管理：agent processes/services/hostinfo 真读 /proc + systemctl

## CTO 端到端实测（真实数据，非造假）
- 未登录访问 401 → 登录（Argon2id）→ 概览 CPU6.3%/8核/内存8GB → 进程50个真实PID → 服务65个 → hostinfo真实时区内核

## 进行中
- 系统卡收尾（qa-hyomin 朴孝敏自审修复中）

## 待做
- 网站(Nginx)/Docker/文件/终端/AI 模块
- 桌面窗口模式（后置）
