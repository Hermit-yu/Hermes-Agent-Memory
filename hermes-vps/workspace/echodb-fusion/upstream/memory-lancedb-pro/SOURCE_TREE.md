# 关键源码目录清单（upstream）

## 顶层关键目录

- `src/`：核心检索、存储、过滤、作用域实现
- `skills/lesson/`：技能文档与接入说明

## 顶层关键文件

- `index.ts`：插件入口导出
- `cli.ts`：管理与运维命令入口
- `openclaw.plugin.json`：插件声明与配置 schema
- `package.json`：依赖与许可证声明
- `README.md` / `README_CN.md`：功能与接入文档

## src 文件清单

- `src/store.ts`
- `src/retriever.ts`
- `src/adaptive-retrieval.ts`
- `src/noise-filter.ts`
- `src/scopes.ts`
- `src/embedder.ts`
- `src/migrate.ts`
- `src/tools.ts`
