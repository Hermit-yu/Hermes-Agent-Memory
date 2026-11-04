# 全量备份索引 (本体不入 git, 在本机 /data 分区下中文目录(名含"的"字, 4 字符, 勿手打)的 backup-20261105/ (中文父目录, 用 find 解析勿手打))
- 大文件实体: 12G rsync 活目录块 + 2.0G docker save + 31M 卷 + 2.9M pg_dump
- 校验: signatures/SHA256.*.gz 解压后逐块 sha256sum -c; 顶层 SHA256SUMS.txt
- honcho 恢复锚点: pg-baseline.txt (messages=685)
- 验收: judge-verdict-20261105.json (裁判模型 8/8 PASS, 双模型复核制度首战)
- 复原手册: ../RECOVERY-RUNBOOK.md
