# Dotbento

An opinionated bootstrap for the development machines we support:

- macOS with Zsh, Ghostty, Starship, Zed, Neovim, and OpenCode
- Omarchy Linux with its shell and terminal defaults, plus Zed, Neovim, and
  OpenCode configuration

Dotbento intentionally does not replace Omarchy's Bash, Starship, or terminal
configuration.

## Documentation

The [design notes](docs/README.md) explain the decisions and tradeoffs behind
each supported tool:

- [bootstrap](docs/bootstrap.md) and [Git ownership](docs/git.md)
- [Ghostty](docs/ghostty.md), [Zsh](docs/zsh.md), and
  [Starship](docs/starship.md)
- [Neovim](docs/neovim.md), [Zed](docs/zed.md), and
  [OpenCode](docs/opencode.md)
- the shared [visual system](docs/visual-system.md)

## Install

```bash
git clone https://github.com/funsaized/dotbento.git ~/dotbento
cd ~/dotbento

./install.sh --dry-run             # inspect config changes
./install.sh                       # asks before changing files
./install.sh --packages            # also asks before installing dependencies
./install.sh --packages --yes      # approved, non-interactive bootstrap
```

Existing files are moved to `<name>.bak-<timestamp>` before replacement.
Package installation never happens unless `--packages` is passed. Without
`--yes`, all changes require interactive approval.

Dotbento detects macOS and Omarchy Linux. Other platforms stop without making
changes.

## What gets configured

| Config | macOS | Omarchy Linux |
|---|---:|---:|
| Zed | symlink | symlink |
| Neovim | symlink | copy |
| OpenCode | symlink | symlink |
| Git | included from existing config | included from existing config |
| Zsh, Starship, Ghostty | symlink | keep Omarchy defaults |

Neovim is copied on Omarchy because `omarchy-nvim-refresh` owns and replaces
`~/.config/nvim`. Re-run Dotbento after an Omarchy Neovim refresh to restore
this opinionated setup. macOS uses a symlink so edits remain visible to Git.

`XDG_CONFIG_HOME` is respected, falling back to `~/.config`.

## Neovim

The LazyVim setup matches the plugins enabled on the reference Omarchy machine:

- Neo-tree
- JSON and SchemaStore support
- Markdown rendering and preview
- TypeScript with vtsls
- the standard LazyVim editing, completion, Git, diagnostics, and UI plugins

On Omarchy, Neovim loads the current theme from
`~/.local/state/omarchy/current/theme/neovim.lua` at startup. On macOS it uses
the bundled Aether/Gruvy Glass fallback. Restart Neovim after changing an
Omarchy theme; Dotbento deliberately avoids a live-reload watcher and a cache of
every possible colorscheme.

Remote sessions retain OSC 52 clipboard support, with Wayland integration on
Omarchy and `pbcopy`/`pbpaste` integration on macOS.

## Zed

Zed uses oxfmt and oxlint for JavaScript, TypeScript, JSON, and JSONC. Other
languages use their language server formatter. Prettier is disabled, and Java
is discovered from the machine rather than a versioned Homebrew or SDKMAN path.

The tracked settings contain no API keys, so they can remain symlinked. Configure
MCP servers and credentials outside this repository.

## OpenCode

`opencode/opencode.jsonc` and `opencode/AGENTS.md` are linked into the detected
XDG config directory. Authentication remains in OpenCode's own credential
store. Restart OpenCode after changing either file; configuration is loaded at
startup.

## macOS shell

The Zsh setup initializes Starship, direnv, zoxide, fzf, and optional language
toolchains when they are installed. Homebrew's actual prefix is detected rather
than assuming `/opt/homebrew`.

`--packages` installs the command-line tools, Zsh plugins, Ghostty, Zed,
OpenCode, and the required Nerd Font through Homebrew. Operator Mono remains an
optional commercial font.

## Omarchy

Omarchy's Bash aliases, prompt, terminal, and package conventions remain in
charge. `--packages` uses `omarchy pkg add` only for the editor/tooling packages
Dotbento needs; it does not install a second shell stack.

## Git identity

Dotbento adds its shared Git settings as an include in the global config Git
already uses: `~/.gitconfig` when present, otherwise
`$XDG_CONFIG_HOME/git/config`. Existing identity and credential helpers remain
untouched, and the repository does not track a name or email:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Verification

```bash
./scripts/scan-secrets.sh
bash -n install.sh scripts/scan-secrets.sh zsh/.zshrc
XDG_CONFIG_HOME="$PWD" nvim --headless +qa
```
