---
name: hermes-memory-git-sync
description: 把 VPS Hermes（智妍）的运行时记忆与核心人格同步到 Hermes-Agent-Memory 私有仓库，供灾难恢复使用。完整 SOUL 母本由仓库维护，脚本不会覆盖。内置 D3 拦截、幂等提交与冲突中止。
---

# Hermes Memory Git Sync

## 用途

备份落在 `Hermit-yu/Hermes-Agent-Memory` 私有仓库的 `hermes-vps/`：

- `hermes-vps/memory/` ← `/root/.hermes/memories/`
- `hermes-vps/SOUL.core.md` ← `/root/.hermes/SOUL.md`（每轮加载的短版核心人格）
- `hermes-vps/SOUL.md` ← 核心人格兼容镜像
- `hermes-vps/SOUL.master.md` = 完整人格母本，由 Hermes-Agent-Memory 维护；自动同步脚本**不得覆盖**

排除：`*.bak*`、`*.lock`、`*.db*`。

## 权威来源

- 人格母本、治理和项目规则：`governance/SOURCE-OF-TRUTH.md`
- 运行时人格：`hermes-vps/SOUL.core.md`
- 完整人格：`hermes-vps/SOUL.master.md`

## 手动执行

```bash
bash /root/.hermes/scripts/hermes-memory-sync.sh "可选自定义 commit 信息"
```

克隆/脚本缺失时（重装、迁移、或仓库目录被清过）：先 `ssh -T git@github.com` 验认证，`git clone` 到 `/root/Hermes-Agent-Memory`，再按本 skill 的映射语义手动执行（rsync 记忆目录带 `--delete` + 排除项、拷核心 SOUL 两份、母本不动、D3 扫描后 commit + pull --rebase + push）；跑完把 `scripts/hermes-memory-sync.sh` 与定时任务重建回来，避免下次再缺。

## 定时

系统 crontab 每天 UTC 20:00（北京 04:00）自动运行一次，日志：
`/root/.hermes/logs/memory-sync.log`

## 护栏

- D3 命中即中止，绝不 push。
- 无变更不产生空提交。
- 不 force-push。
- `pull --rebase` 冲突时自动 `--abort` 并交人工处理。
- 自动脚本只同步 `memory/`、`SOUL.core.md` 与兼容 `SOUL.md`，不修改 `SOUL.master.md`。
- 本同步属用户已授权的日常外部同步；若用户撤销，应停止定时任务。
- 访问前必须验证 SSH (`ssh -T git@github.com`); 若 crawl/extract 失败，必须报告失败并切换到 SSH/clone 验证，不能假装成功读取。

## 恢复方式

```bash
cd /root/Hermes-Agent-Memory && git pull
cp hermes-vps/memory/MEMORY.md /root/.hermes/memories/MEMORY.md
cp hermes-vps/memory/USER.md /root/.hermes/memories/USER.md
cp hermes-vps/SOUL.core.md /root/.hermes/SOUL.md
systemctl restart hermes-gateway
```

恢复前先备份现有文件。需要恢复完整人格资料时读取 `SOUL.master.md`，但不要直接把母本替换为每轮运行文件，除非用户明确要求回退到完整加载模式。

## 灾备镜像扩展位（用户要求把 Honcho 等本地服务数据一并入库时）

同步范围不止 `hermes-vps/`；本地服务的可恢复镜像落到仓库 `services/<服务名>/`，约定：
- **脱敏配置**：真实 `.env` 不进仓；生成 `env.example`（键名+非敏感值保留，仅 API_KEY/TOKEN/SECRET/PASSWORD 类打码 `***REDACTED***`——别过度打码端口/模型名）；harness 侧配置（如 `honcho.json`）复制后把 `api_key` 打码。
- **数据快照**：关系库用 `pg_dump -Fc` 压缩格式（几十 MB 数据→几百 KB），存 `snapshots/<名>-<YYYYMMDD>.dump`，先 `pg_restore --list` 校验可读再入库。
- **README 写恢复步骤**：重建顺序 + 回填密钥 + 验证查询（如 `SELECT count(*)`），引用相关技能名。
- 入库前对改动目录跑 D3 敏感串扫描（pat 同护栏），命中即 abort 不推。

## 对称校验（verify 双轴，换机可复原的证明）

灾备是否"双边对称"不靠口头，靠 `hermes-vps/symmetry/verify.py` 实跑；全 ✓ 才提交，证据落 `symmetry/MANIFEST.json`（随仓库提交）。轴不是逐字节相等：
- **L→R 可复原**：本地每个持久文件（排除运行态噪声/可重建项）在仓库有同路径同内容副本。
- **R→L 无孤儿**：仓库里每个文件都能映射回本地一个真实路径（restore 时知道落哪）。

条目按"恢复语义"分模式，别全当逐字节镜像：
- `MIRROR` 持久目录（memory/cron/state/skills…）；`FILE` 单文件；`MANIFEST` 大体积可重装件（agent 本体/tools，登记精确版本即对称，不入 git）；`SNAPSHOT` 点时转储（pg_dump，只要求"仓库有转储+本地有源"）；`ENCRYPTED` 密钥包（只断言 `.enc` 在仓 + 能解密回读，值不回显；**别**再跨查一份可能过期的内部 manifest，重建密钥包后旧 manifest 会让这条假报 mismatch）。重排密钥包顺序应为 manifest→tar→encrypt。
- **`DERIVED`（关键）**：可再生派生缓存，如 curator 内容寻址缓存 `/root/.hermes/.curator_backups`（由 skills 派生、换机可重建、非恢复源）。**必须 DERIVED 而非 MIRROR**：只要求"本地有、新机可重建"，绝不逐字节拷进 git。WHY：这类缓存会把已拆除项目的配方连同其中烤进去的**活凭据**一起前向复制，MIRROR 就把明文密钥送进 git；restore 侧只 `mkdir -p .../blobs` 占位即可。

D3 命中甄别（提交前逐条定性再决定清/留，别一刀切）：
- **真凭据**（高熵/base64 口令、`BEGIN ... PRIVATE KEY` 实体）→ 清除或降 DERIVED/.gitignore 挡出，绝不提交。
- **扫描器自身正则**（sync 脚本里 `PAT='...ghp_...BEGIN PRIVATE KEY...'` 那行）与**占位符**（文档里 `ghp_xx...xxxx`、`sk-***`）→ 假阳性，可提交。
- 拿不准一条 base64 是不是活口令：拿它探真实服务（如 `docker exec <mysql容器> mysql -uroot -p'<它>' -e 'SELECT 1'`），能连上=活凭据，必须挡出 git 并建议用户轮换。
- 挡出后确认它从没进历史：`git log -S '<片段>' --all` 应返回空；非空需重写历史。

## 迁移完备性审计（"全对称"绿了 ≠ 换机能把我完整复原）

verify 全 ✓ 只证明**已列的条目**彼此对称，不证明**清单本身完整**。被问"这样够不够完整迁移/换机复原"时，先做完备性审计再回答，别拿"verify 全绿"当结论——绿的是覆盖范围，不是覆盖全否。

审计步骤：
1. `du -sh /root/.hermes/* /root/.hermes/.*` 列出活目录**全部**顶层条目（含隐藏文件 + sqlite 库）。
2. 逐个判断：这条持久件在 verify 的 ENTRIES 里有没有？没有就是缺口。
3. 每个缺口定性，决定怎么补：
   - **持久数据**（丢了就丢我状态）→ 必须可复原，加 verify 条目 + restore 步。典型：`state.db`（消息/会话=本体连续性）、`sessions/`、**顶层** `MEMORY.md`/`USER.md`。
   - **凭据类** → 一律进加密 vault（新增一项 + 重建 manifest→tar→encrypt），绝不进明文 git。典型：`auth.json`（LLM 凭据池）。
   - **机器级**（新 VPS 默认没有、不补会静默坏）→ 捕获进仓 + restore 重建。典型：系统 crontab（`acme.sh --cron` 续证，漏了证书会静默过期）、systemd unit。
   - **可重装 / 运行态 / 空框架** → 跳过：`cache/`、`logs/`、`lsp/`、`installs/`、`tools/`（manifest 已登记可重装）、`kanban.db`/`shared-state.db`（0 行空表）、`.lock`/`.sock`/`*.db-wal`。
4. 补完条目后**再**跑 verify 到全 ✓，并把新增文件与新步骤同步进 `restore.sh` 与 `RECOVERY-RUNBOOK.md`（runbook 的清单行也要跟上，别只改 verify）。

配了 verify 仍会翻的坑：
- **同名两份 ≠ 同一份**：`/root/.hermes/MEMORY.md`（顶层 Layer-1，粘进提示词顶）与 `memories/MEMORY.md`（memory 工具库）内容不同。`diff -q` 确认；两份都 live 就都镜像，别只备一份。
- **`state` 条目 ≠ state.db**：镜像 12K 的 `state/` 目录那条不是 73M 的 `state.db` SQLite 库。命名分开，别以为有 `state` 条目就覆盖了库。
- **活 SQLite 库用 WAL 感知备份，别 `cp`**：`sqlite3 db ".backup /tmp/x"`（一致性快照、含 WAL）再 `gzip -c`；恢复前 `gunzip` + `sqlite3 x 'select count(*) from messages'` 验可读。`cp` 一个开着 WAL 的库会拷出不一致状态。
- **凭据池/密钥重包后 MANIFEST 会过期**：加项后按 manifest→tar→encrypt 重排，并 `sha256sum -c` 解包回读自洽，别拿旧 manifest 断言（重建后旧 manifest 会让 ENCRYPTED 条假报 mismatch）。

## 仓库改名 / URL 迁移（GitHub 改 repo 名时）

远端改名后，恢复链路里所有硬编码引用会集体指向旧名而断掉，缺一个换机复原就失败。重对齐清单：
1. `git remote set-url origin <新地址>`，再 `git push` 验证（远端会回显 "This repository moved"）。
2. 本地 clone 目录 `mv` 改名，并同步 `verify.py` 的 `REPO=`、`restore.sh` 的 `REPO=` 默认路径、sync 脚本的 `REPO=`。
3. runbook/RECOVERY 的 `git clone ... && cd ...` 两行改成新名。
4. 全树文本替换旧名→新名（仓内文件 + `/root/.hermes` 活侧镜像目录 + SOUL），**别动**运行态 log/cache/sessions/curator。
5. 改完跑 verify：若某 `MIRROR` 条 GAP，多半是"仓侧正文已改、活侧没改"（或反之）→ 把活侧对应镜像目录做同样的文本替换，再跑，直到全 ✓。

## 失败处理

- exit 2：D3 命中，清除敏感内容后再运行。
- exit 3：rebase 冲突，人工处理。
