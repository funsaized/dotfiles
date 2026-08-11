# Dotfiles

A terminal and editor setup that behaves like **one environment** instead of four
applications that happen to be open at once — same font, same palette, same
light/dark switch, same muscle memory.

Tuned for full-stack TypeScript / Java / Python with AI-assisted workflows on
macOS. Every non-obvious line carries a comment explaining *why*, and the
reasoning behind the whole thing is written up in
[`docs/METHODOLOGY.md`](docs/METHODOLOGY.md).

Take what works. Ignore the rest.

---

## Contents

```
dotfiles/
├── ghostty/config              # terminal — theme, font, splits, keybinds
├── starship/starship.toml      # prompt
├── zsh/.zshrc                  # shell — PATH, tools, aliases, plugin order
├── git/.gitconfig              # git + delta diffs
├── zed/settings.json           # Zed editor
├── vscode/settings.json        # VS Code
├── claude/skills/notebooklm/   # Claude Code skill — NotebookLM bridge
├── scripts/scan-secrets.sh     # credential scanner + pre-commit hook
├── docs/METHODOLOGY.md         # how these decisions were made
└── install.sh                  # symlink bootstrap
```

---

## Install

```bash
git clone https://github.com/funsaized/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run     # see exactly what would change
./install.sh --brew        # install CLI tools, then link everything
```

Nothing is ever clobbered — existing files are moved to `<name>.bak-<timestamp>`
first.

**Shell and terminal configs are symlinked** so editing `~/.zshrc` edits the
repo and `git diff` shows your drift. **Editor configs are copied, not
symlinked**, because they contain API-key fields — see
[§7 of the methodology](docs/METHODOLOGY.md#7-design-against-the-failure-mode-not-just-the-happy-path)
for why that asymmetry exists.

### Fonts (not installed automatically)

```bash
brew install --cask font-meslo-lg-nerd-font   # required — icons and glyphs
```

[Operator Mono](https://www.typography.com/fonts/operator/overview) is
commercial and optional. Without it, delete one line in `ghostty/config` and
Meslo takes over as the primary face — everything still works.

---

## The Terminal Stack

### Ghostty

**One config file, not two.** On macOS, Ghostty loads *both*
`~/.config/ghostty/config` and
`~/Library/Application Support/com.mitchellh.ghostty/config` and merges them.
Splitting settings across the two is how you edit a config and see no change.
Everything lives in the former; `install.sh` neutralizes the latter.

#### Theme follows the system

```
theme = light:Catppuccin Latte,dark:Catppuccin Mocha
```

Pairs with Zed's theme block, so the editor and terminal flip together at dusk
instead of clashing. A common mistake is `light:X,dark:X` with the same theme in
both slots — that silently does nothing.

#### Font stack, not a font compromise

```
font-family = Operator Mono SSm Lig
font-family = MesloLGS Nerd Font Mono
font-thicken = false
adjust-cell-height = 12%
```

Ghostty falls back **per codepoint**. Text renders in the editor's font; icons
render in the font that has icons. No single-font compromise, and it degrades
gracefully on a machine without Operator Mono.

**Pick the cut with a real bold.** Plain `Operator Mono Lig` ships only Book and
Light — *no bold face at all*. Terminals render a lot of bold (eza bolds
directories, `ls -l` bolds permissions, grep bolds matches), so the renderer has
to synthesize it by dilating strokes, which looks clumsy and heavy. The `SSm Lig`
cut ships real Book/Medium/Bold plus italics for each, and SSm ("Screen Smart")
is Hoefler's screen-optimized variant — tighter sidebearings, hinting tuned for
small sizes. Check what you have with `ghostty +list-fonts | grep -A8 Operator`.

**`font-thicken` is off on purpose.** It defaults to strength `255` — the
maximum — and stacks on top of synthetic bold. It's also backwards in light
mode, where dark-text-on-light already reads heavier. If text looks thin to you
in dark mode, enable it *and* dial the strength down (`font-thicken-strength =
40`), rather than flipping it on at full blast.

`adjust-cell-height` approximates Zed's `"buffer_line_height": "comfortable"` —
terminal cells are tighter by default.

#### The one setting that fixes daily friction

```
macos-option-as-alt = true
```

Without it macOS swallows Option, zsh never receives a Meta key, and `alt+b` /
`alt+f` (jump word), `alt+d` (kill word) and `alt+backspace` all silently do
nothing. This is usually the largest single quality-of-life change in the file.

#### Keybinds

| Keys | Action |
|---|---|
| `cmd+d` / `cmd+shift+d` | split right / split down |
| `cmd+alt+←↑↓→` | focus split by direction |
| `cmd+shift+enter` | zoom the current split |
| `cmd+alt+=` | equalize splits |
| `` cmd+` `` | quick terminal — a **global** dropdown over any app |
| `cmd+shift+,` / `cmd+,` | reload config / open config |

The quick terminal is a system-wide hotkey; macOS may ask for accessibility
permission the first time.

Unfocused splits dim to `0.85`, mirroring Zed's `active_pane_modifiers`.

#### Other choices worth knowing

- `copy-on-select = clipboard` — selecting text puts it on the system
  clipboard, no `cmd+c`. (The default `true` uses the *selection* clipboard,
  which is not the same thing.)
- `shell-integration-features = cursor,sudo,title` — `sudo` exports
  `SUDO_TERMINFO` so `sudo vim` doesn't land in a broken `TERM`.
- `bell-features = attention,title,no-audio` — a finished build bounces the
  Dock icon and marks the tab. No sound.
- `window-colorspace = display-p3` — wide gamut on Apple panels, no frame cost.

#### SSH caveat

Ghostty sets `TERM=xterm-ghostty`, which won't exist on your servers. Push the
terminfo once per host instead of downgrading `TERM` globally:

```bash
infocmp -x xterm-ghostty | ssh YOUR_HOST -- tic -x -
```

---

### Starship

Emoji-forward, two-line, and — the point of the rewrite — **honest about what
it renders**.

```
📄/dev on 🌿 main [📝2 ✅1] via ⚡v22.11
➜
```

**Colors are ANSI names, never hex.** The terminal's active palette owns the
actual RGB, so when Ghostty flips Catppuccin Latte → Mocha the prompt re-colors
itself for free. Hardcoded hex would be correct in exactly one of the two modes.
A named palette keeps that readable:

```toml
palette = "adaptive"

[palettes.adaptive]
dir = "cyan"      # not "#89b4fa"
vcs = "purple"
```

**Every configured module appears in `format`.** The previous version of this
file was 521 lines, ~150 of which never rendered a single character — ten fully
tuned modules absent from the format string. Starship never warns you about
this. Check with `starship explain`, which lists only what actually rendered.

Other fixes:

- `command_timeout` 500 → 1000 ms. The `[java]` module shells out to
  `java -version`; under SDKMAN that routinely exceeds 500 ms, so it had been
  silently timing out and rendering nothing.
- Added `[direnv]`. You run `direnv hook zsh` but had no indicator, so a blocked
  `.envrc` — the usual "why aren't my env vars set" case — was invisible.
- Dropped `$git_metrics`, **but not for the reason you'd guess.** It is the most
  expensive single module (14 ms), yet removing it changed end-to-end prompt
  time by nothing at all, because starship runs modules in parallel. Measured
  numbers are in the config file and in
  [§3 of the methodology](docs/METHODOLOGY.md#3-measure-before-claiming-a-performance-win--this-one-backfired).

---

### Zsh

Sections are ordered by dependency, and two of those orderings are load-bearing:

**`zsh-syntax-highlighting` must be last.** It wraps every ZLE widget that
exists *at the moment it is sourced*. Anything defining widgets afterwards —
fzf, zoxide, direnv — ends up unhighlighted. It previously sat mid-file with
fzf and zoxide loading after it.

**`$EDITOR` must be exported before the `edit*` aliases.** Those aliases are
defined with double quotes, so `$EDITOR` expands at *definition* time; defined
after, they silently become bare filenames.

#### Tools

| Tool | What it buys |
|---|---|
| `fzf` | `Ctrl-R` fuzzy history, `Ctrl-T` file picker, `Alt-C` dir jump — all with `bat`/`eza` previews |
| `zoxide` | `z dash` jumps to the right directory from anywhere; `zi` for an interactive pick |
| `delta` | side-by-side diffs with word-level intra-line highlighting |
| `lazygit` | full git TUI (`lg`) |
| `eza` / `bat` / `fd` / `rg` | modern `ls` / `cat` / `find` / `grep` |

`fd` powers the fzf pickers so they respect `.gitignore` and skip `.git/`, and
fzf is themed to match Ghostty and Zed.

**`cat` is deliberately *not* aliased to `bat`.** Shadowing a coreutil is fine
until it isn't — inside a one-off pipeline, at 2am. The alias is `b`.

---

### Git + delta

```ini
[core]        pager = delta
[interactive] diffFilter = delta --color-only   # `git add -p` too
[delta]       navigate = true, side-by-side = true, line-numbers = true
```

Beyond delta, the settings that actually change day-to-day behavior:

| Setting | Why |
|---|---|
| `merge.conflictstyle = zdiff3` | Shows the common ancestor in conflict blocks — turns "which of these is right?" into "here's what each side changed" |
| `diff.algorithm = histogram` | Smarter hunk boundaries; stops diffs splitting on a lone `}` |
| `push.autoSetupRemote = true` | `git push` on a new branch just works |
| `rerere.enabled = true` | Remembers conflict resolutions and replays them |
| `fetch.prune = true` | Drops local refs for branches deleted upstream |
| `branch.sort = -committerdate` | `git branch` lists most-recent first |

Plus `git churn` — files changed most often, a decent proxy for where the risk
lives.

---

## Editors

### Zed

**Theme & type.** Catppuccin Latte / Mocha, Operator Mono SSm Lig at 16 — the
same cut as the terminal, for the same reason — with
`theme_overrides` applying italic across ~11 syntax scopes — comments, keywords,
types, decorators, parameters, escapes. With a font that has a true italic, this
makes structure readable at a glance: *italic = type-level, upright =
value-level.* The Ghostty config deliberately mirrors the font, size, and cursor
shape.

**JS/TS toolchain is oxc, not ESLint/Prettier.** `oxfmt` handles formatting via
the CLI with `--stdin-filepath`, and `oxlint` handles diagnostics plus
`source.fixAll.oxc` on save. Zed's bundled `eslint` is blocked everywhere with
`"!eslint"`. The config carries a note that `oxfmt --lsp` is broken in 0.16
(returns null for every format request), which is why formatting goes through
the CLI instead — the kind of detail that costs an hour to rediscover.

**Focus helpers.** Inactive panes dim to 75%, autosave on focus change, smartcase
search, wrap guides at 80/100/120 for the three conventions you actually meet.

**Agent setup is two-tier** — a thinking model for agent tasks, a fast codex
model for inline edits where latency beats deliberation.

> Replace the `YOUR KEY HERE` / `YOUR PAT HERE` placeholders in
> `context_servers` before use. `ssh_connections` is intentionally empty.

### VS Code

Maintained as a fallback rather than a daily driver. Highlights:

- **Font stack degrades gracefully** — Operator Mono → Fira Code → system mono,
  so it works on a machine without the commercial font.
- **`editor.formatOnSave: false`**, with formatting delegated per language. No
  surprise reformats in unfamiliar codebases.
- **`inlayHints: "offUnlessPressed"`** — useful on demand, noise otherwise.
- **`gotoLocation.multipleDefinitions: "gotoAndPeek"`** — jumps to the best match
  *and* peeks the alternatives.
- **Java LSP tuned** — G1GC with string dedup and a 12 GB heap; drop `-Xmx` if
  you have under 16 GB.
- **~130-line Copilot terminal allowlist** — read-only commands auto-approved,
  destructive ones blocked, with regex carve-outs for the edge cases (`sort -o`
  writes to a file; `find -exec` runs arbitrary commands).

---

## Claude Code Skills

### notebooklm — NotebookLM bridge

Import content into Google NotebookLM from Claude Code, and query it with cited
answers traced to exact source passages.

**Sources**: YouTube channels (bulk-load up to 300 episodes), individual videos,
podcasts, webpages, PDFs, images, Google Docs/Slides, plain text.

**Prerequisites**: `nlm` CLI (`uv tool install notebooklm-mcp-cli`) and
`notebooklm-py` (`pip install "notebooklm-py[browser]"`). Full setup in
[`claude/skills/notebooklm/SKILL.md`](claude/skills/notebooklm/SKILL.md).

**Triggers**: "notebooklm", "load channel", "add to notebook", "notebooklm ask".

---

## Secrets

This repo publishes editor configs that contain API-key *fields*. They're meant
to hold placeholders. One careless copy from a live machine and they hold a real
token — in a public repo.

```bash
./scripts/scan-secrets.sh            # scan the working tree
./scripts/scan-secrets.sh --install  # run it as a pre-commit hook
```

The scanner matches real token *shapes* (`ghp_…`, `sk-ant-…`, `AKIA…`, private
key headers) rather than the word "token", so documentation doesn't trip it.

---

## Adapting This

Settings needing local changes are tagged in the source:

| Tag | Meaning |
|---|---|
| `[USER-SPECIFIC]` | Depends on installed fonts, themes, or licenses |
| `[MACHINE-SPECIFIC]` | Depends on local paths or hardware |
| `[PROJECT-SPECIFIC]` | Depends on the codebase |

| If you don't have… | Replace with… |
|---|---|
| Operator Mono | Delete the line in `ghostty/config`; Meslo takes over. In Zed/VS Code use `"Fira Code"` or `"JetBrains Mono"` — both have real italics |
| A Nerd Font | Unavoidable — icons and prompt glyphs need one |
| SDKMAN | Point `lsp.jdtls` at `/usr/libexec/java_home -V` output |
| 16 GB+ RAM | Lower VS Code's `-Xmx12G` to `-Xmx4G` |
| macOS | The Ghostty `macos-*` keys are no-ops elsewhere; swap `super` for `ctrl` in keybinds |

---

## Philosophy

1. **One environment, not four apps.** Font, palette, cursor, and light/dark
   switch are shared across terminal and editors. Context switching should cost
   nothing visually.
2. **Reduce noise, show signal.** Inlay hints on demand, dimmed inactive panes,
   `git_metrics` off, ten dead prompt modules deleted.
3. **Italic = type-level.** Comments, types, interfaces, and decorators render
   italic; value-level code stays upright.
4. **Bind to the layer someone else maintains.** ANSI color names over hex.
   Font *stacks* over a single compromise face. Both adapt for free.
5. **Position is semantics.** In shell config, load order is a correctness
   property. Comment the constraint at the line that depends on it.
6. **Design against the failure mode.** Don't shadow coreutils. Don't symlink
   files with credential fields. Assume the 2am version of yourself.
7. **Measure, then claim.** A profiler showing a component is expensive doesn't
   mean removing it makes the system faster. This repo contains a worked example
   where that assumption was wrong, kept in place rather than quietly corrected.
8. **Leave the reasoning in the file.** A value you can't explain is a value you
   can't safely change later.

---

## License

Do whatever you want with these. No attribution needed. If something here makes
your day better, that's the whole point.
