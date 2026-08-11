# Methodology

How the terminal configs in this repo were derived. Written down because the
*reasoning* is the reusable part — the specific values will drift, but the way
of arriving at them shouldn't.

---

## 1. Read the whole system before changing one file

The request was "customize my Ghostty config." Ghostty's config was two lines.
Nothing useful could be decided from it alone.

What actually determined the outcome:

| Read | What it settled |
|---|---|
| `~/.config/zed/settings.json` | Font, size, theme pair, cursor shape, pane-dimming — the terminal should agree with the editor, not compete with it |
| `~/.zshrc` | What's already installed, what's missing, and the plugin load order |
| `~/.config/starship.toml` | Where the prompt was lying about what it rendered |
| `system_profiler SPFontsDataType` | Whether Operator Mono Lig was even available (it was) |
| `ghostty +show-config` | Which config files were actually in effect |

The single most valuable find — that Ghostty was **merging two config files** —
came from `+show-config`, not from reading either file. Settings from
`~/.config/ghostty/config` and from `~/Library/Application Support/…/config`
both appeared in the effective config. That explains a class of bug where you
edit a config and nothing changes.

**Rule: ask the tool what it thinks its configuration is. Don't infer it from
the files you happen to know about.**

---

## 2. Dead configuration is invisible unless you go looking

The previous `starship.toml` was 521 lines. Roughly 150 of them never rendered
a single character.

Starship only renders modules named in the `format` string. The file had fully
configured `[package]`, `[battery]`, `[memory_usage]`, `[shell]`, `[ruby]`,
`[php]`, `[terraform]`, `[conda]`, `[aws]`, and `[kubernetes]` blocks — none of
which appeared in `format`. They had been carefully tuned and were no-ops.

This is a general failure mode for any config with an explicit render list:
the block *looks* live, the tool never warns you, and the file grows.

**Rule: for every configured module, verify it appears in the render list. If
the tool has a "show what you'd actually output" command, run it.**

Verified after the rewrite with:

```bash
starship explain    # lists only modules that actually rendered
starship timings    # per-module cost, only for modules that ran
```

---

## 3. Measure before claiming a performance win — this one backfired

The plan asserted that `git_metrics` was "the single most expensive thing you
can put in a prompt" because it runs `git diff --shortstat` every time.

`starship timings` supported that at the module level:

```
git_metrics  -  14ms
directory    -   9ms
git_status   -  <1ms
```

Then the *whole prompt* got timed, 15 runs, in a 1267-file repo with a dirty
worktree:

```
with    git_metrics ... 45.3 ms/prompt
without git_metrics ... 46.5 ms/prompt
```

**No improvement.** Starship runs modules in parallel, so a 14 ms module hides
behind the others. The ~35 ms floor is starship's own process startup, and
nothing in the config file moves it.

`git_metrics` stayed disabled — but for signal-to-noise, which is an honest
reason, rather than for speed, which was a false one. The measurement is
recorded in `starship/starship.toml` so nobody re-derives the wrong conclusion.

**Rule: a profiler showing a component is expensive does not mean removing it
makes the system faster. Time the end-to-end thing, before and after.**

---

## 4. Verify against the installed version, never from memory

Terminal config options get renamed between releases. Every option written here
was checked against the actual binary first:

```bash
ghostty +show-config --default        # real option names, real defaults
ghostty +list-themes                  # exact theme strings
ghostty +validate-config --config-file=<path>
```

This caught several things memory would have gotten wrong:

- `scrollback-limit` already defaults to 10,000,000 — a "bump the scrollback"
  line would have been a no-op pretending to be an improvement.
- `copy-on-select` was already `true`; the useful change was the *different*
  value `clipboard`, not enabling it.
- `bell-features` accepted the new value but `+show-config` then printed
  nothing for it — because that flag set is semantically identical to the
  default, and plain `+show-config` prints only non-default values.

**Every validation needs a control.** `+validate-config` exited 0 on the new
config, which proves nothing unless you know it can fail. Feeding it a file
containing `this-is-not-a-real-option = 1` produced `unknown field` — only then
was the passing result meaningful.

The same control discipline exposed that `+show-config` silently **ignores**
`--config-file`, so any conclusion drawn from
`ghostty +show-config --config-file=…` would have been fiction.

---

## 5. Prefer indirection the theme can drive

The prompt could have hardcoded Catppuccin Mocha hex values. It doesn't.

Ghostty switches between Catppuccin Latte and Mocha with the macOS appearance.
Hardcoded hex would be correct in exactly one of those modes. ANSI color names
(`cyan`, `purple`, `red`) are resolved by the terminal's active palette, so the
prompt re-colors itself for free when the theme flips.

Starship palettes give this a readable name layer without giving up the
indirection:

```toml
palette = "adaptive"

[palettes.adaptive]
dir = "cyan"      # not "#89b4fa"
vcs = "purple"
```

**Rule: bind to the semantic layer that something else already maintains.**

This is also why the terminal font list is `Operator Mono Lig` followed by
`MesloLGS Nerd Font Mono`. Ghostty falls back per-codepoint, so text uses the
editor's font and icons use the font that has icons — no compromise face, and
it degrades to plain Meslo on a machine without the commercial font.

---

## 6. Fix load-bearing order, not just values

Two ordering bugs mattered more than most of the settings:

**`zsh-syntax-highlighting` was sourced mid-file.** It wraps every ZLE widget
that exists *at the moment it is sourced*. Anything defining widgets later —
fzf, zoxide, direnv — ends up unhighlighted. It now runs last, and the file
carries a comment explaining why so it doesn't drift back.

**`$EDITOR` was referenced before assignment.** The `edit*` aliases are defined
with double quotes, so `$EDITOR` expands at *definition* time. Defined after,
the aliases silently became bare filenames. The export moved above them.

**Rule: in shell config, position is semantics. Comment the constraint at the
line that depends on it.**

---

## 7. Design against the failure mode, not just the happy path

Three choices exist purely because of how they fail:

- **`cat` is not aliased to `bat`.** Shadowing a coreutil is fine until it
  isn't — inside a one-off pipeline, at 2am. The alias is `b`.
- **Editor settings are copied by `install.sh`, not symlinked.** They contain
  API-key fields. Symlinking would overwrite real keys with placeholders on
  install, and worse, put real keys into `git status` once filled in. That is
  precisely how credentials reach public repos. Shell and terminal configs hold
  no secrets, so those *are* symlinked and stay live-editable.
- **`scripts/scan-secrets.sh` exists and runs as a pre-commit hook**, because
  the previous point is a mitigation, not a guarantee.

---

## 8. Leave the reasoning in the file

Every non-obvious line in these configs carries a comment saying *why*, not
*what*. `background-opacity = 0.95` needs no explanation. These do:

- why `macos-option-as-alt = true` (macOS eats Option, so `alt+b`/`alt+f` never
  reach zsh)
- why `shell-integration-features` includes `sudo` (`SUDO_TERMINFO`, so
  `sudo vim` doesn't get a broken `TERM`)
- why `git_metrics` is off (with the measurement that contradicted the guess)
- why the Application Support config is an empty stub (it merges)

A value you can't explain is a value you can't safely change later.

---

## Verification log

Everything asserted above was checked, not assumed:

| Claim | Check |
|---|---|
| Both Ghostty configs load | `+show-config` showed keys from both files |
| New Ghostty config is valid | `+validate-config`, with a failing control |
| `global:` prefix is real | found in `+show-config --default --docs`; available since 1.0.0 |
| Options resolve as written | `+show-config` after consolidation |
| Starship parses and renders | `starship explain`, `starship prompt` |
| `git_metrics` removal is not a speedup | 15-run timing, both configs, dirty 1267-file repo |
| gitconfig inline `;` comments parse | `git config --get` returned clean values |
| delta renders | real diff through `delta --paging=never` |
| zsh loads clean | `zsh -i` under a pty — the `zle` warning is a no-TTY artifact |
| Repo has no live credentials | `scripts/scan-secrets.sh`, with a planted-token control |
| `install.sh` is non-destructive | `--dry-run`, then confirmed `~/.zshrc` was untouched |
