# Why the macOS shell is ordered explicitly

The Zsh configuration is a dependency graph written as a file. Its section
order prevents tools from initializing against an incomplete environment.

Omarchy does not use this file. Dotbento prefers Omarchy's Bash defaults rather
than installing a parallel shell environment.

## PATH comes before consumers

The first section establishes Homebrew, language tools, local binaries, and the
editor. Tool initialization follows only after those paths are stable.

Homebrew's prefix comes from `brew --prefix`. This supports Apple Silicon,
Intel, and non-default Homebrew locations without branching on CPU type.

Optional managers are guarded by executable or file checks. Installing the
configuration before every tool is available should not break shell startup.

## SDKMAN wins Java selection

SDKMAN initializes after the other PATH changes. Its Java, Gradle, and Maven
shims therefore take precedence when SDKMAN is installed.

The position is the important setting. Moving the block to satisfy a generic
"installer says end of file" comment would put it after interactive plugins and
make the dependency structure less clear.

## The editor is selected before aliases

Config-editing aliases interpolate `$EDITOR` when the aliases are defined. The
variable must therefore exist first.

Dotbento prefers Neovim when installed and falls back to Vim. Existing user
choice wins over both defaults.

## Hooks initialize after PATH

Starship, direnv, zoxide, and fzf install shell hooks or widgets. They are loaded
after the final executable search path is known.

Each integration is conditional. The config can be installed without
`--packages`, and ordinary shell startup still works.

## fzf uses the modern toolchain

fzf's native Zsh integration provides history, file, and directory pickers.
`fd` replaces `find` for picker input so ignored files and `.git` internals stay
out of results.

`bat` previews files and `eza` previews directory trees when available. The fzf
palette is pinned to Catppuccin Mocha because the macOS terminal theme is also
pinned.

## Aliases should save typing without changing shell semantics

The alias set is deliberately small. `eza` replaces interactive listing
commands when installed. `bat` is exposed as `b` rather than replacing `cat`.

Keeping `cat` intact matters in pipelines and copied shell snippets. The small
typing gain from shadowing a core utility is not worth hidden behavior.

Git aliases cover common actions, while lazygit handles workflows that benefit
from a UI. `vim` maps to Neovim only when Neovim exists.

## Syntax highlighting must load last

`zsh-syntax-highlighting` wraps ZLE widgets that exist when it is sourced. If
fzf, zoxide, or another widget provider loads later, highlighting can miss or
interfere with those widgets.

Autosuggestions and syntax highlighting therefore form the final section. Both
paths use the detected Homebrew prefix.

## Machine integrations are explicit exceptions

The arbord telemetry environment and optional Logi haptics integration are
machine-oriented additions. They are isolated in their own section rather than
mixed with portable shell behavior.

This makes their ownership visible and gives future maintainers one place to
remove them when the supported machine profile changes.

## Related

- [Bootstrap platform boundary](bootstrap.md#two-supported-environments)
- [Starship prompt design](starship.md)
- [Ghostty keyboard behavior](ghostty.md#option-must-reach-zsh)
