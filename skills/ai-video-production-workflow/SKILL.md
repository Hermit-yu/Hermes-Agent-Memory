---
name: ai-video-production-workflow
description: "AI video matching a reference: card-frame HTML/CSS + ffmpeg."
version: 1.3.0
author: hermes-agent
license: MIT
hermes:
  tags: [video, ffmpeg, chromium, html-css, motion-graphics, av1]
  related_skills: [ascii-video, manim-video, p5js]
---

# Skill: AI Video Production Workflow

Universal video production pipeline based on the Ploto / Claude Code workflow analyzed from reference video. Combines Blender (3D/2D animation), Remotion (programmatic React-based video), ffmpeg (frame assembly/rendering), and generative code capabilities.

## When to use

- User asks to "make a video like [reference]"
- User wants to convert a script/story into animated frames
- User needs to assemble frames into MP4 with custom fps/codec
- User wants to generate motion graphics without traditional剪辑软件 (editing software)

## Workflow phases (6-stage freeze model + release gate)

1. **Project Setup (立项)** — Define topic, target duration (short <60s / long 5-46min), platform (Bilibili/YouTube/TikTok), style reference images
2. **Script Freeze (剧本冻结)** — Lock narration text and scene count; no edits after this point without restarting
3. **Style Freeze (风格冻结)** — Lock color palette (default warm cream `#f2ede4`, orange `#ff8c42`, green `#5cb85c`, blue `#4a9eff`), font (sans-serif black), card radius (16-24px), mascot pixels, background dot-grid texture
4. **Key Frame Lock (关键静帧)** — Generate or approve representative still frames for every scene; these drive the animation prompts
5. **Animation / Render (动画初版)** — Run Blender/Remotion/code to generate frame sequences; AI reviews first 3 frames before full batch. Proven no-dependency variant (no Remotion/Blender needed): deterministic HTML/CSS card scenes + headless-Chromium per-frame screenshots → ffmpeg. Full recipe: `references/html-frame-pipeline.md`.
6. **Final Assembly (成片放行)** — ffmpeg composites frames + audio/subtitle; output `output.mp4`. No-narration variant (subtitle-driven, matching the Ploto reference style): subtitle pill at bottom-center, calm CC-BY/CC0 BGM looped under the whole film, credits + BGM license disclosed on the final card.
7. **Release Gate (发布门禁)** — BEFORE copying the film to the delivery dir, run `scripts/qa-gate.sh`. Machine assertions ([1]specs [2]BGM volume [3]still-frame extraction uniqueness [4]timing [5]contact-sheet) + a per-card 6-point visual checklist. All green + checklist passed, only then ship. See "Release gate" below.

## Tools available

- `ffmpeg` — Frame extraction (`-vf fps=`), image sequence to video (`-i frame_%04d.jpg`), format conversion, subtitle burn (`-vf subtitles=`)
- `python` / `node` — Remotion scene generation (`remotion render`), SVG/HTML scene scripting
- `blender` (optional) — `.blend` files for 3D motion graphics; can be replaced by pure Remotion/HTML for faster iteration
- `shell` — Bash commands for batch rendering, file management

## Scripts provided

- `scripts/remotion-scaffold.js` — Creates a new Remotion scene from a JSON scene description
- `scripts/blender-template.blend` — Base Blender file with camera, lighting, and pixel-art materials matching reference style
- `scripts/ffmpeg-compose.sh` — Assembles `frames/frame_%04d.jpg` into `output.mp4` at 24fps with H.264
- `scripts/ffmpeg-split.sh` — Splits reference video into preview frames

## Default parameters (from reference analysis)

| Parameter | Value |
|-----------|-------|
| Resolution | 1920×1080 (16:9) |
| Frame rate | 24 fps |
| Video codec | AV1 / libx264 |
| Audio | Optional; use TTS or external file |
| Subtitle style | Bottom-center white pill with dark text |
| Background | Warm cream dot-grid |
| Primary accent | Orange (`#ff8c42`) |
| Secondary accents | Green (`#5cb85c`), Blue (`#4a9eff`) |
| Card style | White rounded rectangle (r=20px), subtle shadow |

## Installation / Import

This skill works in any agent framework that supports file-based skills:

- **OpenCode / Hermes-agent**: Copy `skills/ai-video-production-workflow/` into `.opencode/skills/` or project root `skills/`
- **Generic AI agent**: Load `SKILL.md` as instruction context; reference `scripts/` as executable helpers
- **Manual**: Run scripts directly with `bash scripts/ffmpeg-...` or `node scripts/remotion-...`

## References

- Ploto reference video (analysis source): `reference.mp4` (32:08, AV1, 1080p24)
- Frame previews: `frames/preview_*.jpg` (193 frames, 10-second intervals)
- Video production docs: `docs/video-workflow.md` (auto-generated from analysis)

## Important constraints

- Do NOT start rendering until Script Freeze (phase 2) and Style Freeze (phase 3) are complete. Changing style mid-render causes full re-render.
- Always review at least 3 key frames before running full animation batch.
- For long videos (>10 min), split into 46-minute max segments (platform limits) or chapters.
- If using Blender, ensure `.blend` materials use flat shading (no PBR) to match the flat Web-design aesthetic of the reference.
- HTML/CSS card-frame pipeline (Chromium screenshots → ffmpeg, no Remotion/Blender): see `references/html-frame-pipeline.md` — deterministic `__setTime(t)` per frame, opacity-only fade-ins, one-ffmpeg-command-per-frame extraction, AV1 delivery via libsvtav1.
- No narration required: subtitle pill + CC-licensed BGM is a first-class delivery mode (used for the xray-core explainer); disclose music license on the final card.

## Release gate (publishing discipline)

Root cause of recurring multi-card defects in card-based films is the absence of a mandatory pre-release checkpoint — the film ships because "someone remembered to check," not because anything forced it. This gate makes the check executable. **Do not copy the film to the delivery directory until every item below is green.**

Delivery rule (standing user preference): ship the finished film **into the same folder as the reference/example video, under a distinct name** — never overwrite or rename the reference. Confirm the exact target path and filename before copying out.

Run: `bash scripts/qa-gate.sh <film.mp4> <cards/cards.json> [out_dir]` — it auto-asserts [1] specs (1920×1080 + video + audio track), [2] BGM volume in the calm band, [3] still-frame extraction uniqueness (md5), [4] still-frame timing falls in the hold segment not the animation window, [5] a ≥1440px contact-sheet. Then complete the per-card visual 6-point checklist ([6]) against `qa_sheet.jpg` + `f_XX.jpg`:

- **[d1] bounds** — no element/card right edge >1920 or bottom >1080 (e.g. a 4-up row whose 4th card walks off-screen).
- **[d2] overlap** — a big title must not sit on a content card; cards must not occlude each other (e.g. a centered title over the first layer box).
- **[d3] connectors** — SVG connection/detour lines close start→end with no floating/broken segment (clipped by a mismatched `width`/`viewBox` overlay).
- **[d4] contrast** — explanatory/annotation small text must be legible vs. its background; lighten-on-white gets darkened (faint `--ink2` captions on white).
- **[d5] balance** — side-by-side or stacked columns share a bottom edge; content is not top-heavy (uneven column heights, "hanging" compare boxes).
- **[d6] hold** — the closing card must hold its content to the card's end; never fade out early and leave blank screen time (faded at 5s leaving 10s empty).

Any one failing → fix that card → **re-render only the changed card** (`ONLY=..`) → re-run the gate. `references/html-frame-pipeline.md` holds the deeper technique pitfalls (rise-vs-transform, SVG overlay sizing, ffmpeg multi-input extraction, BGM download UA+Referer, contact-sheet resolution) that caused these.

## Regression checklist (defect classes the gate catches)

Recorded so the same failure classes are caught by design, not by luck. Each maps to a gate check ([d1]-[d6]):

1. **Detour/connector lines "floated and broke"** — SVG overlay sized with a `width` far smaller than the `viewBox` it reached, silently clipping the paths ([d3]; overlay sizing pitfall).
2. **Big title overlapped the first content box** — centered layout with no reserved header band ([d2]).
3. **A card ran off the frame edge** (left+width exceeded 1920) and cards over-tall with empty lower halves ([d1] bounds + [d5] balance).
4. **Description text too light** (`--ink2` on white) ([d4] contrast).
5. **Side-by-side column bottoms uneven; low-contrast captions** ([d5] + [d4]).
6. **Compare boxes top-heavy ("hanging")** — content not vertically centered ([d5]).
7. **End-card content faded out early, leaving blank screen time** ([d6] hold).
8. **Typewriter placeholder double-print** — `<span class="tw"><i>full text</i><em></em><b>cursor</b></span>` prints the full text TWICE because the placeholder `<i>` stays visible next to the `<em>` output. Fix: global `.tw i{display:none}` in common.css. Any typewriter widget MUST hide its placeholder in shared CSS, not per-card ([d2] overlap / text-correctness).
9. **Data-wall / progressive-fill half-lit at the still frame** — staggered fills whose last row starts too late (or with too long a window) freeze mid-fill when the still loop grabs the final frame. Rule: schedule fills so `lastRowStart + window < animDur − 0.5s`, AND add a hard "snap-to-full" fallback tween at `animDur − 0.4s` that forces every cell to final state ([d5] balance / [d6] hold).
10. **Multi-column label collision from typical-length sizing** — a fixed left column sized for typical labels silently collides with the right column when the longest label overflows it. Rule: size each column to its longest content or add whitespace margin ([d2] overlap / column alignment).
11. **In-card SVG chart elements silently clipped at the viewBox edge** — axis labels or the last gridline placed beyond the SVG's `height` vanish without any error (text at y=410 in a 380-tall SVG is invisible). Budget at least one row of height below the baseline, or render labels in HTML outside the SVG ([d1] bounds).
18. **Low-res contact sheets produce false positives** — a shrunken multi-card sheet makes the auditor report "severe layout imbalance" on cards that are fine at full resolution (thin lines read as broken, sparse intentional whitespace reads as a defect). Treat every low-res-sheet finding as a flag, not a bug: re-audit each flagged card single-frame at full res before editing, and only trust findings that survive that pass.

Meta-failure (process, not a card): **an audit run on frames extracted at wrong times misreports** — a multi-input ffmpeg bug plus hand-typed `-ss` values make the auditor "see" half-drawn or blank frames. The gate's [3]/[4] recompute still-frame times from `cards.json` cumulative totals and verify md5-uniqueness before any visual audit is trusted.

## Lessons learned (card-based films)

- Ship discipline beats memory: a film that "looks fine" is not a verified film. The only acceptable "done" is gate-green + checklist-passed.
- Always re-render **only the changed cards**; full re-render is reserved for `common.js` / global layout changes (cheapest correct path).
- Two audit passes minimum on any card-based film: one on the assembled film's still frames, one targeted re-check of every card the first pass flagged — and only trust frames whose extraction you've verified (md5-unique, timing-in-hold).
- Match the reference's codec when told "same style/specs" (here AV1 via `libsvtav1`; x264 intermediates are fine, only the final encode must match).
- No narration is a legitimate delivery mode: subtitle pill + calm CC-BY BGM, with the BGM credit on the end card.
- **Pacing (standing user preference)**: tight — hold segments (`total − animDur`) 2–4s per card; a long still gap between data scenes reads as dead air. To dwell longer, extend `animDur` (more motion) instead of the still hold. Review rounds: 3 is the working default for explainer films (gate + low-res sheet → full-res single-card re-audit of every flagged card → final sheet + stillness check); the user expects these rounds done before delivery, not offered.
