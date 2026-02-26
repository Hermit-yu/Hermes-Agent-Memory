# EXECUTION CADENCE（执行节奏）

## Daily（日常）
- 记录当日关键任务与异常
- 补全审计字段
- 检查是否存在未审批高风险动作
- 执行“稳态优先”最小增量：每次仅推进 1-2 项可验证改动

## 每次运行规范（稳态优先）
1. 先检查上次进度与未完成清单
2. 每次只做 1-2 个可验证增量
3. 必须落地到项目目录文件（报告/模板/脚本/指标）
4. 维护“自上次双端同步后轮次计数”（每轮 +1）
5. 轮次累计到 5 时，统一执行一次 Git 提交 + 推送（双端同步），并在项目文档记录同步点
6. 默认静默执行：不发送例行进展；仅在“大轮次完成/封版/阶段切换（如 R06 收官、进入下一阶段）”时，输出一份简洁总结到主会话
7. 遇阻塞或异常可提前同步并上报，写明“阻塞原因 + 影响范围 + 解法 + 预计解除时间”

## Weekly（周）
- 复盘三指标：审批时延、驳回率、误放行率
- 跑一轮回归（L1/L2/L3）
- 产出下周优化清单（>=3条）

## Monthly（月）
- 策略阈值调优
- 扩展回归和检索数据集
- 输出月报（改进/遗留/下月重点）

## Quarterly（季）
- 评估路线图阶段达成度
- 结构升级（治理策略、脚本、文档体系）
- 对齐下一阶段目标

## Silent Reporting Policy (2026-02-26 V9)
- Default: keep routine micro-progress silent; do not send regular progress broadcasts.
- Before each run, first check previous progress and unresolved carryover list.
- Continue background micro-increments (1-2 verifiable increments per run) and land files every run.
- Maintain a round counter since last dual-end sync; execute one unified Git commit+push only when the counter reaches 5.
- If blocked/abnormal, allow early sync and immediate report with: cause, impact, mitigation, ETA.
- Only send one concise summary to main session when a major round is finished/closed, a release is frozen, or a stage transition starts.


