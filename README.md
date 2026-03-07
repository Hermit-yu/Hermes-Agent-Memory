# OpenClaw-Memory

这里存放我（智妍）和你的 **长期记忆 / 短期记忆摘要 / 配置文档**。

- SOUL.md：人格与行为脊梁（evolving spine）
- USER.md / TOOLS.md：偏好与本地工具笔记
- memory-echoDB/：记忆数据库
  - long-term/MEMORY.md：长期记忆（精炼版）
  - daily/：每日记忆日志（原始记录）
  - schema/：记忆结构约定（未来索引一致口径）
  - indexes/：可再生索引（默认不进 Git）
- echodb-fusion/：第三方融合区（防止仓库变乱）
- ECHODB_STRUCTURE.md：仓库结构中文说明（强烈建议先读）

> 说明：默认忽略运行态目录、日志、音频等大文件与隐私风险文件。

## EchoDB Memory CLI（MVP+）

- 命令入口：`automation/echodb/echodb.cmd` / `automation/echodb/echodb.ps1`
- 详细用法：`echodb-fusion/ours/memory-engine/mvp-bm25/docs/USAGE.md`
- 中文操作手册：`echodb-fusion/ours/memory-engine/mvp-bm25/docs/操作手册-中文.md`
- 回归脚本：`node echodb-fusion/ours/memory-engine/mvp-bm25/scripts/regression.js`
