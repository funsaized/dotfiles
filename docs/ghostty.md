# Why Ghostty has one effective configuration

Ghostty is the standalone terminal for the macOS profile. Its configuration is
designed around one source of truth, predictable typography, and native terminal
features.

## One application can read two files

On macOS, Ghostty can merge:

```text
~/.config/ghostty/config
~/Library/Application Support/com.mitchellh.ghostty/config
```

Two active files make precedence hard to see. A correct edit can appear broken
because the other location overrides it.

Dotbento links the XDG-side file and neutralizes an existing Application Support
file after backing it up. The stub points readers toward the real source.

## The terminal is pinned dark

The selected theme is Catppuccin Mocha regardless of system appearance. Its
palette matches Zed and supplies Starship's semantic ANSI colors.

Following system light and dark modes would require validating typography and
prompt contrast on two surfaces. Dotbento chooses one known reading environment
instead.

## Font fallback solves a coverage problem

Operator Mono Lig is the primary text face. It does not contain the Nerd Font
glyphs used by eza and Starship, so MesloLGS Nerd Font Mono is a fallback.

Ghostty resolves fallback per codepoint. Normal text keeps the preferred face,
while icons use Meslo. The result avoids choosing an icon font as the primary
coding font.

## Bold comes from a compatible family

Operator Mono Lig has Book and Light faces but no true bold. Synthetic bold
dilates strokes and becomes especially visible in terminals, where many tools
use bold for ordinary structure.

The non-ligature Operator Mono family supplies bold and bold italic. Its metrics
match the Lig cut closely enough to preserve alignment. Explicit style names are
required because this family uses unusual numeric weight registration.

Meslo remains the fallback for those styles as well.

## Font thickening remains off

Ghostty's default thickening strength is aggressive and can compound synthetic
weight. Dark-on-light text also appears heavier than light-on-dark text, making
one global thickening choice unsuitable for a theme pair.

Because Dotbento pins a dark theme and supplies a real bold donor, thickening is
not needed. If display hardware changes, adjust the strength rather than merely
enabling the maximum.

## Option must reach Zsh

macOS normally reserves Option for character composition. Zsh then never sees
Meta sequences used by bindings such as word movement and deletion.

`macos-option-as-alt = true` sends those keys to the shell. This is an input
correctness setting, not a cosmetic preference.

## Native splits avoid another multiplexer layer

Ghostty's own split model covers the local graphical workflow. Keybindings
create horizontal and vertical splits, move focus by direction, zoom a pane,
and equalize the layout.

Unfocused panes dim, matching Zed's focus treatment. The global quick terminal
provides a separate scratch surface without requiring a permanent terminal
window.

## Clipboard and selection

Clipboard reads and writes are allowed. Selecting text writes to the system
clipboard, and trailing spaces are trimmed.

Paste protection is disabled. This favors uninterrupted terminal workflows but
removes Ghostty's confirmation layer for suspicious multiline pastes. Re-enable
it on machines where untrusted clipboard content is a larger risk.

This supports the same local clipboard that Neovim uses through `pbcopy` and
OSC 52 in remote sessions. Secure-input auto-switching remains disabled so it
does not unexpectedly block that path.

## Shell integration preserves terminal capabilities

The `sudo` integration carries terminal information into elevated commands.
Without it, `sudo vim` can inherit a terminal type whose capabilities are
unknown in the elevated environment.

Cursor and title integration allow the shell to update interaction state while
Ghostty remains the rendering owner.

## Notifications are visible but silent

The bell requests attention and updates the title without playing audio. Long
commands remain noticeable without turning routine terminal events into sound.

## Verification

```bash
ghostty +validate-config
ghostty +show-config
ghostty +show-face --style=bold --string=A
```

The final command confirms which family supplies a bold glyph.

## Related

- [Visual system](visual-system.md)
- [Zsh load and input model](zsh.md)
- [Neovim remote clipboard](neovim.md#why-remote-clipboard-handling-is-custom)
