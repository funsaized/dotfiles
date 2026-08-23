#!/usr/bin/env bash
#
#  dotfiles installer
#
#  Symlinks configs from this repo into place. Symlinks (not copies) so that
#  editing ~/.zshrc edits the repo and `git diff` shows your drift.
#
#    ./install.sh            symlink everything, backing up what's there
#    ./install.sh --dry-run  print what would happen, touch nothing
#    ./install.sh --brew     also install the CLI tools these configs assume
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
BREW=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --brew)    BREW=1 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

# link <source-relative-to-repo> <destination-absolute>
link() {
  local src="$REPO/$1" dst="$2"

  if [[ ! -e $src ]]; then
    warn "missing in repo, skipped: $1"
    return
  fi

  # Already pointing where we want? Nothing to do.
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    ok "already linked: $dst"
    return
  fi

  if (( DRY )); then
    [[ -e $dst ]] && echo "  would back up $dst -> $dst.bak-$STAMP"
    echo "  would link    $dst -> $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  # Never clobber. Real files get moved aside with a timestamp; stale symlinks
  # are just removed (there's nothing to preserve).
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak-$STAMP"
    warn "backed up existing $dst -> $(basename "$dst").bak-$STAMP"
  fi

  ln -s "$src" "$dst"
  ok "linked $dst"
}

bold "dotfiles -> \$HOME    ${DRY:+(dry run)}"
echo

bold "Shell & prompt"
link zsh/.zshrc              "$HOME/.zshrc"
link starship/starship.toml  "$HOME/.config/starship.toml"
link git/.gitconfig          "$HOME/.gitconfig"
echo

bold "Terminal"
link ghostty/config          "$HOME/.config/ghostty/config"
# On macOS Ghostty ALSO reads this path and merges it with the one above.
# Leaving a real config there is how you end up with settings that silently
# override the repo. Point it at nothing.
GHOSTTY_APPSUPPORT="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [[ -e $GHOSTTY_APPSUPPORT && ! -L $GHOSTTY_APPSUPPORT ]]; then
  if (( DRY )); then
    echo "  would neutralize $GHOSTTY_APPSUPPORT"
  else
    mv "$GHOSTTY_APPSUPPORT" "$GHOSTTY_APPSUPPORT.bak-$STAMP"
    printf '# Intentionally empty. Real config: ~/.config/ghostty/config\n' > "$GHOSTTY_APPSUPPORT"
    warn "neutralized the Application Support config (it merges with ours)"
  fi
fi
echo

# Editor settings are COPIED, not symlinked, and that asymmetry is deliberate.
# These two files contain API-key fields. Symlinking them would (a) overwrite
# your real keys with the repo's "YOUR KEY HERE" placeholders, and (b) put your
# real keys into `git status` the moment you filled them in — which is exactly
# how credentials end up in a public repo. Copy once, then diverge safely.
copy_editor() {
  local src="$REPO/$1" dst="$2"
  [[ -e $src ]] || { warn "missing in repo, skipped: $1"; return; }
  if (( DRY )); then
    [[ -e $dst ]] && echo "  would back up $dst -> $dst.bak-$STAMP"
    echo "  would COPY    $dst (not symlinked — contains key fields)"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  [[ -e $dst ]] && cp "$dst" "$dst.bak-$STAMP" && warn "backed up $(basename "$dst")"
  cp "$src" "$dst"
  ok "copied $dst  (re-add your API keys)"
}

bold "Editors"
copy_editor zed/settings.json    "$HOME/.config/zed/settings.json"
copy_editor vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
echo

bold "Claude Code skills"
if (( DRY )); then
  echo "  would copy claude/skills/* -> ~/.claude/skills/"
else
  mkdir -p "$HOME/.claude/skills"
  cp -R "$REPO/claude/skills/." "$HOME/.claude/skills/"
  ok "copied skills to ~/.claude/skills/"
fi
echo

bold "OpenCode"
link opencode/opencode.jsonc "$HOME/.config/opencode/opencode.jsonc"
link opencode/AGENTS.md      "$HOME/.config/opencode/AGENTS.md"
echo

if (( BREW )); then
  bold "CLI tools"
  if ! command -v brew >/dev/null; then
    warn "Homebrew not found — https://brew.sh"
  else
    # What the configs actually reference. Missing any of these degrades
    # gracefully except eza/fd, which the aliases and fzf commands need.
    PKGS=(starship eza bat fd ripgrep fzf zoxide git-delta lazygit direnv jq)
    if (( DRY )); then
      echo "  would: brew install ${PKGS[*]}"
    else
      brew install "${PKGS[@]}"
      ok "installed: ${PKGS[*]}"
    fi
  fi
  echo
fi

bold "Next steps"
cat <<'EOF'
  1. Fonts are NOT installed by this script. These configs expect:
       - MesloLGS Nerd Font  (required — icons/glyphs)
           brew install --cask font-meslo-lg-nerd-font
       - Operator Mono Lig   (optional, commercial — falls back to Meslo)
  2. Put your identity back in git:
       git config --global user.name  "Your Name"
       git config --global user.email "you@example.com"
  3. Add your API keys to ~/.config/zed/settings.json (search "YOUR KEY HERE").
  4. Restart your shell:  exec zsh
EOF
