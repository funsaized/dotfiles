# Dotfiles

Opinionated editor configs for [VS Code](https://code.visualstudio.com/) and [Zed](https://zed.dev/) — tuned for full-stack TypeScript/Java/Python development with AI-assisted workflows.

These are battle-tested settings from daily use. Every decision is intentional and documented inline. Take what works for you, ignore the rest.

## Repo Structure

```
dotfiles/
├── claude/
│   └── skills/
│       └── notebooklm/          # Claude Code skill — NotebookLM bridge
│           ├── SKILL.md
│           ├── scripts/
│           │   └── load_channel.py
│           └── workflows/
│               ├── add-source.md
│               ├── ask.md
│               ├── auth.md
│               ├── manage.md
│               └── youtube-channel.md
├── vscode/
│   └── settings.json    # VS Code user settings (~490 lines)
├── zed/
│   └── settings.json    # Zed editor settings (~560 lines)
└── README.md
```

Both editor config files are heavily commented with section headers and `[USER-SPECIFIC]` / `[MACHINE-SPECIFIC]` tags so you know exactly what to change when copying to your own setup.

---

## How to Use These

### Quick Start — VS Code

```bash
# Back up your current settings first
cp ~/Library/Application\ Support/Code/User/settings.json \
   ~/Library/Application\ Support/Code/User/settings.json.bak

# Copy this config in
cp vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

### Quick Start — Zed

```bash
cp ~/.config/zed/settings.json ~/.config/zed/settings.json.bak
cp zed/settings.json ~/.config/zed/settings.json
```

### Quick Start — Claude Code Skills

```bash
# Copy the skills into your global Claude config
cp -r claude/skills/* ~/.claude/skills/
```

Each skill is self-contained with a `SKILL.md` (the skill definition Claude reads) plus supporting scripts and workflow docs.

### Cherry-Pick Instead of Wholesale Copy

Both editor config files use section headers (`// ===` in VS Code, `// ──` in Zed) so you can grab individual blocks. Every section is self-contained — copy a block into your own settings and it just works.

---

## Claude Code Skills

### notebooklm — NotebookLM Bridge

Import any content into Google NotebookLM directly from Claude Code.

**Supported sources**: YouTube channels (bulk load up to 300 episodes), individual YouTube videos, podcasts, webpages, PDFs, images, Google Docs/Slides, plain text.

**What it does**:
- Bulk-load entire YouTube channels into a notebook with one command
- Add any URL or local file as a NotebookLM source
- Query notebooks and get cited answers with `[N]` markers traced to exact source passages
- Create and manage notebooks

**Prerequisites**: `nlm` CLI (`uv tool install notebooklm-mcp-cli`) and `notebooklm-py` (`pip install "notebooklm-py[browser]"`). See [`claude/skills/notebooklm/SKILL.md`](claude/skills/notebooklm/SKILL.md) for full setup.

**Trigger phrases**: "notebooklm", "load channel", "add to notebook", "notebooklm ask", "import into notebooklm"

---

## VS Code — Key Decisions

### Typography

```jsonc
"editor.fontFamily": "Operator Mono Lig, Fira Code, Menlo, Monaco, 'Courier New', monospace",
"editor.fontLigatures": true,
"editor.lineHeight": 1.6,
"editor.letterSpacing": 0.2
```

**Why**: [Operator Mono](https://www.typography.com/fonts/operator/overview) has a true italic that makes comments and types visually distinct from code. The font stack falls back gracefully — if you don't own Operator Mono, you get Fira Code ligatures instead, then system monospace. Line height at 1.6 with slight letter spacing reduces eye strain on long sessions.

### Formatting Strategy — Intentionally Split

```jsonc
"editor.formatOnSave": false,
"editor.codeActionsOnSave": { "source.fixAll.eslint": "explicit" }
```

**Why**: Global format-on-save is disabled to avoid surprises in unfamiliar codebases. Formatting is delegated per-language to the right tool — Prettier for JS/TS/SCSS, built-in for JSON, markdownlint for Markdown. ESLint auto-fix runs on save but only when you explicitly trigger it. This keeps you in control.

### Inlay Hints — Off Unless Pressed

```jsonc
"editor.inlayHints.enabled": "offUnlessPressed"
```

**Why**: Inlay hints (showing inferred types inline) are useful when you need them and noisy when you don't. Hold `Ctrl+Alt` (or your configured key) to show them on-demand without permanently cluttering the editor.

### Navigation — Peek-First Workflow

```jsonc
"editor.gotoLocation.multipleDefinitions": "gotoAndPeek",
"editor.gotoLocation.multipleReferences": "peek"
```

**Why**: When "Go to Definition" finds multiple results, it navigates to the best match AND opens a peek widget — so you see the destination but can quickly scan alternatives without losing your place. References always peek since you typically want to scan multiple call sites, not jump to one.

### Minimap — Block Mode

```jsonc
"editor.minimap.renderCharacters": false,
"editor.minimap.size": "fill",
"editor.minimap.showSlider": "mouseover"
```

**Why**: The minimap renders abstract blocks instead of tiny unreadable characters. Fills the available height for a real birds-eye view of the file. Slider only appears on hover to keep the chrome minimal.

### Italic Syntax Highlighting

```jsonc
"editor.tokenColorCustomizations": {
    "textMateRules": [
        { "scope": ["comment", ...], "settings": { "fontStyle": "italic" } },
        { "scope": ["entity.name.type.interface.ts", ...], "settings": { "fontStyle": "italic" } },
        { "scope": ["entity.name.type.class.java", ...], "settings": { "fontStyle": "italic" } }
    ]
}
```

**Why**: With a font that has distinct italics (Operator Mono, JetBrains Mono, Victor Mono), this makes comments, types, interfaces, and decorators pop without changing colors. You can *read* the code structure at a glance — "italic = type-level, upright = value-level."

### Java JVM Tuning

```jsonc
"java.jdt.ls.vmargs": "-XX:+UseG1GC -XX:G1HeapRegionSize=16m -XX:+UseStringDeduplication -Xmx12G -Xms1G"
```

**Why**: The Java language server is notoriously memory-hungry. G1GC with string deduplication keeps GC pauses short. 12GB max heap is aggressive but eliminates OOM crashes on large monorepos. Adjust `-Xmx` down if you have < 16GB RAM.

### Copilot Terminal Auto-Approve

The `chat.tools.terminal.autoApprove` block (~130 lines) is a granular allowlist for AI-initiated terminal commands. The philosophy:

- **Read-only commands auto-approved**: `ls`, `cat`, `grep`, `git status`, `git log`, `docker ps`, `npm list`, etc.
- **Destructive commands blocked or require confirmation**: `rm`, `dd`, `git branch -D`, `find -delete`, `eval`, etc.
- **Regex patterns for edge cases**: e.g., `sort -o` (writes to file) is blocked even though `sort` is allowed; `find -exec` is blocked even though `find` is allowed.

This lets AI assistants work autonomously on safe operations while keeping you in the loop for anything that modifies state.

### Workbench Layout

```jsonc
"workbench.editor.showTabs": "single",
"workbench.sideBar.location": "right",
"workbench.startupEditor": "none"
```

**Why**: Single tab mode forces intentional file navigation — you use `Cmd+P` instead of clicking through 20 tabs. Sidebar on the right keeps the code gutter stable (no horizontal shift when toggling the sidebar). No startup editor means you're immediately in your last workspace.

### File Watcher Exclusions

```jsonc
"files.watcherExclude": {
    "**/target/**": true,
    "**/node_modules/**": true,
    "**/build/**": true,
    "**/dist/**": true,
    "**/.gradle/**": true,
    ...
}
```

**Why**: VS Code's file watcher can eat CPU and file descriptors in large polyglot repos. Excluding build artifacts, dependency dirs, and IDE metadata keeps things fast. The `files.exclude` list mirrors this for the explorer view.

---

## Zed — Key Decisions

### Adaptive Theme

```jsonc
"theme": {
    "mode": "system",
    "light": "Catppuccin Iced Latte (Blur)",
    "dark": "Vesper Blur"
},
"icon_theme": {
    "mode": "system",
    "light": "Base Charmed Icons",
    "dark": "Soft Charmed Icons"
}
```

**Why**: Theme follows your OS dark/light mode automatically. Blur variants give the macOS-native frosted glass effect. Separate icon themes per mode ensure file icons stay legible regardless of background color.

### Italic Syntax Overrides (Both Themes)

Both the dark and light themes get identical `theme_overrides` applying italic to comments, keywords, types, decorators, parameters, and escape sequences. Same rationale as VS Code — visual separation between type-level and value-level constructs without changing the color palette.

### AI Agent Configuration

```jsonc
"agent": {
    "default_model": {
        "provider": "anthropic",
        "model": "claude-sonnet-4-6-thinking-latest",
        "enable_thinking": true
    },
    "inline_assistant_model": {
        "provider": "copilot_chat",
        "model": "gpt-5.1-codex-max"
    },
    "tool_permissions": { "default": "allow" },
    "play_sound_when_agent_done": true
}
```

**Why**: Two-tier AI setup — the heavy thinking model (Claude Sonnet with extended thinking) for agent tasks that require reasoning, and a fast codex model for inline edits where speed matters more than deliberation. Tools are allowed by default because the agent workflow is approval-gated anyway. Audio notification so you can context-switch while the agent works.

### MCP Context Servers

```jsonc
"context_servers": {
    "mcp-server-context7": { "enabled": true },
    "mcp-server-github": { "enabled": true }
}
```

**Why**: [Context7](https://context7.com/) provides real-time documentation lookups and the GitHub MCP server gives the agent direct access to issues, PRs, and code search — dramatically improving the quality of AI-generated code by grounding it in actual docs and your codebase.

> **Note**: Replace the placeholder API keys with your own before use.

### Editor — Wrap Guides at Three Widths

```jsonc
"wrap_guides": [80, 100, 120]
```

**Why**: Different codebases have different line-length conventions. Three subtle vertical guides let you eyeball compliance without memorizing the number — commit messages and comments should fit at 80, most code at 100, and nothing should exceed 120.

### Editor — Focus Helpers

```jsonc
"active_pane_modifiers": {
    "inactive_opacity": 0.75,
    "border_size": 1.0
},
"autosave": "on_focus_change",
"use_smartcase_search": true
```

**Why**: Inactive panes dim to 75% opacity, making the active pane obvious in split layouts. Autosave on focus change eliminates "did I save?" anxiety — when you switch to the terminal or another pane, the file is already saved. Smartcase search means lowercase queries are case-insensitive, but adding any uppercase character makes it exact — same behavior as Vim's `smartcase`.

### Panel Layout — Sidebar Right, Close Button Left

```jsonc
"project_panel": { "dock": "right" },
"tabs": { "close_position": "left" }
```

**Why**: Sidebar on right for the same reason as VS Code — stable code gutter. Close button on the left of each tab follows Fitts's Law — your cursor is already near the left edge of the tab after reading the filename.

### TypeScript LSP — Full Inlay Hints

```jsonc
"typescript-language-server": {
    "settings": {
        "typescript": {
            "inlayHints": {
                "parameterNames": { "enabled": "literals" },
                "parameterTypes": { "enabled": true },
                "variableTypes": { "enabled": true },
                "returnTypes": { "enabled": true }
            }
        }
    }
}
```

**Why**: Zed's inlay hints are less intrusive than VS Code's, so they're always on here. `parameterNames` is set to `"literals"` — it only shows names for literal arguments (e.g., `fn(/* count */ 5, /* enabled */ true)`) rather than every argument, which reduces noise while catching the cases where hints actually help.

### ESLint — All Rules as Warnings

```jsonc
"eslint": {
    "settings": {
        "rulesCustomizations": [{ "rule": "*", "severity": "warn" }]
    }
}
```

**Why**: Treats all ESLint violations as warnings (yellow) instead of errors (red). This keeps the editor from screaming at you while typing — the CI pipeline enforces the actual severity. Less visual noise, same rigor at merge time.

### File Scan Exclusions

Comprehensive exclusion list covering every common build/cache/output directory:

- **JS ecosystem**: `node_modules`, `.next`, `.nuxt`, `.turbo`, `.parcel-cache`, lock files, source maps, minified bundles
- **General build**: `dist`, `build`, `out`, `target`, `coverage`
- **IDE/editor**: `.idea`, swap files (`.swp`, `.swo`)
- **Env/secrets**: `.env.local`, `.env.*.local`

**Why**: Zed indexes your project for search and symbols. Without these exclusions, you'll wait ages for indexing and get garbage results from generated files.

---

## What You'll Need to Change

Every setting that requires local adaptation is tagged in the source:

| Tag | Meaning | Example |
|---|---|---|
| `[USER-SPECIFIC]` | Depends on installed fonts/themes/extensions | Operator Mono, Kanagawa theme |
| `[MACHINE-SPECIFIC]` | Depends on local paths or hardware | JDK path, JVM heap size, terminal shell |
| `[PROJECT-SPECIFIC]` | Depends on codebase | cSpell dictionary words |

### Common Substitutions

| If you don't have... | Replace with... |
|---|---|
| Operator Mono | `"Fira Code"` (free, includes ligatures) |
| Kanagawa theme (VS Code) | `"One Dark Pro"` or any installed theme |
| Homebrew JDK 21 | Output of `/usr/libexec/java_home -V` |
| 16 GB+ RAM | Lower `-Xmx12G` to `-Xmx4G` or `-Xmx6G` |
| macOS | Change `terminal.integrated.defaultProfile.osx` to your OS equivalent |

---

## Philosophy

These configs share a few principles across both editors:

1. **Reduce noise, show signal** — Minimap as abstract blocks, inlay hints on-demand (VS Code) or scoped to literals (Zed), ESLint warnings not errors, inactive pane dimming.
2. **Let formatters own formatting** — Per-language formatter delegation (Prettier, markdownlint, built-in JSON). No global format-on-save surprises.
3. **Sidebar right, always** — Code stays pinned to the left gutter. Toggling panels doesn't shift your reading position.
4. **Italic = type-level** — Comments, types, interfaces, decorators, and keywords render in italic. Value-level code stays upright. You can read the architecture at a glance.
5. **AI-assisted, human-approved** — AI tools run with broad permissions but terminal commands go through a granular allowlist. The agent works for you, not the other way around.
6. **Performance by exclusion** — Aggressive file watcher and scan exclusions. Don't let the editor waste cycles on `node_modules` and build artifacts.

---

## License

Do whatever you want with these. No attribution needed. If something here makes your day better, that's the whole point.
