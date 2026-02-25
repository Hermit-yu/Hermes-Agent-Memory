# memory-engine 融合记录（INIT）

- 来源仓库：https://github.com/win4r/memory-lancedb-pro
- 引入策略：只学架构与工作流，不直接改变现有文件型记忆习惯
- 当前阶段：Phase A（骨架）

## 本次新增
- 目录骨架：`memory-echoDB/schema`、`memory-echoDB/indexes`
- 规划文档：`echodb-fusion/ours/memory-engine/PLAN.md`
- 同步脚本：`automation/echodb/sync.ps1`

## 风险控制
- indexes 仅存可再生文件（可删可重建）
- upstream 暂不落盘（等你确认是否 vendor）

---

## 融合记录（Round 2 / 2026-02-25）

- 来源仓库：https://github.com/win4r/memory-lancedb-pro
- 来源提交：`3df1fefc0c61857aef25ab4a6b6662139e76f1c6`
- 同步日期（Asia/Shanghai）：2026-02-25

### 本次变更

1. 建立上游可追溯快照目录：
   - `echodb-fusion/upstream/memory-lancedb-pro/README.md`
   - `echodb-fusion/upstream/memory-lancedb-pro/README_CN.md`
   - `echodb-fusion/upstream/memory-lancedb-pro/openclaw.plugin.json`
   - `echodb-fusion/upstream/memory-lancedb-pro/SNAPSHOT_META.md`
   - `echodb-fusion/upstream/memory-lancedb-pro/SOURCE_TREE.md`
   - `echodb-fusion/upstream/memory-lancedb-pro/FILE_MANIFEST.md`
   - `echodb-fusion/upstream/memory-lancedb-pro/LICENSE_INFO.md`

2. 补充我方融合文档：
   - `echodb-fusion/ours/memory-engine/UPSTREAM_FEATURE_MAP.md`
   - `echodb-fusion/ours/memory-engine/INTEGRATION_BACKLOG.md`

3. 同步更新结构说明：
   - `ECHODB_STRUCTURE.md`
   - `echodb-fusion/README.md`

### 差异与取舍

- 采用“文档快照 + 清单追溯”方式，不全量 vendor 上游源码，降低仓库噪声。
- 上游声明 MIT（package.json），但缺独立 LICENSE 文件，已单独记录风险。
- 维持我方原则：真相源仍是 markdown；索引层为可再生产物。

### 风险

- 上游未来若重构目录/补 LICENSE 正文，需要更新 `LICENSE_INFO.md` 与清单文件。
- Hybrid/Rerank/Scope 目前仍处于规划与分阶段实施，尚未进入完整运行态。

### 下一步

1. 执行 Phase B（先稳定 BM25 + scope 贯通）。
2. 补最小评估集，建立回归基线。
3. 在不污染真相源前提下推进向量检索与融合排序。

