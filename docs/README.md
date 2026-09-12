# Dotbento design notes

These explanations record why Dotbento configures each tool the way it does.
They describe tradeoffs and boundaries rather than repeating configuration
syntax. Use the root [README](../README.md) when you need installation steps.

## Foundations

- [Bootstrap](bootstrap.md): supported platforms, approval, backups, and
  symlink-versus-copy decisions
- [Visual system](visual-system.md): how fonts, colors, cursors, and opacity
  connect the terminal and editors
- [Git](git.md): shared behavior without owning identity or credentials

## macOS terminal stack

- [Zsh](zsh.md): dependency order, optional tools, and restrained aliases
- [Ghostty](ghostty.md): one effective config, typography, keyboard behavior,
  splits, and clipboard policy
- [Starship](starship.md): explicit rendering, semantic colors, and measured
  prompt performance

## Editors and agents

- [Neovim](neovim.md): LazyVim parity, portable themes, and remote clipboard
  behavior
- [Zed](zed.md): formatting ownership, portable Java discovery, and shared
  visual conventions
- [OpenCode](opencode.md): agent roles, permissions, output limits, and global
  working rules

## Documentation model

These pages are Diataxis **explanations**. Their reader job is understanding
the design well enough to change it safely. Commands appear only when they help
verify a claim. Task-oriented procedures stay in the root README.
