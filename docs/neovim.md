# Why Neovim is portable rather than platform-specific

Dotbento keeps one LazyVim configuration for macOS and Omarchy Linux. Platform
differences are resolved at runtime instead of maintaining two plugin trees.

## LazyVim is the base, not a template to fork

`nvim/init.lua` delegates to `config.lazy`, which bootstraps `lazy.nvim` when
needed and imports LazyVim's plugin specification. Local files override only
the behavior Dotbento intentionally changes.

This preserves LazyVim's maintained defaults for completion, diagnostics,
navigation, Git integration, and UI behavior. Dotbento does not reimplement
those systems.

Plugin releases are pinned by commit in `lazy-lock.json`. The config currently
resolves to 37 plugins. The lockfile gives both supported platforms the same
plugin graph after synchronization.

## Extras reflect the reference development workload

The selected LazyVim extras are:

- Neo-tree for file navigation;
- JSON with SchemaStore support;
- Markdown rendering and preview;
- TypeScript with vtsls.

These match the useful extras on the reference Omarchy machine. Example specs
and the preload cache for every Omarchy theme are excluded. LazyVim's own
Catppuccin and Tokyo Night support remains. Parity means matching active
development capabilities, not retaining every package once downloaded.

## Formatting remains an explicit action

`vim.g.autoformat` is disabled. Format-on-save can produce broad changes when
opening an unfamiliar repository, so Dotbento leaves formatting on
`<leader>cf`.

The formatter integration still exists. Only the trigger changes from implicit
to deliberate.

Relative line numbers remain enabled because that matches the reference
Omarchy setup and supports movement-oriented editing.

## Omarchy owns the current theme

On startup, `plugins/theme.lua` checks:

```text
~/.local/state/omarchy/current/theme/neovim.lua
```

When readable, that file supplies the complete Lazy plugin specification for
the active Omarchy theme. Dotbento does not translate theme names or duplicate
Omarchy's palette.

Outside Omarchy, the same loader returns an Aether specification with the
bundled Gruvy Glass palette.

## Why theme changes require a restart

An earlier design preloaded every supported colorscheme and watched Omarchy's
theme state. That supported live switching, but it required a custom reload
pipeline and many otherwise unused plugins.

The current design reads the theme once during startup. After
`omarchy theme set`, restart Neovim. Lazy can install the newly referenced
colorscheme if needed.

This trades a rare restart for a much smaller plugin and maintenance surface.

## Semantic italics survive colorscheme application

Colorschemes own highlight groups and may replace them when loaded. Dotbento
therefore applies its italic convention:

- once during config loading;
- after `ColorScheme`;
- after LazyVim's `VeryLazy` event.

The helper reads each existing highlight first and changes only `italic`. It
preserves foreground colors and other theme attributes.

## Transparency belongs to the terminal

The transparency plugin removes backgrounds from core windows, floating
windows, menus, line-number areas, WhichKey, and Neo-tree. It does not define an
independent opacity value.

The active terminal remains the owner of actual background opacity and blur:
Ghostty on macOS, and Omarchy's selected terminal on Linux. Neovim only allows
that surface to show through.

## Why remote clipboard handling is custom

Local graphical Neovim sessions use the built-in clipboard provider. The custom
provider activates only under tmux, SSH, or herdr.

Copies take two paths when possible:

1. Write to the local OS clipboard using `wl-copy` or `pbcopy`.
2. Emit OSC 52 so tmux or the visible terminal can forward the text.

Pastes prefer `wl-paste` or `pbpaste`. Without a local display clipboard, they
fall back to an OSC 52 query.

This dual path preserves both directions of work. A remote yank reaches the
laptop, while text copied from a browser remains pasteable inside Neovim.

Linux and macOS use different process APIs when detecting a herdr ancestor.
Linux reads `/proc`; macOS queries `ps`. That small runtime branch avoids a
second configuration tree.

## Omarchy and macOS install differently

macOS receives a symlink at `~/.config/nvim`, or the configured XDG equivalent.
Live edits therefore remain repository edits.

Omarchy receives a copy because its package tooling owns and may replace the
Neovim config directory. Identical copies are skipped. After an Omarchy refresh,
run Dotbento again to restore this configuration.

## Verification

The headless startup check uses the repository as `XDG_CONFIG_HOME`:

```bash
XDG_CONFIG_HOME="$PWD" nvim --headless +qa
```

A stricter parity check should compare every resolved Lazy plugin with a
matching `lazy-lock.json` entry.

## Related

- [Bootstrap ownership](bootstrap.md#why-neovim-is-copied-on-omarchy)
- [Visual system](visual-system.md)
- [Ghostty clipboard policy](ghostty.md#clipboard-and-selection)
