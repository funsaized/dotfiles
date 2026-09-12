# Why Git settings are included rather than installed wholesale

Git configuration mixes portable behavior with personal identity and
credentials. Dotbento owns the first category and preserves the second.

## Shared config is an include

The installer finds the global config Git already uses:

- `~/.gitconfig` when it exists;
- otherwise `$XDG_CONFIG_HOME/git/config`.

It adds `git/.gitconfig` through `include.path`. It does not replace the global
file.

This boundary allows Dotbento to version merge, diff, push, pull, rebase, and
alias behavior without tracking a name, email, or credential helper.

## Existing symlinks are migrated

An older setup linked the complete global Git config into the repository. That
made `git config --global` write personal values into a tracked file.

Dotbento converts such a symlink into a real file. Shared sections are removed
from the detached copy before the repository include is added. Personal sections
remain local.

Other config symlinks are also detached before editing. This prevents the
installer from writing through an unknown link target.

The include operation is idempotent. Repeated runs do not add duplicate paths.

## Conflict context favors understanding

`merge.conflictstyle = zdiff3` includes the common ancestor beside both sides of
a conflict. The extra context distinguishes what each branch changed from what
both inherited.

This is more useful than a smaller conflict marker when resolving nontrivial
merges.

## Diffs favor meaningful boundaries

The histogram algorithm tends to choose better hunk boundaries around repeated
or structural lines. Moved-line coloring separates relocation from rewriting.
Copy detection is enabled alongside rename detection.

No external pager is required. Shared Git behavior must remain functional even
when optional visual tools are absent.

## Branch and remote defaults remove ceremony

New repositories use `main`. Branches sort by most recent commit. A first push
can establish its upstream automatically, and the current branch is the default
push target.

Fetching prunes deleted remote references. These choices reduce stale state and
repeated flags without inventing a wrapper command.

## Rebase settings preserve unfinished work

Pulls rebase by default. Rebase automatically stashes worktree changes and
honors autosquash markers.

This favors a linear local history while still protecting in-progress changes.
It does not force rebase behavior inside repositories that override the global
setting.

## Reuse conflict resolutions

`rerere` records successful conflict resolutions and updates the index when it
can replay them. This matters during repeated rebases and long-running branch
work.

The feature is global because its value compounds over time. The recorded data
remains in each repository, not in Dotbento.

## Aliases remain close to Git

Portable aliases such as `last`, `unstage`, and `amend` live in Git config so
they work from any shell. The macOS Zsh file adds shorter aliases for its
interactive workflow.

`git churn` is a Git alias that runs a shell pipeline to rank frequently changed
files. It is a heuristic for locating maintenance hotspots, not a measure of
code quality.

## Related

- [Bootstrap safety model](bootstrap.md#backups-are-part-of-installation)
- [Zsh interactive aliases](zsh.md#aliases-should-save-typing-without-changing-shell-semantics)
