# Integration Backlog（Phase B/C/D）

> 目标：把 upstream 的可用能力按可执行任务拆解，不破坏现有文件型记忆习惯。

## Phase B：离线索引 MVP（可用优先）

### B-1 数据入索引规范化（daily + long-term）
- 输入：`memory-echoDB/daily/*.md`、`memory-echoDB/long-term/*.md`
- 输出：统一 `MemoryItem` JSONL（含 id/scope/text/time/source）
- 验收标准：
  - 任意样本文件可解析为结构化条目
  - 解析错误率 < 1%（按样本集统计）
  - 不改写原始 markdown 文件

### B-2 BM25 检索落地（稳定版）
- 输入：B-1 生成的 `MemoryItem`
- 输出：可重建 BM25 索引 + query topK 结果
- 验收标准：
  - `query -> top5/top10` 可稳定返回
  - 支持 scope 过滤（至少 global/agent/project）
  - 重建索引后结果波动在可接受范围（人工抽检）

### B-3 向量检索接入（可选 provider）
- 输入：B-1 `MemoryItem` + embedding 配置
- 输出：向量索引（本地可重建）
- 验收标准：
  - 能完成 embedding + upsert + topK
  - 配置缺失时优雅降级到 BM25-only
  - 不把 key/token 写入仓库

### B-4 融合排序（Hybrid 初版）
- 输入：BM25 候选、Vector 候选
- 输出：融合后的排序结果（含来源分数）
- 验收标准：
  - 至少支持加权融合或 RRF
  - 可配置 `vectorWeight`/`bm25Weight`
  - 返回结果可解释（日志或调试字段）

## Phase C：检索治理（质量优先）

### C-1 Adaptive Retrieval 触发判定
- 输入：用户 query + 上下文特征
- 输出：`retrieve=true/false` 判定
- 验收标准：
  - 寒暄/确认句检索触发率显著下降
  - 事实问答检索召回不明显下降（人工回归）

### C-2 Noise Filter 写入前清洗
- 输入：候选写入文本
- 输出：过滤后可入库条目
- 验收标准：
  - 重复、空洞、系统噪声明显减少
  - 过滤规则可配置、可关闭

### C-3 Recency/Decay/LengthNorm/MMR 打分治理
- 输入：Hybrid 候选集
- 输出：最终排序结果
- 验收标准：
  - 新近且高相关内容排名提升
  - 超长低信息密度文本不过度霸榜
  - 每个因子可独立开关与调参

### C-4 评估集与回归脚本
- 输入：典型 query 集合（中文为主）
- 输出：离线评估报告（召回/相关性/噪声率）
- 验收标准：
  - 每次改动可跑回归
  - 指标变化可追踪可解释

## Phase D：运维化与产品化

### D-1 统一 CLI：search/list/stats/reindex
- 输入：命令参数
- 输出：可读结果 + 结构化输出（可选 JSON）
- 验收标准：
  - 命令可在本地稳定执行
  - 错误提示明确（配置缺失/索引不存在等）

### D-2 forget/export 能力
- 输入：记忆 id / scope / 时间范围
- 输出：删除确认与导出文件
- 验收标准：
  - 删除操作可审计（日志/记录）
  - 导出结果可重导入

### D-3 索引重建与灾备流程
- 输入：真相源 markdown
- 输出：可重建索引 + 操作文档
- 验收标准：
  - 清空索引后可一键重建
  - 重建后核心检索能力恢复

### D-4 文档与结构收敛
- 输入：融合过程中的文档与脚本
- 输出：更新后的 README / 结构说明 / 操作手册
- 验收标准：
  - 新成员可按文档完成一次从 0 到可检索
  - 文档无失效路径与命令
