# Why OpenCode uses specialized agents

The OpenCode configuration treats model choice, role boundaries, and tool
permissions as one system. The primary agent owns outcomes. Subagents handle
bounded work where a narrower context or specialty helps.

## One primary implementation owner

The default `build` agent uses the Sol build model with medium reasoning. Its
prompt assigns end-to-end responsibility and allows delegation without
transferring integration ownership.

The `plan` agent is separate because planning and implementation have different
failure modes. It emphasizes architecture, invariants, risk, and acceptance
criteria without turning every implementation task into a design exercise.

## Subagents are divided by job

The workforce is intentionally role-based:

- `explore` traces code without modifying it;
- `general` handles bounded research and analysis;
- `frontier` receives harder delegated engineering work;
- `vision` connects visual evidence to implementation;
- `digest` compresses large inputs into structured context;
- `frontend` is available in primary and delegated contexts for rendered
  product work;
- `reviewer` tries to falsify a proposed change.

These roles reduce prompt ambiguity. They are not an organizational chart for
its own sake. The primary agent should delegate only when the narrower job saves
context or adds independent judgment.

## Expensive judgment and cheap mechanics use different models

The configuration assigns model families according to the work expected from
each role. Build uses Sol, while planning uses Astra. Frontend and adversarial
review use a high-reasoning Grok variant. Research and compression use
DeepSeek.

This division keeps the strongest model focused on integration while allowing
bounded work to run elsewhere. Model identifiers remain explicit so a machine
failure is visible rather than silently falling back.

## Permissions reinforce role boundaries

Global rules ask before commands matching `rm -rf *`, edits under `~/.config`,
or reads of environment files.

The reviewer cannot edit and can run only a small set of Git inspection
commands without asking.

These restrictions match the agent's purpose. A read-only reviewer with broad
write access would be a role in name only.

## Output limits protect the working context

Tool output is capped at 1,000 lines and 32,768 bytes. The global instructions
therefore recommend filtering noisy build output so failures near the end are
not truncated.

Compaction preserves a large recent window while reserving space for continued
work. The goal is not maximum transcript retention. It is keeping recent
decisions and enough room to finish the task.

## Reusable commands encode repeatable jobs

Three commands cover common context transitions:

- `review` requests an independent diff review;
- `brief` compresses a file or directory into a structured map;
- `handoff` records current state for another developer or session.

They package recurring intent, not shell aliases. Each command names the agent
best suited to the job.

## The plugin and MCP surface stays small

Ponytail is the only configured plugin. It reinforces the same preference for
small, direct solutions found in the global instructions.

Playwright is the only MCP server. OpenCode starts it through `npx` when browser
automation is needed. Other integrations are omitted until they have a regular
job in the supported workflow.

## Global instructions are versioned beside the config

`AGENTS.md` defines cross-project expectations for verification, delegation,
language conventions, formatting, Git operations, and communication. Project
instructions can override it.

Keeping this file beside `opencode.jsonc` ties behavior to the agent roster it
describes. Both files are linked into the global OpenCode config directory.

## Credentials remain outside Git

Provider authentication is not embedded in `opencode.jsonc`. The installer also
backs up a conflicting `opencode.json` before linking the JSONC source of truth.

This produces one visible config and one external credential store.

## OpenCode must restart after config changes

OpenCode loads config, agent definitions, and plugins at startup. A running
session does not adopt edits to these files. Restarting is part of applying a
configuration change rather than a troubleshooting step.

## Related

- [Bootstrap config ownership](bootstrap.md#why-opencodes-alternate-config-is-backed-up)
- [Zed agent integration](zed.md#agent-support-is-separate-from-opencode-policy)
- [`opencode/AGENTS.md`](../opencode/AGENTS.md)
