# Why the prompt declares exactly what it renders

Starship permits detailed configuration for modules that never appear. Dotbento
uses an explicit format as both layout and allowlist.

This file belongs to the macOS profile. Omarchy keeps its own Starship defaults.

## The format string is the source of truth

Every configured module must appear in `format` or `right_format`. A module
block without a corresponding variable is dead configuration, and Starship does
not warn about it.

The prompt has two lines:

1. identity, location, Git state, language runtimes, containers, and direnv;
2. jobs, duration, exit status, and the prompt character.

Time appears on the right. This arrangement keeps project context together and
execution feedback close to the next command.

## ANSI names let Ghostty own color

The palette uses names such as `cyan`, `purple`, and `red`, not hex values.
Ghostty resolves those names through the active terminal theme.

This is the right layer of indirection. Starship describes semantic roles while
the terminal owns display colors. Changing the terminal palette does not require
rewriting the prompt.

The palette table gives those roles names such as `dir`, `vcs`, `runtime`, and
`warn`. Module blocks refer to roles rather than raw terminal colors.

## Runtime detection should be useful, not exhaustive

The prompt displays Node.js, Java, Python, Rust, Go, Docker, and direnv state.
These match the supported development workload.

Ten previously tuned modules were removed because they did not appear in the
format. Reintroducing a technology requires both a module block and a deliberate
position in the prompt.

## Java needs a longer command timeout

Starship obtains Java's version by executing `java -version`. Under SDKMAN, a
cold invocation can exceed the default 500 ms timeout and disappear from the
prompt without an error.

Dotbento raises Starship's global command timeout to 1,000 ms. The setting also
applies to other command-backed modules, but Java is the measured reason for the
change.

## direnv state is operational information

The shell already evaluates direnv. Showing its state in the prompt makes a
blocked or unloaded `.envrc` visible at the point where missing environment
variables become confusing.

This module is not decorative. It closes the feedback loop created by the Zsh
hook.

## Module cost is not prompt cost

`git_metrics` measured as an expensive individual module, around 14 ms in the
recorded repository. Removing it did not improve the complete prompt: measured
totals were 45.3 ms with it and 46.5 ms without it.

Starship evaluates modules in parallel. Optimizing one branch does not reduce
wall-clock latency when another branch or process startup remains dominant.

The module stays absent for signal-to-noise, not for a false performance claim.

## Personal path substitutions are intentionally opinionated

Directory substitutions compress common development roots into recognizable
symbols. They make a two-line prompt more stable in deeply nested repositories.

These mappings are one of the few parts expected to change for another owner.
They should remain explicit rather than hidden behind host detection.

## Verification

```bash
starship explain
starship timings
STARSHIP_CONFIG="$PWD/starship/starship.toml" starship prompt
```

`explain` shows what rendered. `timings` measures module cost. The final command
checks the repository config without installing it.

## Related

- [Ghostty theme ownership](ghostty.md#the-terminal-is-pinned-dark)
- [Zsh direnv and prompt hooks](zsh.md#hooks-initialize-after-path)
- [Visual system](visual-system.md)
