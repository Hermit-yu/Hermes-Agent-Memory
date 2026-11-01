# Video Production Workflow Documentation

Derived from deep analysis of Ploto reference video (`reference.mp4`, 1928s, 1080p24, AV1).

## Reference Style Analysis

### Visual Language
- **Background**: Warm cream (`#f2ede4`) with subtle dot-grid texture.
- **Cards**: White rounded rectangles (`border-radius: 20px`), very light shadow, centered text.
- **Typography**: Black sans-serif (weight 700 for titles, 400 for body), large sizes (48px title / 28px body in 1080p frame).
- **Palette**: Orange (`#ff8c42`) primary; Green (`#5cb85c`) secondary (tags, progress); Blue (`#4a9eff`) data; Purple (`#9b59b6`) UI accents.
- **Character / Mascot**: Pixel-art orange creature (crab-like), walks across timeline nodes.

### Scene Types (from frame previews)
1. **Title Card** — Large text, tag pill at bottom, character above timeline.
2. **Data Wall** — Multiple thumbnail cards arranged in grid, titles + source labels.
3. **Progress Curve** — Line chart with points, axis labels, large number overlay.
4. **Software UI Mockup** — Flat interface representations (not screenshots), simplified buttons/menus.
5. **Diagram / Flowchart** — Nodes connected by lines, labels inside nodes, arrows.
6. **Timeline / Phase Bar** — Horizontal line with diamond markers, labels below.

### Animation Principles
- Card entry: slide up + fade in (20 frames ~ 0.8s)
- Character movement: frame-by-frame pixel walking
- Data reveal: progress bars grow left-to-right; curves draw sequentially
- Transitions: direct cut or very quick crossfade (not fancy wipes)

## Technical Pipeline

### Phase 1: Setup
```
mkdir video_project
cd video_project
# Create script freeze doc
# Create style freeze doc (colors, fonts, card specs)
# Define output specs: 1080p, 24fps, H.264 or AV1
```

### Phase 2: Script Freeze
Lock narration text. No more text changes after this.

### Phase 3: Style Freeze
Create a `style.md` specifying exact hex codes, font names, card dimensions. Lock this file.

### Phase 4: Key Frame Generation
Generate or approve key frames (one per scene). These become prompts for animation.

### Phase 5: Batch Animation
Use Remotion (`remotion render`) or Blender (`blender --background --render-anim`) to generate `frames/frame_%04d.jpg`.

Always review frames 1, 10, 20 before continuing full batch.

### Phase 6: Assembly
```
./scripts/ffmpeg-compose.sh frames output.mp4 24
```

Add subtitles with `ffmpeg -vf subtitles=subtitle.srt` if needed.

## Installation for Any Agent

### OpenCode
Copy this directory to `.opencode/skills/ai-video-production-workflow/`.
Add to `opencode.json`:
```json
{
  "skills": [".opencode/skills/ai-video-production-workflow"]
}
```

### Hermes-Agent / Generic
Load `SKILL.md` as system prompt or instruction file. Reference `scripts/` as executable tools.

### Manual / CLI
Run scripts directly:
```bash
bash skills/ai-video-production-workflow/scripts/ffmpeg-split.sh
node skills/ai-video-production-workflow/scripts/remotion-scaffold.js
```

## Quality Checklist (before final output)

- [ ] All scenes use locked color palette (no off-color text)
- [ ] Font sizes consistent across cards (title/body ratio ~ 1.7x)
- [ ] Background texture visible but not distracting
- [ ] Subtitles have round white pill background, centered, readable at 1080p on mobile
- [ ] Frame rate is exactly 24fps (not 30, not 60) for cinematic motion
- [ ] Audio (if present) is normalized and does not clip
- [ ] Ending frame includes call-to-action or branding (e.g., `@Ploto.me`, like/coin icons)
