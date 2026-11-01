# HTML/CSS Card-Frame Pipeline (proven)

Proven in the xray-core explainer project (15 cards, 1080p24, ~6 min, AV1 delivery). Use when the platform has no Remotion/Blender and a clean node_modules install is not desired: deterministic HTML/CSS scenes rendered to JPEG frames via headless Chromium, assembled with ffmpeg.

## Pipeline

1. **Style freeze first.** Pick card set, per-card duration `total` (s) and `animDur` (animation window, rest holds last frame). Store in `cards/cards.json`. All timings deterministic: one JS tween table per card, `window.__setTime(t)` positions every element exactly at time t — no CSS transitions/animations (they are non-deterministic and break frame re-render).
   ```js
   // common.js tween kernel (idempotent at(t), per-frame reproducible)
   window.Tw=(function(){const tweens=[];const E={outCubic:p=>1-Math.pow(1-p,3),lin:p=>p};return{add(t0,dur,fn,e){tweens.push({t0,dur,fn,e:e||'outCubic'})},at(t){for(const o of tweens){let p=(t-o.t0)/o.dur;p=p<0?0:p>1?1:p;o.fn(E[o.e](p),p,t)}}}})();
   window.rise=function(el,p){el.style.opacity=p;}; // OPACITY ONLY — see pitfall 1
   ```
2. **Render each frame**: puppeteer-core pointed at a local Chromium binary (`executablePath`), viewport 1920×1080 deviceScaleFactor=1, `page.screenshot({quality:88})` per frame at `i/24` seconds. ~144 frames/card ≈ 17s → full batch minutes, run in background. `document.fonts.ready` before capture.
3. **Assemble per card**: image sequence → H.264 seg (libx264 crf18 veryfast) + hold last frame (`-loop 1 -framerate 24 -t <still>`) → concat list → copy-concat into silent.mp4.
4. **BGM + final encode**: multi-input needs `-filter_complex` (not `-filter:a`):
   ```bash
   ffmpeg -stream_loop -1 -i bgm.mp3 -i silent.mp4 -shortest \
    -filter_complex "[0:a]apad,afade=t=out:st=<TOT-2.5>:d=2.5,volume=0.55[a]" \
    -map 1:v -map "[a]" -c:v libsvtav1 -svtav1-params "preset=6:crf=36" -pix_fmt yuv420p -c:a aac -b:a 192k out.mp4
   ```
   Match the reference codec (AV1) when the user says "same style/specs as example".

## Pitfalls (each cost a full re-render or a false audit)

1. **`rise()` must not touch `transform`** — centering containers use `transform:translate(-50%,-50%)`; a translateY slide-in overwrites the centering and throws the card to a corner. Use pure opacity fades for centered layouts; keep transform tweens only on containers positioned via left/top.
2. **Draw-in SVG lines**: `strokeDasharray=len; strokeDashoffset=len*(1-p)` per frame. Compute `getTotalLength()` in the tween (runs every frame, idempotent).
3. **SVG overlay sizing**: an overlay `<svg width="100" viewBox="0 0 100 620">` clips paths drawn beyond x=100 silently. Size the overlay to the card (or use `viewBox` matching actual pixel space) — mismatched width/viewBox makes connector lines "float and break".
4. **Multi-input ffmpeg frame extraction**: `ffmpeg -i a.mp4 -i b.mp4 -i c.mp4 -frames:v 1 out.jpg` with N outputs takes all frames from the LAST input. One `-ss <t> -i file -frames:v 1 outN.jpg` command per frame. Verify with `md5sum` uniqueness — N outputs of identical size = broken extraction, not coincidence.
5. **Contact sheets for vision audit must be near full resolution**: `vstack` of 3 frames scaled to ~1440px wide works. Tiny 5×3 grids make the auditor hallucinate "all frames identical" or miss real issues; re-audit the suspicious card at full res from `frames/XX/last.jpg` before believing a finding. Vision audits can also fail by returning a generic checklist that read nothing, or by hallucinating; if a finding contradicts what the card should contain, re-extract that one card's still frame at full res and re-audit single-frame, one card per call, before editing anything.
6. **Free-stock-music MP3 links require a full browser UA + Referer** or you get HTML back saved as .mp3. `file` the download before use; "Audio file with ID3" is the pass signal.
7. **Re-render only changed cards** (`ONLY=01,05 node render.js`); assembly is cheap. Full re-render is only for common.js / layout changes.
8. **Static hold frame = last animation frame** (`anim-1` index, printf %04d). The hold segment is what dominates each card's screen time, so it must be the composition's final state — audit the mid-still point (`start + total/2`), not `start + anim`.
9. **Audit round 2 findings may be artifacts of your own extraction** (wrong -ss times) before they are card bugs; recompute the timeline from `cards.json` cumulative totals before editing cards.
10. **ffprobe `csv=p=0` pollutes string comparisons** — it emits a trailing comma/space, so `"1920," != "1920"` and any spec assertion silently false-FAILs. Read single values with `-of default=noprint_wrappers=1:nokey=1 | tr -d '[:space:],'` before comparing (this is what `qa-gate.sh` does).
11. **Delivery location & naming follow the user's instruction, not the pipeline default** — ship into the reference video's own folder under a DISTINCT name (never overwrite or rename the reference). Confirm both the path and the name before copying out.
12. **`trace(pathEl, dots, t, speed)` takes ONE path element** — passing an array of paths (`trace([p1,p2],dots,t)`) crashes mid-render (`getTotalLength is not a function`) and kills the whole batch. Loop one `trace()` per path with its own dot subset inside a single `Tw.cont`.
13. **AV1 hold-segment frames are NOT md5-identical across extraction times** — I-frame vs P-frame encode noise changes the bytes even when the picture is static. To verify "the still is actually still", compare two still-segment extractions with the psnr filter: `ffmpeg -i a.jpg -i b.jpg -filter_complex psnr -f null -` → `average:inf` (or >60dB) = static. An md5 DIFF inside a hold is NOT a motion defect. (Gate step [3] md5-uniqueness tests extraction correctness — a different question; don't conflate the two.)
14. **In-card SVG chart labels get clipped when the SVG `height` doesn't reach the text baseline.** Budget one row of height below the last gridline, or render axis labels in HTML outside the SVG (cost one full card rewrite on a latency bar-chart).
15. **Reusing a previous film's scaffold (cp render.js / assemble.sh / common.\*) requires rewriting every hardcoded project path, card-ID list, and output filename before running** — a copied assemble.sh silently targets the old project's `cd` + old card set.
16. **Data sourcing (user requirement: 资料自己找自己写)** — pull counts/versions/stars from the actual source cloned this session (docs tree, GitHub API releases/tags); any SIMULATED quantity (e.g. latency comparisons) must be visibly labeled as 量级示意/illustrative ("实测随网络环境浮动") — never present fabricated numbers as measurements.
17. **git clone 404 → credential-prompt trap**: cloning a guessed/wrong GitHub repo name (404) makes git prompt for username/password and hang on a non-interactive host. Use `GIT_TERMINAL_PROMPT=0`, and verify the repo exists first — docs usually live in the MAIN repo's `docs/` tree, not a separate `-doc` repo.

## Release gate (do not ship before this)

After assembly and at least one audit/iteration round, run `scripts/qa-gate.sh <film.mp4> <cards/cards.json>` and only ship to the delivery dir when it exits 0 **and** the per-card 6-point checklist in SKILL.md "Release gate" is passed. The gate encodes the v1 post-mortem: it recomputes still-frame times from `cards.json`, verifies extraction uniqueness by md5 (pitfall 4/9), asserts specs + BGM volume, and regenerates a ≥1440px contact-sheet for the visual pass.

## Tooling note (VPS hermes-vps)

- ffmpeg 9.0.1 at `/root/.hermes/tools/ffmpeg-9.0.1-linux-x64/` (ffprobe alongside). ffmpeg 9 renamed `-vsync` → `-fps_mode`; `-filter:a` with multiple inputs fails — use `-filter_complex`.
- Headless Chromium: `/root/.hermes/tools/chromium-1208/chrome-linux64/chrome` (Chrome for Testing). Node + npm at `/root/.hermes/tools/node-26.7.0-linux-x64/bin/`.
- CJK fonts: Noto Sans CJK SC installed to `/usr/local/share/fonts/noto/` (Regular + Bold OTF from googlefonts/noto-cjk). Verify with `fc-list :lang=zh`.
- BGM: calm lo-fi candidates from free-stock-music.com (CC-BY 4.0, credit the artist in the end card, e.g. FSM Team "Late Night Decaf" 67BPM).

## Reference motion-technique library (lift a film's quality to match a dense reference)

When the reference film feels "much denser" than a naive white-card + fade-in version, the gap is almost always in these 8 underlying techniques. Inventory from high-density 2fps motion sampling of the reference (sample 3+ windows, build 4-timepoint contact sheets, re-sample windows until they land on the reference's TECHNICAL segments, not filler). Port them in via the extended tween kernel (common.js): one-shot tweens (`rise/fade/slide/stagger/type/count/barW/barH/draw/scl`) + continuous per-frame evaluators registered with `Tw.cont(fn)` (fn gets absolute t; keeps everything deterministic).

| # | Technique | What the reference does | Kernel API |
|---|---|---|---|
| 1 | Object morph / state-swap | old element exits, new element grows from the same anchor; single card splits and expands | rise+slide pair on a window, staggered |
| 2 | Fixed skeleton + progressive fill | container static, content lights up per-cell / per-row | `stagger(els,idx,p,step,fn)` on grid cells |
| 3 | SVG path draw-on + particle trace | line grows (strokeDashoffset), then dots stream along it | `draw()` + `trace(pathEl,dots,t,speed)` in `Tw.cont` |
| 4 | Typewriter + blinking cursor | narration words appear letter by letter | `<span class=tw><i>full</i><em></em><b class=cur></b></span>` + `type()`; **`.tw i{display:none}` in shared CSS or text double-prints** |
| 5 | Skeleton shimmer loading state | gray bars with a moving highlight, then swap to real content | `shimmer(el,t)` + opacity crossfade at a switch time |
| 6 | Highlight pulse / glow | focus-guiding: element breathes a soft glow while active | `pulse()` or sin-driven box-shadow in `Tw.cont`; drop-shadow filter for SVG |
| 7 | Scan line | a highlight bar sweeps a data wall, rows light as it passes | `scan(el,t,range,period)` |
| 8 | Window simulation + count-up + step pacing | Mac-style window chrome, numbers roll, still→still→mutation rhythm | `.win` chrome markup, `count(el,p,end)`, schedule "mutation" tweens at discrete t |

Hard rules learned from this round:
- Progressive fills MUST complete before the still frame: `lastRowStart + window < animDur − 0.5s`, plus a snap-to-full fallback tween at `animDur − 0.4s` (still loop grabs the final frame; half-lit walls are a visible defect).
- Continuous animations (`Tw.cont`) run on absolute t, so they survive the anim→still handoff: design the still frame as the settled end-state of every continuous motion.
- After any common.js/common.css change, full re-render is mandatory; after single-card changes, `ONLY=..` re-render + re-assemble + re-gate.
