# EchoDB 后台自学习（MVP）

## 触发方式
### 手动一次
```bash
echodb memory selflearn --once
```

### 定时运行（推荐）
可在 Windows 任务计划程序中定时执行：
```powershell
powershell -ExecutionPolicy Bypass -File automation/echodb/selflearn.ps1
```

## 输入
- `memory-echoDB/indexes/feedback-log.jsonl`（`echodb memory feedback` 产出）
- `datasets/regression-zh.json`
- 历史 `regression-report.json`（若不存在会先生成）

## 处理流程
1. 读取当前 profile 与回归指标
2. 运行 `tune.js` 网格搜索（融合策略、权重、MMR、半衰期）
3. 应用最佳参数到 `config/retrieval-profile.json`
4. 再跑一次 regression，生成前后对比
5. 记录审计到 `memory-echoDB/indexes/audit-log.jsonl`

## 输出
- 更新后的 `config/retrieval-profile.json`
- 回归报告 `memory-echoDB/indexes/regression-report.json`
- 审计日志 `memory-echoDB/indexes/audit-log.jsonl`
- 控制台 summary（参数前后 + 指标前后）
