# Dotfiles

A terminal and editor setup that behaves like **one environment** instead of four
applications that happen to be open at once — same font, same palette, same
theme, same muscle memory.

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
├── opencode/opencode.jsonc     # OpenCode models, agents, and permissions
├── opencode/AGENTS.md          # global OpenCode agent instructions
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

#### Theme is pinned dark

```
theme = Catppuccin Mocha
```

Dark regardless of the macOS appearance, matching Zed — which is likewise pinned
with `"theme": { "mode": "dark" }` rather than `"system"`. Light terminals are a
worse reading surface here: dark-text-on-light renders visually heavier, which
fights an already-light typeface, and the prompt's ANSI colors are tuned against
a dark background.

Ghostty *does* support following the system, if you'd rather:

```
theme = light:Catppuccin Latte,dark:Catppuccin Mocha
```

If you use that form, note the common mistake — `light:X,dark:X` with the *same*
theme in both slots silently does nothing.

#### Font stack, not a font compromise

```
font-family = Operator Mono Lig
font-family = MesloLGS Nerd Font Mono
font-thicken = false
adjust-cell-height = 12%
```

Ghostty falls back **per codepoint**. Text renders in the editor's font; icons
render in the font that has icons. No single-font compromise, and it degrades
gracefully on a machine without Operator Mono. Bold is handled separately —
see the next section.

**`font-thicken` is off on purpose.** It defaults to strength `255` — the
maximum — and stacks on top of synthetic bold. It's also backwards in light
mode, where dark-text-on-light already reads heavier. If text looks thin to you
in dark mode, enable it *and* dial the strength down (`font-thicken-strength =
40`), rather than flipping it on at full blast.

`adjust-cell-height` approximates Zed's `"buffer_line_height": "comfortable"` —
terminal cells are tighter by default.

#### Bold comes from a different family on purpose

`Operator Mono Lig` ships **no bold face** — only Book and Light:

```bash
$ ghostty +list-fonts | grep -A4 '^Operator Mono Lig$'
Operator Mono Lig
  Operator Mono Lig Book
  Operator Mono Lig Book Italic
  Operator Mono Lig Light
  Operator Mono Lig Light Italic     # <- no Bold. none.
```

Terminals render a *lot* of bold — eza bolds directories, `ls -l` bolds
permissions, `grep` bolds matches — so without a real face all of it gets
synthesized by dilating strokes, which looks clumsy and heavy.

The fix borrows bold from the non-ligature `Operator Mono` family, whose metrics
are **identical** to the Lig cut (x-height 490, cap height 620, advance 550 —
measured from the `.otf` files), so bold text lines up perfectly:

```
font-family             = Operator Mono Lig
font-family-bold        = Operator Mono
font-style-bold         = Bold
font-family-bold-italic = Operator Mono
font-style-bold-italic  = Bold Italic
```

`font-style-bold` is **required**, not cosmetic. Hoefler registers this family's
weights unusually — `Book` is `usWeightClass` 325 and `Bold` is 400, not the
standard 700 — so weight matching alone will not find the bold face.

Verify it resolved with Ghostty's own tool:

```bash
$ ghostty +show-face --string=A --style=bold
U+41 « A » found in face "Operator Mono".
```

#### A note on font cuts

There is a third cut, `Operator Mono SSm Lig`, which also has a real bold — it
looks like the obvious answer and **it isn't**. Worth knowing why before you
"fix" anything here.

Measured from the actual font files (both 1000 upem, both `usWeightClass` 400):

| Metric | `Lig Book` | `SSm Lig Book` | Δ |
|---|---:|---:|---:|
| x-height | 490 | 544 | **+11.0%** |
| cap height | 620 | 688 | **+11.0%** |
| advance width | 550 | 625 | **+13.6%** |
| stem width (`l`) | 401 | 446 | **+11.2%** |
| ascender / descender | 960 / −240 | 960 / −240 | 0% |

SSm is Hoefler's **ScreenSmart** cut: bigger x-height and fatter stems so glyphs
survive being rasterized across very few pixels. Note the vertical metrics are
*identical* — so at the same nominal `font-size`, SSm draws ~11% larger, ~11%
heavier glyphs into the same line box. Denser text, more antialiased edge per
stroke, and on a Retina panel that reads as **soft rather than crisp**.

ScreenSmart's payoff depends on a rasterizer that snaps stems to the pixel grid.
macOS hasn't done that since it dropped subpixel antialiasing in Mojave — it
renders pure grayscale AA with no stem snapping. So on this hardware you inherit
all of SSm's design compromises and none of its benefit.

This was tried as the terminal font, on the theory that a real bold beat a
synthesized one. It does — but it trades a bold-weight problem for a
whole-screen sharpness problem, which is a bad deal. Borrowing bold from the
non-ligature `Operator Mono` family (above) fixes the bold without touching
anything else, so that's what both surfaces use.

Both Ghostty and Zed therefore run `Operator Mono Lig` at 16 with identical
metrics. Nothing to reconcile.

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
actual RGB. Change the Ghostty theme and the prompt re-colors itself for free —
including if you switch back to a light/dark auto-switching theme, where
hardcoded hex would be correct in exactly one of the two modes. A named palette
keeps that readable:

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

**Theme & type.** Catppuccin Latte / Mocha, Operator Mono Lig at 16 — identical
to the terminal, so code looks the same in both — with
`theme_overrides` applying italic across ~11 syntax scopes — comments, keywords,
types, decorators, parameters, escapes. With a font that has a true italic, this
makes structure readable at a glance: *italic = type-level, upright =
value-level.* The Ghostty config deliberately mirrors the font, size, and cursor
shape.

**JS/TS toolchain is oxc, not ESLint/Prettier.** Project-local `oxfmt` and
`oxlint` language servers handle formatting, diagnostics, and
`source.fixAll.oxc` on save. Zed's bundled Biome and ESLint servers are blocked
to prevent duplicate diagnostics and competing fixes. JSON and JSONC use the
same `oxfmt` language server.

**Focus helpers.** Inactive panes dim to 75%, autosave on focus change, smartcase
search, wrap guides at 80/100/120 for the three conventions you actually meet.

**Agent setup is two-tier** — GPT-5.6 Sol with thinking for agent tasks and the
faster GPT-5.6 Terra for inline edits where latency beats deliberation. Both use
Zed's OpenAI subscription provider.

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

## OpenCode

The global OpenCode setup defines models, specialized subagents, reusable
commands, permission guardrails, watcher exclusions, and the Playwright MCP
server. `AGENTS.md` supplies cross-project engineering rules that project-level
instructions can override.

Both files are symlinked into `~/.config/opencode/`, so local edits remain
visible to Git. Provider authentication is stored separately and is not part of
the repository.

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

1. **One environment, not four apps.** Font, palette, cursor, and theme are
   shared across terminal and editors — all pinned to Catppuccin Mocha, not
   following the system. Context switching should cost nothing visually.
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

## Useful Workflows

Everything above is *what* is configured. This is *how to actually use it.* The
compounding wins are in the combinations, not the individual tools.

### Learn these five first

If you take nothing else from this repo, take these. They cover most of the
daily friction:

| | |
|---|---|
| `z <fragment>` | Jump to any directory you've visited, from anywhere |
| `Ctrl-R` | Fuzzy-search your whole shell history |
| `Ctrl-T` | Fuzzy file picker, inserted into the command you're typing |
| `alt+b` / `alt+f` / `alt+d` | Move and delete by *word* on the command line |
| `cmd+d` | Split the terminal |

### Getting somewhere

`zoxide` ranks directories by frecency, so partial names are usually enough:

```bash
z dash          # -> ~/Documents/programming/funsaized/dashavatara
z fun s11a      # multiple fragments narrow it down; order doesn't matter
z -             # back to the previous directory
zi              # can't remember the name? interactive picker
```

`z` only knows directories you've actually `cd`'d into before, so it gets better
over the first week. For anything it doesn't know yet, `Alt-C` fuzzy-searches
directories under the current one with a tree preview.

### The `**` trigger — the most underrated thing here

Type `**` then `Tab` after almost any command to get a fuzzy picker for that
command's argument:

```bash
vim **<TAB>              # pick a file, fuzzily, from anywhere below cwd
cd **<TAB>               # pick a directory
kill -9 **<TAB>          # pick a process (Tab multi-selects)
ssh **<TAB>              # pick a host from ~/.ssh/config and known_hosts
unset **<TAB>            # pick an env var (also: export, unalias)
```

It works after *any* command — the default is a fuzzy path picker, which is what
you want most of the time. `kill`, `ssh`, `telnet`, `export`, `unset` and
`unalias` have purpose-built pickers instead. It replaces most of the `ls` →
squint → retype loop.

There's no git-aware picker, so `git checkout **<TAB>` completes *paths*, not
branch names — use `lg` for branch switching, or plain `git branch`, which this
config sorts most-recent-first.

### Finding things, then opening them

`rg` and `fd` both respect `.gitignore` by default, so results are signal:

```bash
rg "useEffect"                    # search contents
rg -l "useEffect"                 # just the filenames
fd component                      # search filenames
fd -e ts -e tsx                   # by extension
```

Chain either into fzf when you want to browse before committing to a file:

```bash
rg -l "TODO" | fzf --preview 'bat --color=always {}'
```

`Ctrl-T` already does this for the general case — it previews with `bat`, so you
can read a file's contents before selecting it, and it inserts the path into
whatever command you were already typing.

### The git loop

```bash
gs                # short status with branch line
gd                # diff -> delta, side-by-side, word-level highlighting
ga -p             # stage hunk by hunk, also rendered through delta
gc "message"
gp                # no -u needed, even on a brand-new branch
```

Inside any delta pager, `n` and `N` jump **between files** rather than scrolling
line by line — much faster on a large diff. File paths are hyperlinked; cmd-click
opens them.

For anything more involved than "stage everything", `lg` (lazygit) is faster than
the CLI — staging individual lines, interactive rebase, reflog browsing, and
resolving conflicts all have real UI.

Occasionally useful:

```bash
gl                # last 20 commits as a graph
git last          # what did I just commit?
git amend         # fold staged changes into it, keep the message
git unstage <f>   # the opposite of git add, without googling it
git churn         # files changed most often -- a decent proxy for risk
```

Two settings pay off silently. `rerere` records how you resolved a conflict and
replays it if the same one reappears, which matters on long-lived branches. And
`zdiff3` puts the **common ancestor** in conflict blocks, so instead of guessing
which of two versions is right, you can see what each side actually changed.

### Working in splits

```
cmd+d              split right          cmd+alt+←↑↓→   focus by direction
cmd+shift+d        split down           cmd+[ / cmd+]  cycle splits
cmd+shift+enter    zoom / unzoom        cmd+alt+=      equalize
```

The zoom is the one people miss. Run a dev server in one split and tests in
another, then `cmd+shift+enter` to blow either up to full window when you need
to actually read the output, and again to drop back. No layout to rebuild.

`` cmd+` `` opens the quick terminal over whatever app is focused — a scratchpad
for a one-off command without leaving Zed or the browser. It hides again on blur.

`cmd+f` searches scrollback.

### Command-line editing

These only work because `macos-option-as-alt = true`; on a stock macOS terminal
Option never reaches zsh.

| | |
|---|---|
| `alt+b` / `alt+f` | Back / forward one word |
| `alt+d` | Delete the word ahead of the cursor |
| `alt+backspace` | Delete the word behind the cursor |
| `ctrl+a` / `ctrl+e` | Start / end of line |
| `ctrl+w` | Delete previous word |
| `ctrl+u` | Clear the whole line |
| `→` at end of line | Accept the greyed-out autosuggestion |

The greyed-out text as you type is `zsh-autosuggestions` proposing your most
recent matching command. Commands turn **green when valid and red when not**,
before you press Enter — a typo'd command name is visible immediately.

### Reading output

```bash
b file.ts                    # bat: syntax highlighting + line numbers
ll                           # long listing, with per-file git status
lt                           # 2-level tree, respecting .gitignore
some-command | jq '.data[]'  # slice JSON
```

Selecting text with the mouse copies it to the system clipboard immediately —
there is no `cmd+c` step — and trailing whitespace is stripped on the way out,
so copying a block of terminal output doesn't paste a ragged right edge.

### The config edit loop

```bash
editghost      # then cmd+shift+, to reload Ghostty live -- no restart
editstarship   # takes effect on the very next prompt
editzsh        # then: reload
```

Before reloading Ghostty, `ghostty +validate-config` will catch typos. Worth
knowing when a change appears to do nothing:

```bash
ghostty +show-config              # what Ghostty thinks its config IS
ghostty +show-face --style=bold --string=A   # which font face a style resolves to
starship explain                  # which prompt modules actually rendered
starship timings                  # per-module cost
```

`starship explain` is the one to reach for when you add a module and nothing
appears — it only lists modules that rendered, so a missing entry means the
module isn't in your `format` string.

### Per-project environments

Drop an `.envrc` in a project, then:

```bash
direnv allow
```

Variables load on `cd` in and unload on `cd` out. The prompt shows a `📁`
indicator with the current state, so a **blocked** `.envrc` — the usual cause of
"why aren't my env vars set" — is visible rather than silent.

### Cheat sheet

| Keys / command | Does |
|---|---|
| `z <frag>` · `zi` · `z -` | Jump to directory · pick interactively · go back |
| `Ctrl-R` · `Ctrl-T` · `Alt-C` | History · file picker · directory picker |
| `**<TAB>` | Fuzzy-complete any command's argument |
| `alt+b` `alt+f` `alt+d` | Word back · word forward · delete word |
| `cmd+d` · `cmd+shift+d` | Split right · split down |
| `cmd+alt+←↑↓→` · `cmd+shift+enter` | Focus split · zoom split |
| `` cmd+` `` · `cmd+f` | Quick terminal · search scrollback |
| `gs` `gd` `ga -p` `gc` `gp` | Status · diff · stage hunks · commit · push |
| `lg` · `gl` · `git churn` | lazygit · log graph · highest-churn files |
| `ll` `lt` `b` | Listing w/ git · tree · bat |
| `n` / `N` in a diff | Jump between files in the pager |
| `editghost` + `cmd+shift+,` | Edit and hot-reload terminal config |

---

## License

Do whatever you want with these. No attribution needed. If something here makes
your day better, that's the whole point.
