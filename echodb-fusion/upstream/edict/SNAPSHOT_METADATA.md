# Upstream Snapshot Metadata - edict

- 仓库：`https://github.com/cft0808/edict`
- 快照方式：`git clone --depth 1`
- 快照提交（commit）：`a4417abb565ad180c9419ce27fdc8fc5e6201704`
- 上游提交时间：`2026-02-25T00:29:39+08:00`
- 本地快照时间：`2026-02-26T01:04:01+08:00`
- 采样范围：README / LICENSE / 目录树与文件清单（未全量 vendor 二进制大文件）
- 用途：为 EchoDB 融合治理方案提供可追溯依据，不直接改动现有运行主链

## 可追溯校验命令

```bash
git ls-remote https://github.com/cft0808/edict HEAD
git clone --depth 1 https://github.com/cft0808/edict
cd edict
git rev-parse HEAD
git ls-files
```
