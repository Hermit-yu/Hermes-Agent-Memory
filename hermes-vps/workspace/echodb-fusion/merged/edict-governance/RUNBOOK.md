# EDICT 执行 Runbook

## 1) 申请（Request）
1. 中书省生成申请单：operation/scope/risk_level/rollback_plan。
2. 调用 `preflight-check.ps1` 进行预检。
3. 预检为 deny 时不得进入执行。

## 2) 审批（Approval）
1. 按 `APPROVAL_MATRIX.md` 匹配审批链。
2. L2 需单签；L3 需双签（two-man rule）。
3. 生成审批 token 并写入审计日志。

## 3) 执行（Execution）
1. 尚书省派发兵部/工部执行。
2. 严格按审批 scope 执行，不得扩项。
3. 执行结果（成功/失败）实时记录。

## 4) 审计（Audit）
1. 执行后调用 `audit-log.ps1` 记录关键字段。
2. 刑部抽查 L3 和紧急豁免任务。
3. 都察院按周做监督复核。

## 5) 回滚（Rollback）
1. 触发条件：失败、误发、越权、审计缺失。
2. 按 `ROLLBACK_PLAYBOOK.md` 对应场景回滚。
3. 回滚后追加审计并产出复盘结论。

## 最小可执行命令
- `powershell -ExecutionPolicy Bypass -File automation/edict/preflight-check.ps1 -Operation workspace.edit.batch -RiskLevel L2 -ApprovalToken "APPROVED"`
- `powershell -ExecutionPolicy Bypass -File automation/edict/audit-log.ps1 -Operation workspace.edit.batch -RiskLevel L2 -Decision allow -Reason "approved" -Actor "shangshu_dispatcher" -RequestId "REQ-001" -Status executed`