# One visual system across tools

Dotbento treats the terminal and editors as surfaces of one environment. The
goal is not exact pixel identity. The goal is stable visual meaning when moving
between tools.

## Typography has two jobs

Operator Mono Lig renders code and prose. MesloLGS Nerd Font Mono supplies icon
glyphs that Operator Mono does not contain.

Ghostty can fall back per codepoint, so it uses both families. Text resolves to
Operator Mono while prompt and file icons resolve to Meslo. Zed uses Operator
Mono for its editor and embedded terminal. The macOS package path installs
Meslo, while Operator Mono remains optional.

Neovim's semantic italics rely on a font with a real italic face. They still
function without Operator Mono, but the visual distinction may be weaker.

## Why the ScreenSmart cut is excluded

`Operator Mono SSm Lig` includes stronger screen-oriented metrics. At the same
nominal size, its x-height, advance width, and stems are roughly 11 percent
larger or heavier than the selected Lig cut.

That tradeoff was designed for rasterizers with stronger pixel-grid fitting.
Modern macOS uses grayscale antialiasing without the old subpixel stem
snapping. On that display path, the ScreenSmart cut reads softer rather than
clearer.

The standard Lig cut is therefore shared by Ghostty and Zed.

## Italic carries semantic weight

Zed and Neovim use italic text for comments, keywords, types, parameters, and
related semantic-token groups. Upright text remains the default for values and
ordinary identifiers.

This is not a universal syntax-highlighting theory. It is a consistent cue for
the languages used by this setup. Both editors reapply the rule at their own
theme boundary.

## Theme ownership differs by platform

The macOS stack is pinned to a dark Catppuccin surface in Ghostty and Zed.
Starship uses semantic ANSI names, so Ghostty's palette supplies the actual RGB
values.

Neovim follows a different rule:

- Omarchy owns the active desktop theme and exports a Neovim specification.
- macOS falls back to the bundled Aether/Gruvy Glass palette.

This avoids maintaining a second Omarchy theme mapping in Dotbento.

Zed remains pinned to Catppuccin Mocha on Omarchy. It does not follow the
desktop theme, so the Linux profile favors a stable graphical editor over exact
theme parity with Neovim.

## Some colors are indirect, others are explicit

Starship colors are indirect because a terminal palette already provides the
right abstraction. Retheming the terminal updates the prompt automatically.

The fzf palette is explicit hex because fzf does not consume Starship's
semantic palette. That is accepted duplication. It is small, visible, and tied
to the pinned macOS terminal theme.

## Cursor and focus are shared signals

Ghostty and Zed both use a blinking underline cursor. Inactive panes dim rather
than gaining heavier borders or decorations.

Ghostty provides the actual translucent surface. Neovim clears selected
background highlight groups so terminal opacity remains visible. Zed applies
its own inactive-pane opacity because it controls its rendering surface.

## Consistency stops where interaction differs

Ghostty maps macOS Option to Alt so Zsh receives Meta bindings. Zed's embedded
terminal keeps its own `option_as_meta` setting disabled. This is a known
interaction difference, not an accidental theme mismatch.

Visual consistency should not force every application into identical input
behavior when their host environments differ.

## Related

- [Ghostty decisions](ghostty.md)
- [Starship decisions](starship.md)
- [Zsh decisions](zsh.md)
- [Neovim decisions](neovim.md)
- [Zed decisions](zed.md)
