# PanelLite

对标 [KPanel](https://github.com/kejilion/KPanel) 的轻量 Linux 运维面板（独立实现）。

- **授权**: AGPL-3.0-only（与 KPanel 同族开源协议，通过网络提供服务须开源源码）
- **路线**: 完整开源，可读/可复用 KPanel 源码（AGPL 兼容）
- **范围**: 先做扎实内核 —— 经典面板（概览/系统/网站/Docker/文件/终端/AI），真数据绑定；桌面模式后置
- **架构**: Go 后端 + 宿主机 Agent（Unix socket）+ Vue3 前端（Vite 构建，静态内嵌单二进制）

> 参考源码镜像: `~/.hermes/Hermes-Agent-Memory/Workspace/kpanel-source` (KPanel v1.30.1-rc.1, AGPL)
