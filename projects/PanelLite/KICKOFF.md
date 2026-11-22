# PanelLite 启动简报（全员）

## 目标
对标 KPanel 的轻量 Linux 运维面板，独立项目 PanelLite，放 /opt/PanelLite/。

## 三大已定决策（CTO拍板，勿改）
1. **授权 AGPL-3.0-only**（已确认）。可读/可复用 KPanel 源码（AGPL兼容）。成品须开源。
2. **范围**：先做扎实内核 = 经典面板（概览/系统/网站/Docker/文件/终端/AI），真数据绑定；桌面窗口模式后置。
3. **旧橘猫面板**：保留在线但冻结，不投新功能；PanelLite 可用后再切流量删旧。

## 关键路径
- KPanel 源码镜像（AGPL，可读可复用）：/root/.hermes/Hermes-Agent-Memory/Workspace/kpanel-source
  - 后端 Go 1.27.4，module kejilion/kejilion-panel
  - 双进程：cmd/paneld（面板web）+ cmd/kejilion-agent（宿主机agent，Unix socket）
  - internal/ 领域包：agent/auth/monitoring/dockerx/filemanager/hostpty/ai/appmarket/notification/... 30个
  - 前端：web/src Vue3+TS，31个视图，router.ts/stores/theme/i18n
- PanelLite 项目根：/opt/PanelLite/（已 git init + AGPL LICENSE）
- 参考官网：https://kpanel.kejilion.sh/ ；演示：https://panel.kejilion.pro/

## 工程约束（全员）
- 真实优先：无真实数据源的模块诚实标"依赖未就绪"，绝不造假。
- 安全门禁：Web非特权、Agent走Unix socket结构化命令、PTY独立授权有界生命周期、审计。
- 复用KPanel代码时保留其版权声明（AGPL传染），自研部分归PanelLite。
- 交付摘要写 /home/coding team/reports/。

## 参考旧资产（可复用经验，不必须）
- 旧橘猫面板 /opt/OrangeCatPanel（Go agent+panel+sampler三进程架构，可参考其真实宿主采集逻辑）
- 已验证可用的运维环境：本机有Docker、nginx(/home/web)、systemd
