# Global rules — apply in every session

These are cross-project rules. Project AGENTS.md files add specifics
and win on conflict.

## Environment

- macOS. Editor: Zed. Terminal: Ghostty and tmux sessions herdr. Node via npm; Rust via cargo; Java via Maven unless the repo says otherwise.
- Stacks I work in: Java/Spring Boot, TypeScript/Next.js/Tanstack/React, Python (AI/ML/Data), Rust (TUI/ratatui).
- Check the repo's AGENTS.md and lockfiles before assuming a package manager or build tool.

## How to work

- Verify before declaring done: run the narrowest relevant test or build for what you changed. If you cannot run it, say so explicitly — never imply verification that didn't happen.
- Pipe noisy commands through filters; tool output is truncated at ~800 lines from the top, and build failures often sit at the bottom:
  - `mvn test 2>&1 | tail -120`
  - `cargo test 2>&1 | grep -B2 -A8 'error\['`
  - `npm test 2>&1 | tail -120`
- Prefer the smallest diff that solves the problem. No drive-by refactors, no reformatting untouched code, no speculative abstractions.
- If instructions are ambiguous or two requirements conflict, stop and ask one precise question instead of guessing.
- If the same test fails after two fix attempts, stop and summarize what you tried and what you suspect — don't loop.

## Delegation (custom subagents available)

- `explore` / `general` — read-only research and multi-step lookups. Use for "how does X work here" questions before editing.
- `digest` — summarize large files, logs, or unfamiliar modules in a child session instead of reading them into this context.
- `grunt` — mechanical, fully-specified edits across many files (renames, pattern application, scaffolding). Write the complete spec in the delegation prompt; the child sees nothing from this session.
- `reviewer` — pre-commit diff review. Suggest running it before any commit that touches auth, data persistence, or money.
- When delegating, the task prompt is the entire briefing. Include file paths, the exemplar pattern, and acceptance criteria.

## Code conventions

- TypeScript: strict mode assumptions; no `any` without a comment justifying it; functional React components only.
- Java: constructor injection, no field `@Autowired`; nullability annotated at boundaries.
- Rust: no `unwrap()`/`expect()` outside tests and main(); propagate with `?`.
- Comments explain *why*, not *what*. Don't narrate obvious code.

## Formatting (manual until OpenCode V2 runs formatters)

Before finishing, format only the files you modified:
- Rust: `cargo fmt`
- TS/JS: oxfmt <files>, then oxlint <files> and fix what it reports. Do not use prettier or eslint even if configs for them linger in a repo — oxfmt/oxlint are the tools of record unless the project AGENTS.md says otherwise.
- Java: respect the repo's checkstyle/spotless config if present; otherwise leave formatting as found.

## Git

- Never commit or push unless explicitly asked. Staging is fine.
- Commit messages: conventional commits (`feat:`, `fix:`, `refactor:`, `test:`, `chore:`), imperative, under 72 chars, body only when the why isn't obvious.
- Never commit secrets, .env files, or credentials. If you encounter a secret in the working tree, flag it and stop.

## Communication

- Lead with the outcome, then details. No preamble, no restating my request.
- When you made a judgment call I didn't specify, name it in one line so I can override it.
- Concise by default; token budget matters more than thoroughness theater.
