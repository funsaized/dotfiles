# Why Zed is configured as the graphical editor

Zed is the graphical counterpart to Neovim. It shares the visual language but
keeps editor-specific behavior where that produces a better workflow.

## The settings file is safe to link

The tracked settings contain no API tokens. Context servers that require keys
are not configured in this repository.

This allows `settings.json` to remain symlinked on both platforms. Changes are
visible to Git immediately, while credentials stay in tool-specific storage or
machine-local configuration.

## Formatting has one owner per language

Prettier is disabled globally. JavaScript, JSX, TypeScript, TSX, JSON, and JSONC
use oxfmt. The four JavaScript and TypeScript scopes also run safe oxlint fixes.

Biome and ESLint language servers are disabled for the JavaScript and TypeScript
scopes. JSON and JSONC disable Biome. Running multiple formatters or fix
providers produces duplicated diagnostics and competing edits. The
configuration chooses one path instead.

CSS, SCSS, HTML, and Markdown delegate to their language server. Dotbento does
not install another formatter solely to cover those file types.

Format-on-save remains enabled in Zed. This differs from Neovim's explicit
format command. Zed is used as the opinionated project editor, while Neovim is
also used to inspect unfamiliar trees from the terminal.

## Java follows the machine

The jdtls configuration controls source downloads and decompiled-source
behavior, but does not name a JDK path.

Hardcoded Homebrew cellar versions and user-specific SDKMAN paths fail as soon
as a JDK updates or the config moves to another platform. Zed instead discovers
Java through the environment it launches with.

The shell remains responsible for selecting a JDK through Homebrew, SDKMAN, or
project-local tooling.

## Theme and typography mirror the terminal

The dark theme is Catppuccin Mocha, matching the managed Ghostty profile on
macOS. Zed keeps this theme on Omarchy even when Neovim follows the desktop
theme. The editor and embedded terminal use Operator Mono Lig at size 16.
Syntax overrides apply italic to the same broad semantic categories used by
Neovim.

The UI font remains Zed's own sans-serif face. Matching code typography matters
more than forcing one font into every piece of application chrome.

## Interaction settings reduce persistent noise

Inlay hints are disabled until requested. Inactive panes dim. Autosave occurs on
focus change. Search uses smart case. Wrap guides expose common 80, 100, and 120
column conventions without enforcing one globally.

Inline blame waits before appearing and starts at a minimum column. This keeps
Git context available without placing it beside every short line immediately.

## The embedded terminal is not Ghostty

Zed's terminal follows the system shell and starts in the current project. It
shares the font, size, underline cursor, and blinking behavior used by Ghostty.

It does not inherit every Ghostty keyboard decision. In particular,
`option_as_meta` remains disabled. Dotbento accepts that boundary rather than
pretending embedded and standalone terminals are identical.

## Agent support is separate from OpenCode policy

Zed registers several agent servers, including OpenCode. Its editor-facing
model and inline-assistant choices optimize for two different latency profiles.

The global OpenCode roles, permissions, and instructions still live under
`opencode/`. Registering an agent server in Zed does not duplicate that policy.

## Portability limits

Operator Mono is commercial and may be absent. Zed needs a local font override
on machines without it. SSH connection definitions and MCP credentials are also
machine-local by design.

## Verification

Use **Zed: Open Default Settings** to compare tracked values against the version
installed on the machine. Confirm that oxfmt and oxlint are active in a project
that provides them.

## Related

- [Visual system](visual-system.md)
- [OpenCode agent design](opencode.md)
- [Neovim formatting tradeoff](neovim.md#formatting-remains-an-explicit-action)
