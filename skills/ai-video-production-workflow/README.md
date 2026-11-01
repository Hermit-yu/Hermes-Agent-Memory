# AI Video Production Workflow — Universal Skill Package

A portable, framework-agnostic video production pipeline derived from the Ploto reference video workflow (`reference.mp4`, 32:08, 1080p24, AV1, no audio stream, screen-capture/tutorial style).

## What's Inside

```
skills/ai-video-production-workflow/
├── SKILL.md              # Main skill instructions
├── scripts/
│   ├── ffmpeg-compose.sh # Frame sequence → MP4
│   ├── ffmpeg-split.sh   # Video → preview frames (10s intervals)
│   ├── remotion-scaffold.js # Generate Remotion React scene
│   └── blender-template.blend # Base .blend settings reference
└── docs/
    └── video-workflow.md  # Full technical pipeline + style guide
```

## Quick Start (Any AI Agent)

### Option 1: OpenCode (Native)
```bash
cp -r skills/ai-video-production-workflow .opencode/skills/
# Or add to opencode.json:
# { "skills": [".opencode/skills/ai-video-production-workflow"] }
```

### Option 2: Hermes-Agent / Generic Agent
Load `SKILL.md` as a skill/instruction file. Most agent frameworks support file-based skills by copying the folder into their skills directory (e.g., `~/.hermes/skills/`, `~/.claude/skills/`, or project-local `skills/`).

### Option 3: Manual / CLI
Run scripts directly without any agent framework:
```bash
bash skills/ai-video-production-workflow/scripts/ffmpeg-split.sh
node skills/ai-video-production-workflow/scripts/remotion-scaffold.js
```

### Option 4: Embed in Prompt
Copy the contents of `SKILL.md` into your agent's system prompt or context file.

## Dependencies

- `ffmpeg` (tested with build from `G:\APP\ffmpeg-2026-10-19-git-2344518cc5-essentials_build`)
- `node` (for Remotion scaffold)
- `python` (optional, for additional scripting)
- `blender` (optional, only if using `.blend` template)

## How This Skill Works

When loaded into an agent, it gives the agent:

1. **A structured 6-phase workflow** (Setup → Script Freeze → Style Freeze → Key Frames → Animation → Final Assembly)
2. **Exact visual parameters** (colors, fonts, card sizes, frame rate, resolution) extracted from the reference video
3. **Executable helpers** (ffmpeg commands, remotion templates, blender settings) so the agent can actually run the pipeline
4. **Quality constraints** (checklist, freeze rules) so the agent knows when to ask for approval vs. proceed

## Integration Notes for Developers

If you are building an AI agent framework (like Hermes-agent) and want to support this skill natively:

- Read `SKILL.md` as the skill definition
- Make `scripts/` executable (chmod +x for `.sh`)
- Register the `docs/video-workflow.md` as additional reference context
- The agent should be able to call `shell` and `execute` tools to run the scripts

This package does NOT require any proprietary API, model, or service. It works with any agent that has file access + code execution.
