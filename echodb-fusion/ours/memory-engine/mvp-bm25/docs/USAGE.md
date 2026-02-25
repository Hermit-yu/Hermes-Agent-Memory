# EchoDB BM25 使用说明（中文）

## 命令总览

```bash
echodb memory reindex
echodb memory search "<查询词>" --topK 20
echodb memory stats
```

- `reindex`：先规范化生成 `memory-items.jsonl`，再构建 BM25 索引
- `search`：查询索引并返回最相关结果
- `stats`：输出索引统计信息（docs / terms / avgdl / sources / indexCreatedAt）
- `--topK`：返回条数（默认 20）

## 数据来源与规范化

固定读取以下路径：

- `memory-echoDB/daily/*.md`
- `memory-echoDB/long-term/*.md`

规范化输出：

- `memory-echoDB/indexes/memory-items.jsonl`

MemoryItem 字段（当前最小集合）：

- `id`
- `scope`
- `type`
- `title`
- `content`
- `sourcePath`
- `createdAt`
- `updatedAt`（可选）
- `tags`（可选，当前未自动填充）
- `importance`（默认 `0.5`）

作用域策略 v0：

- `long-term/*` => `global`
- `daily/*` => `agent:main`

## 索引产物

固定写入：

- `memory-echoDB/indexes/bm25-index.json`

该目录已在 `.gitignore` 配置为可忽略（保留 `.gitkeep`）。

## 两种运行方式

### 方式一：Node 脚本

```bash
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory reindex
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory search "项目进展" --topK 20
node echodb-fusion/ours/memory-engine/mvp-bm25/bin/echodb-memory.js memory stats
```

### 方式二：系统命令包装

包装器位置：

- `automation/echodb/echodb.ps1`
- `automation/echodb/echodb.cmd`

把 `automation/echodb` 加到 PATH 后即可直接用 `echodb`。

## 输出格式

### search 结果

每条结果包含：

- `score`：BM25 分数（越高相关性越高）
- `source`：命中来源文件
- `preview`：内容预览

### stats 结果

- `docs`：索引文档数
- `terms`：词项数（df 键数量）
- `avgdl`：平均文档长度
- `sources`：来源文件去重计数
- `indexCreatedAt`：索引生成时间
