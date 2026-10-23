# services/honcho — 本地 Honcho stack 灾备镜像

自托管 Honcho（`/root/.honcho/profiles/local/` + docker 容器组 `honcho-local-*`）的配置与数据备份，供整机/容器销毁后重建。

## 内容
| 文件 | 来源 | 说明 |
|---|---|---|
| `docker-compose.yml` | `honcho start` 生成 | 容器编排（api/deriver/pgvector/redis） |
| `config.toml` | `honcho start` 复制 | 全量配置（deriver/summary/dialectic/dream/向量库） |
| `env.example` | `/root/.honcho/profiles/local/.env` 脱敏 | 键名+非敏感值保留；`AUTH_USE_AUTH`、`LLM_OPENAI_API_KEY` 已打码，恢复时填回 |
| `profile.json` | 同上 | 端口/镜像锁定 |
| `init.sql` | 同上 | 数据库初始化 |
| `hermes-honcho-config.json` | `/root/.hermes/honcho.json` 脱敏 | Hermes 侧 Honcho 插件配置（api_key 打码） |
| `snapshots/honcho-pg-20261023.dump` | `pg_dump -Fc` | 全量数据库快照（129 TOC 条目；479 messages / 476 embeddings / 467 queue） |

快照由 `docker exec honcho-local-database-1 pg_dump -U postgres -d postgres -Fc` 生成，
`pg_restore --list` 已校验可读。

## 恢复步骤
1. 容器环境就绪（docker + docker compose 可用）
2. 以 `env.example` 为底重建 `.env`，填回 `LLM_OPENAI_API_KEY` 等打码项
3. `docker compose -f docker-compose.yml up -d`（pgdata 卷从旧卷挂载，或先恢复快照）
4. 快照恢复：`docker exec -i honcho-local-database-1 pg_restore -U postgres -d postgres -c < snapshots/honcho-pg-20261023.dump`
5. Hermes 侧：将 `hermes-honcho-config.json` 复制回 `/root/.hermes/honcho.json` 并填回真实 `api_key`
6. 验证：`curl http://127.0.0.1:8000/health` + `SELECT count(*) FROM messages;`（预期 ≥479）

## 约定
- 本目录只放**脱敏**配置；真实密钥永远不进仓库
- 数据快照按日期追加（`honcho-pg-YYYYMMDD.dump`），旧的移 `archive/` 不删
- 相关技能：`honcho-local-service`（重建流程与验证方法）
