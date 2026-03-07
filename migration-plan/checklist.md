# 迁移执行清单（草稿）

> 后续我们可以边执行边打勾/补充，这里先列出核心步骤。

## 0. 规划阶段

- [ ] 确认新服务器配置（CPU/内存/磁盘/系统版本）。
- [ ] 确认迁移窗口与回滚策略（例如：保留旧环境至少 1~3 个月）。

## 1. 旧环境导出

- [ ] 打包工作区 `E:\OpenClawAI_bot\workspace`（排除不需要迁移的缓存/大文件）。
  - 建议保留：
    - [ ] `SOUL.md`
    - [ ] `USER.md`
    - [ ] `TOOLS.md`
    - [ ] `AGENTS.md`
    - [ ] `memory/`（至少最近几个月）
    - [ ] `projects/`（尤其是 `智妍的自我提升计划`）
    - [ ] `skills/`（如有自定义技能）
    - [ ] `automation/`（脚本、自评/治理任务）
- [ ] 导出 OpenClaw 配置：`C:\Users\22363\.openclaw\openclaw.json`
  - [ ] 在迁移包中仅保留结构，不直接携带敏感 token（新机上重新配置）。
- [ ] 将上述内容压缩存放到 `migration-plan/backup/`，如：
  - `backup/workspace-YYYYMMDD.zip`
  - `backup/openclaw-config-YYYYMMDD.json`

## 2. 新环境初始化

- [ ] 在新服务器上安装所需依赖（Node/npm/pnpm、curl 等）。
- [ ] 安装 OpenClaw，对应版本尽量与旧环境一致。
- [ ] 创建工作目录（例如 `/opt/openclaw/workspace`），解压 workspace 包。
- [ ] 根据旧机 `openclaw.json` 结构，合并生成新机配置：
  - [ ] 保留/更新：模型设置、agents、cron 结构。
  - [ ] 在新机上重新配置渠道 token（如 Telegram bot）。

## 3. 新环境验证

- [ ] 在新机上运行：`openclaw status`，确认网关与渠道健康。
- [ ] 运行：`openclaw security audit --deep`，确认无 critical 风险。
- [ ] 从新环境向 Telegram 发送一条测试消息，确认收发正常。
- [ ] 检查人格/记忆是否加载正常（SOUL/USER/MEMORY 生效）。

## 4. 灰度期（并行运行）

- [ ] 旧机继续作为主通道使用，新机仅做部分任务测试（如 cron、自评脚本）。
- [ ] 观察新机资源占用、稳定性、行为一致性。

## 5. 正式切换

- [ ] 将 Telegram 等主通道配置指向新机网关。
- [ ] 停止旧机上的 OpenClaw gateway/相关服务，避免重复响应。
- [ ] 在新机上观察一段时间，确认一切正常。

## 6. 回滚与归档

- [ ] 保留旧机数据/环境作为回滚备用（设定保留期限，如 1~3 个月）。
- [ ] 期满后，如无回滚需求，可考虑：
  - [ ] 再做一次完整备份归档。
  - [ ] 关闭旧机服务或挪作他用。

> 后续我们可以根据实际执行情况，在本清单中增加具体命令、注意事项和实际执行日期。
