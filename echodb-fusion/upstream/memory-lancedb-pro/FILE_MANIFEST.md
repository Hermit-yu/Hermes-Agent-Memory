# 文件清单（upstream 快照）

## 已纳入本快照目录的原文文件

- `README.md`
- `README_CN.md`
- `openclaw.plugin.json`

## 上游仓库关键文件（用于追溯，不全量拷贝）

- `.gitignore`
- `.npmignore`
- `index.ts`
- `cli.ts`
- `package.json`
- `package-lock.json`
- `src/adaptive-retrieval.ts`
- `src/embedder.ts`
- `src/migrate.ts`
- `src/noise-filter.ts`
- `src/retriever.ts`
- `src/scopes.ts`
- `src/store.ts`
- `src/tools.ts`
- `skills/lesson/SKILL.md`

## 说明

- 上游仓库存在一个 zip 文件（非融合必需），本仓库未引入，避免大文件/运行态垃圾进入版本管理。
