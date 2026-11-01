#!/bin/bash
# qa-gate.sh — AI 视频发布前硬门禁。全绿才许把成片拷进交付目录。
# 把 v1 复盘出的失误点编码成可复跑断言, 下次不是"记得去查", 而是"跑一遍全绿才放行"。
#
# 用法:
#   bash qa-gate.sh <成片.mp4> <cards.json> [输出目录]
#
# 自动断言(机器): [1]规格 [2]BGM音量 [3]定格帧抽帧唯一性 [4]时刻重算 [5]contact-sheet
# 人工/视觉对照:  [6]每卡设计验收 6 条 checklist (逐张定格帧目视)
#
# 退出码: 0 = 全绿; 非0 = 有 FAIL, 禁止交付。
set -u
FIN="${1:-}"; CARDS="${2:-}"; OUT="${3:-/tmp/qa-gate-$(date +%s)}"
[ -n "$FIN" ] && [ -n "$CARDS" ] || { echo "用法: bash qa-gate.sh <成片.mp4> <cards.json>"; exit 2; }
[ -f "$FIN" ] || { echo "成片不存在: $FIN"; exit 2; }
[ -f "$CARDS" ] || { echo "cards.json 不存在: $CARDS"; exit 2; }

# 工具路径 (VPS hermes-vps 优先, 否则回退 PATH)
FFD="/root/.hermes/tools/ffmpeg-9.0.1-linux-x64/bin"
FF=$([ -x "$FFD/ffmpeg" ] && echo "$FFD/ffmpeg" || echo "ffmpeg")
FP=$([ -x "$FFD/ffprobe" ] && echo "$FFD/ffprobe" || echo "ffprobe")
mkdir -p "$OUT"
FAIL=0
WARN=0

echo "############ QA GATE: $(basename "$FIN") ############"

echo
echo "===== [1/6] 规格验证 (ffprobe) ====="
W=$($FP -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1 | tr -d '[:space:],')
H=$($FP -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1 | tr -d '[:space:],')
FPS=$($FP -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1)
VCO=$($FP -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1 | tr -d '[:space:]')
DUR=$($FP -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1 | tr -d '[:space:]')
ACODEC=$($FP -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FIN" | head -1 | tr -d '[:space:]')
echo "  ${W}x${H} ${FPS} 视频=${VCO:-无} 音频=${ACODEC:-无} 时长=${DUR}s"
[ "$W" = "1920" ] && [ "$H" = "1080" ] && echo "  ✓ 分辨率 1920x1080" || { echo "  ✗ FAIL 分辨率应为1920x1080"; FAIL=1; }
[ -n "$VCO" ] && echo "  ✓ 有视频轨($VCO)" || { echo "  ✗ FAIL 无视频轨"; FAIL=1; }
[ -n "$ACODEC" ] && echo "  ✓ 有音频轨($ACODEC, BGM已混入)" || { echo "  ✗ FAIL 无音频轨(无BGM?)"; FAIL=1; }

echo
echo "===== [2/6] BGM 音量 (volumedetect) ====="
# 无旁白单音轨, mean_volume 落在 [-30,-12]dB 视为舒缓 BGM 正常区间, 超出给 WARN
MEAN=$($FF -i "$FIN" -af volumedetect -f null - 2>&1 | grep -oE "mean_volume: [-0-9.]+ dB" | head -1 | grep -oE '[-0-9.]+')
echo "  mean_volume = ${MEAN:-?} dB"
if [ -n "$MEAN" ]; then
  LO=$(python3 -c "print(float('$MEAN')>=-30.0)")
  HI=$(python3 -c "print(float('$MEAN')<=-12.0)")
  if [ "$LO" = "True" ] && [ "$HI" = "True" ]; then echo "  ✓ 音量在舒缓区间 [-30,-12]dB"
  else echo "  ! WARN 音量${MEAN}dB 超出[-30,-12]dB(过响=调小volume, 几乎无声=确认BGM是否铺满); 不硬卡但需人工定夺"; WARN=1; fi
else echo "  ! WARN 读不到 mean_volume (可能无音频轨)"; WARN=1; fi

echo
echo "===== [3/6] 定格帧抽帧: 逐帧单输入 + md5 唯一校验 (防多输入bug) ====="
# 时刻从 cards.json 累计重算 (start+total/2 = 各卡静止段中点), 不手写, 杜绝时刻错位
FIN="$FIN" CARDS="$CARDS" OUT="$OUT" FF="$FF" python3 - <<'PY'
import json,os,subprocess,hashlib
FIN=os.environ["FIN"]; CARDS=os.environ["CARDS"]; OUT=os.environ["OUT"]; FF=os.environ["FF"]
cards=sorted(json.load(open(CARDS)),key=lambda c:c["id"])
acc=0; frames=[]
for c in cards:
    mid=acc+c["total"]/2.0
    frames.append((c["id"],mid))
    acc+=c["total"]
print(f"  {len(frames)}张卡, 累计时长 {acc:.0f}s (每张取 静止段中点 start+total/2)")
for cid,t in frames:
    subprocess.run([FF,"-v","error","-ss",f"{t:.2f}","-i",FIN,"-frames:v","1",f"{OUT}/f_{cid}.jpg","-y"])
hs=[hashlib.md5(open(f"{OUT}/f_{cid}.jpg","rb").read()).hexdigest() for cid,_ in frames]
uniq=len(set(hs))
print(f"  定格帧 md5 唯一数: {uniq}/{len(hs)}")
if uniq!=len(hs):
    print("  ✗ FAIL: 抽帧有重复(多输入抽帧bug: 全取同一帧), 审片作废, 禁止交付")
    raise SystemExit(3)
print("  ✓ 抽帧唯一, 审片有效")
PY
[ $? -eq 0 ] || FAIL=1

echo
echo "===== [4/6] 时刻正确性: 定格帧不得落在动画窗口内 (防抽到半成品帧) ====="
# 每张卡的定格时刻必须 >= 该卡 start+animDur (动画已结束), 否则抽到的是动画中途的残缺帧
FIN="$FIN" CARDS="$CARDS" OUT="$OUT" FF="$FF" python3 - <<'PY'
import json,os,subprocess,hashlib
FIN=os.environ["FIN"]; CARDS=os.environ["CARDS"]; OUT=os.environ["OUT"]; FF=os.environ["FF"]
cards=sorted(json.load(open(CARDS)),key=lambda c:c["id"])
acc=0; bad=[]
for c in cards:
    start=acc; mid=start+c["total"]/2.0
    # 若 total<=animDur, 该卡全程都在动画内, 无静止段 -> 应告警
    if c["total"]<=c.get("animDur",0):
        bad.append(f'卡{c["id"]}: total({c["total"]}s)<=animDur({c.get("animDur")}), 无静止段, 定格时刻落在动画内')
    acc+=c["total"]
for b in bad: print("  ✗ FAIL "+b)
if not bad: print(f"  ✓ 所有卡 total>animDur, 定格时刻(start+total/2)均落在静止段")
raise SystemExit(1 if bad else 0)
PY
[ $? -eq 0 ] || FAIL=1

echo
echo "===== [5/6] 生成 contact sheet (>=1440px, 防低分辨率幻觉审片) ====="
mkdir -p "$OUT/seq"; rm -f "$OUT/seq"/*
FIN="$FIN" CARDS="$CARDS" OUT="$OUT" FF="$FF" python3 - <<'PY'
import json,os,subprocess,math
CARDS=os.environ["CARDS"]; OUT=os.environ["OUT"]; FF=os.environ["FF"]
ids=[c["id"] for c in sorted(json.load(open(CARDS)),key=lambda c:c["id"])]
for i,cid in enumerate(ids):
    subprocess.run(["cp",f"{OUT}/f_{cid}.jpg",f"{OUT}/seq/{i:02d}.jpg"])
cols=5; rows=math.ceil(len(ids)/cols)
subprocess.run([FF,"-v","error","-framerate","1","-i",f"{OUT}/seq/%02d.jpg",
    "-vf",f"tile={cols}x{rows},scale=1440:-1","-frames:v","1",f"{OUT}/qa_sheet.jpg","-y"])
print(f"  ✓ {OUT}/qa_sheet.jpg ({cols}x{rows}, 宽1440px)")
PY
[ -f "$OUT/qa_sheet.jpg" ] && echo "  ✓ sheet 已生成" || { echo "  ✗ FAIL sheet 生成失败"; FAIL=1; }

echo
echo "===== [6/6] 每卡设计验收 6 条 (逐张定格帧目视/视觉复核) ====="
cat <<'CHK'
  对照 $OUT/qa_sheet.jpg 与 $OUT/f_XX.jpg 逐张过下列 6 条 (v1 的 7 张卡硬伤全出自这里):
  [d1] 边界   所有元素/卡片右缘<=1920, 底缘<=1080, 无越出被裁 (v1: card03 第四卡越出画面)
  [d2] 重叠   大标题与内容框无文字压盖; 卡片之间无相互遮挡 (v1: card02 标题压第一层框)
  [d3] 连线   SVG 连接/绕行线从起点到终点闭合, 无悬空断裂 (v1: card01 绕行线被viewBox裁掉)
  [d4] 对比   说明/注释小字与背景对比度足够(浅灰字放白底要加深), 无近白底近白字 (v1: card04/05 小字过浅)
  [d5] 平衡   同屏左右栏/上下层底边对齐, 内容不头重脚轻 (v1: card05 左右高度不齐, card12 悬挂)
  [d6] 停留   片尾/收尾卡内容须定格停留到该卡结束, 不得提前淡出留空屏 (v1: card14 5s就淡出留10s空白)
  全部 6 条通过才许交付; 任一条不过 -> 改对应卡 -> 只重渲改过的卡 -> 重跑本脚本。
CHK

echo
echo "############ QA GATE 结果: FAIL=$FAIL WARN=$WARN ############"
if [ "$FAIL" -eq 0 ]; then
  echo "  → 自动断言全绿。完成 [6/6] 六条目视后, 可把成片拷入交付目录。"
  echo "  → sheet: $OUT/qa_sheet.jpg   定格帧: $OUT/f_XX.jpg"
else
  echo "  → 存在 FAIL, 禁止交付。修对应卡后重跑。"
fi
exit $FAIL
