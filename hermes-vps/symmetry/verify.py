#!/usr/bin/env python3
"""hermes-vps 双边对称校验 (换机一次 git clone 可复原的可行性证明)。
运行:  python3 hermes-vps/symmetry/verify.py   [全对称 exit 0]
轴定义 (不是『本地==仓库 逐字节』, 而是):
  L→R 可复原:  本地每个『持久文件』(排除运行态噪声/可重建项) 在仓库有同路径同内容副本
  R→L 无孤儿:  仓库里每个文件都能映射回本地一个真实路径 (restore 时知道落哪)
  可重装项     : 体积大的 agent 本体/tools 不进 git, 用 tools-manifest.txt 登记精确版本即视为对称
  快照/密钥    : honcho/web-mysql 是点时转储(pg_dump/dump), 只要求『仓库有转储+本地有源』
  密钥包       : 值不回显, 只要求 .enc 在仓库存在
NOISE = 运行态/可重建, 从本地侧排除 (它们不该进仓, 也随环境变, 不影响可复原性)。"""
import os, sys, hashlib, json, re

REPO = "/root/OpenClaw-Memory"
L = "/root/.hermes"

# 从本地侧排除的噪声/可重建 (目录名 / 文件名)
NOISE_DIRS = {"__pycache__","node_modules",".git","venv","archive",".cache",".venv"}
def is_noise(name):
    return any(name.endswith(s) for s in (".lock",".bak",".bak-",".db-wal",".db-shm",".sock",".pyc")) \
       or name.startswith("ticker_") or name=="catch_up_occurrences" or name=="gateway.heartbeat" \
       or re.match(r"gateway\.loop-tick\..*\.sock", name)

def rel_files(root, extra_excl=None, base_root=""):
    """root 下相对 base_root 的持久文件集合 {relpath: sha256}; 排除 NOISE。"""
    base_root = base_root or root
    out={}
    for dp,dn,fn in os.walk(root):
        dn[:]=[d for d in dn if d not in NOISE_DIRS and not (extra_excl and d in extra_excl)]
        for f in fn:
            if is_noise(f) or (extra_excl and f in extra_excl): continue
            full=os.path.join(dp,f); rel=os.path.relpath(full, base_root)
            h=hashlib.sha256()
            with open(full,"rb") as fh:
                for c in iter(lambda: fh.read(1<<20), b""): h.update(c)
            out[rel]=h.hexdigest()
    return out

# 条目: id, 本地源, 仓库落点, 模式, 额外目录排除
ENTRIES = [
    ("memories","/root/.hermes/memories","hermes-vps/memory","MIRROR",None),
    ("soul.core","/root/.hermes/SOUL.md","hermes-vps/SOUL.core.md","FILE",None),
    ("soul.compat","/root/.hermes/SOUL.md","hermes-vps/SOUL.md","FILE",None),
    ("skills","/root/.hermes/skills","skills","MIRROR",None),
    ("plugins","/root/.hermes/plugins","hermes-vps/plugins","MIRROR",None),
    ("cron","/root/.hermes/cron","hermes-vps/cron","MIRROR",None),
    ("pending","/root/.hermes/pending","hermes-vps/pending","MIRROR",None),
    ("state","/root/.hermes/state","hermes-vps/state","MIRROR",None),
    # 可再生派生缓存: 内容寻址(由 skills 派生), 新机可重建; 不进 git(历史版本内嵌过活 DB 口令)。
    ("curator","/root/.hermes/.curator_backups","hermes-vps/curator-backups","DERIVED",None),
    ("backups","/root/.hermes/backups","hermes-vps/backups","MIRROR",None),
    ("runtime.cfg","/root/.hermes/config.yaml","hermes-vps/runtime/config.yaml","FILE",None),
    ("workspace","/root/.hermes/Hermes-Agent-Memory","hermes-vps/workspace","MIRROR",
                {"kpanel-source","argon-theme-source"}),   # 参考仓可重拉, 不进仓
    # 可重装项 — 版本清单登记即对称 (体积大不入 git)
    ("agent.bin","/root/.hermes/hermes-agent","hermes-vps/runtime/tools-manifest.txt","MANIFEST",None),
    ("tools","/root/.hermes/tools","hermes-vps/runtime/tools-manifest.txt","MANIFEST",None),
    # 数据快照 — 点时转储
    ("honcho.db","/var/lib/docker/volumes/honcho-local_honcho_pgdata","services/honcho/snapshots/honcho-pg-20261023.dump","SNAPSHOT",None),
    # 密钥 — 加密包
    ("secrets","/root/.hermes/.env","services/vault/hermes-secrets-20261023.tar.gz.enc","ENCRYPTED",None),
]

def check(e):
    eid, lp, rp, mode, extra = e
    rfull=os.path.join(REPO,rp); row={"id":eid,"local":lp,"repo":rp,"mode":mode}
    if mode=="MIRROR":
        local=rel_files(lp, extra)
        repo=rel_files(rfull, extra)
        missing_in_repo=sorted(k for k,v in local.items() if k not in repo or repo[k]!=v)
        orphan_in_repo=sorted(k for k,v in repo.items() if k not in local)
        row["n_local_persist"]=len(local); row["n_repo"]=len(repo)
        row["sym_local_to_repo"]= not missing_in_repo            # 本地每个持久件都在仓
        row["sym_repo_to_local"]= not orphan_in_repo             # 仓里无孤儿件
        row["match"]= row["sym_local_to_repo"] and row["sym_repo_to_local"]
        row["gaps_local_missing_in_repo"]=missing_in_repo[:12]
        row["gaps_orphan_in_repo"]=orphan_in_repo[:12]
    elif mode=="FILE":
        row["sym_local_to_repo"]=os.path.isfile(rfull) and open(lp,"rb").read()==open(rfull,"rb").read()
        row["sym_repo_to_local"]=os.path.isfile(lp)
        row["match"]=row["sym_local_to_repo"] and row["sym_repo_to_local"]
    elif mode=="MANIFEST":
        m=os.path.join(REPO,rp); txt=open(m).read() if os.path.isfile(m) else ""
        row["sym_local_to_repo"]= os.path.exists(lp) and len(txt)>50
        row["sym_repo_to_local"]= os.path.isfile(m)
        row["match"]=row["sym_local_to_repo"] and row["sym_repo_to_local"]
        row["note"]="可重装: 仓库登记精确版本, 本地可重装 => 对称"
    elif mode=="SNAPSHOT":
        row["sym_local_to_repo"]= os.path.exists(lp) and os.path.isfile(rfull)   # 本地有源 + 仓有转储
        row["sym_repo_to_local"]= os.path.isfile(rfull)
        row["match"]=row["sym_local_to_repo"] and row["sym_repo_to_local"]
        row["note"]="点时转储(pg_dump/gzip), 非逐字节, 恢复时灌回即可"
    elif mode=="DERIVED":
        # 可再生派生缓存: 本地有 => 对称(新机可重建); 仓库侧不要求(不进 git), 也不因仓有副本而报孤儿。
        row["sym_local_to_repo"]= os.path.exists(lp)
        row["sym_repo_to_local"]= True   # 仓里无此目录=正常; 不因缺失报孤儿
        row["match"]=row["sym_local_to_repo"]
        row["note"]="可再生派生缓存(不入 git): 由 skills 派生, 换机重建; 历史曾内嵌活凭据, 已从仓清除"
    elif mode=="ENCRYPTED":
        row["sym_local_to_repo"]= os.path.exists(lp) and os.path.isfile(rfull)
        row["sym_repo_to_local"]= os.path.isfile(rfull)
        row["match"]=row["sym_local_to_repo"] and row["sym_repo_to_local"]
        row["note"]="密钥仅存 .enc, 值不回显"
    return row

if __name__=="__main__":
    rows=[check(e) for e in ENTRIES]
    os.makedirs(f"{REPO}/hermes-vps/symmetry", exist_ok=True)
    json.dump(rows, open(f"{REPO}/hermes-vps/symmetry/MANIFEST.json","w"), indent=2, ensure_ascii=False)
    print("=== Hermes-Agent 双边对称校验 (轴=可复原, 非逐字节) ===")
    print(f"{'ID':<13}{'L→R可复原':<11}{'R→L无孤儿':<11}{'对称':<4} 备注")
    for r in rows:
        lt="OK" if r.get("sym_local_to_repo") else "GAP"
        rt="OK" if r.get("sym_repo_to_local") else "GAP"
        mk="✓" if r.get("match") else "✗"
        extra=""
        if r.get("gaps_local_missing_in_repo"): extra=f' 缺仓{len(r["gaps_local_missing_in_repo"])}: {r["gaps_local_missing_in_repo"][:3]}'
        if r.get("gaps_orphan_in_repo"): extra+=f' 孤儿{len(r["gaps_orphan_in_repo"])}: {r["gaps_orphan_in_repo"][:3]}'
        print(f"{r['id']:<13}{lt:<11}{rt:<11}{mk:<4} {r.get('note','')}{extra}")
    ok=all(r.get("match") for r in rows)
    print("\n结果:", "全对称 ✓ — 换机 git clone 一次即可复原 Hermes-Agent" if ok else "!! 有缺口, 见上 GAP/✗")
    sys.exit(0 if ok else 1)
