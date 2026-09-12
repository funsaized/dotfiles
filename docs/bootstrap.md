# Why the bootstrap is conservative

Dotbento changes the working environment of an entire development machine. A
fast installer is useful, but a surprising installer is dangerous. The script
therefore treats visibility, consent, and recovery as core behavior.

## Two supported environments

Dotbento supports macOS and Omarchy Linux. Generic Linux is deliberately out of
scope.

This narrow support boundary avoids a growing matrix of package managers,
desktop conventions, and config locations. macOS receives the complete
terminal stack. Omarchy already has strong defaults, so Dotbento leaves its
Bash, Starship, and terminal setup alone.

The platform check is strict:

- Darwin selects the macOS path.
- Linux must expose the `omarchy` command.
- Every other environment stops before making changes.

Supporting another platform should be an explicit product decision. It should
not emerge from a collection of best-effort branches.

## Configuration and packages are separate choices

Running `./install.sh` configures the machine but does not install packages.
Package installation requires `--packages`. This distinction matters because
configuration is reversible local state, while package installation changes
the wider system.

Both modes ask for confirmation unless `--yes` is present. The script prints
its platform, config root, and scope before asking. `--dry-run` shows concrete
destinations and package commands without changing anything.

`--yes` is treated as explicit approval for automation. It is not the default.

## XDG paths before hardcoded home paths

Most destinations are rooted at:

```text
${XDG_CONFIG_HOME:-$HOME/.config}
```

This works with the conventional `~/.config` layout and with machines that set
a custom XDG root. Tool-specific exceptions remain where the platform requires
them, such as `~/.zshrc` and Ghostty's secondary macOS path.

## Backups are part of installation

Real files and directories move to a timestamped sibling before replacement:

```text
settings.json.bak-20260912-153000-12345
```

The process ID supplements the timestamp so two runs in one second do not
collide. Existing symlinks are removed because the target remains elsewhere.

The installer never merges arbitrary application settings. Merging creates
unclear ownership and is difficult to undo. A complete backup gives the user a
simple recovery path.

## Why most configs are symlinked

Zed, OpenCode, and the macOS configurations are symlinked. Editing the live
file then edits the repository, so `git diff` reveals drift immediately.

The linker is idempotent. A destination already pointing at the expected source
is left alone.

This model works when the application accepts user ownership of its config.
Omarchy's Neovim package is the important exception.

## Why Neovim is copied on Omarchy

Omarchy owns `~/.config/nvim` and may replace it during
`omarchy-nvim-refresh`. A repository symlink conflicts with that ownership.

Dotbento therefore:

- symlinks Neovim on macOS;
- copies Neovim on Omarchy;
- skips the copy when source and destination are identical.

After an Omarchy Neovim refresh, running Dotbento restores the opinionated
configuration. This is a deliberate handoff between two owners, not an attempt
to intercept Omarchy's update mechanism.

## Why OpenCode's alternate config is backed up

OpenCode recognizes both `opencode.json` and `opencode.jsonc`. Leaving both in
the global config directory creates ambiguous merged behavior. Dotbento backs
up an existing JSON file before linking the JSONC source of truth.

Authentication is not stored in either file. OpenCode keeps credentials in its
own store.

## Package managers follow the platform

macOS uses Homebrew for command-line tools and casks. Omarchy uses
`omarchy pkg add`, preserving the distribution's package conventions.

The Omarchy package list is intentionally smaller. It installs editor tooling,
Zed, and OpenCode, but not a duplicate shell stack. Operator Mono is not
installed anywhere because it is commercial and optional.

## Consequence of this design

Dotbento is a bootstrap, not a general-purpose dotfile manager. It supports a
small machine fleet with known conventions. That constraint keeps the script
auditable and makes its failures recoverable.

## Related

- [Neovim portability](neovim.md)
- [Git config ownership](git.md)
- [Root installation guide](../README.md#install)
