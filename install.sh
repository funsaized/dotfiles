#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)-$$"
DRY=0
PACKAGES=0
YES=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--packages] [--yes]

  --dry-run   Show changes without applying them
  --packages  Also install supported development tools
  --yes       Approve changes without an interactive prompt
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --packages) PACKAGES=1 ;;
    --yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown flag: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  Darwin) PLATFORM=macos ;;
  Linux)
    command -v omarchy >/dev/null || {
      echo "Dotbento supports Omarchy Linux, not generic Linux." >&2
      exit 1
    }
    PLATFORM=omarchy
    ;;
  *) echo "Dotbento supports macOS and Omarchy Linux only." >&2; exit 1 ;;
esac

command -v git >/dev/null || { echo "Git is required to install shared Git settings." >&2; exit 1; }

if (( PACKAGES )) && [[ $PLATFORM == macos ]] && ! command -v brew >/dev/null; then
  echo "Homebrew is required: https://brew.sh" >&2
  exit 1
fi

printf 'Dotbento plan for %s (%s): Zed, Neovim, OpenCode, Git' "$PLATFORM" "$CONFIG_HOME"
[[ $PLATFORM == macos ]] && printf ', Zsh, Starship, Ghostty'
(( PACKAGES )) && printf '; install requested packages'
printf '\nExisting files will be backed up before replacement.\n'

if (( ! DRY && ! YES )); then
  printf 'Apply Dotbento config for %s%s? [y/N] ' "$PLATFORM" "$([[ $PACKAGES == 1 ]] && printf ' and install packages')"
  read -r answer
  [[ $answer == [Yy] || $answer == [Yy][Ee][Ss] ]] || { echo "Cancelled."; exit 0; }
fi

ok() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

backup() {
  local dst=$1
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak-$STAMP"
    warn "backed up $dst"
  fi
}

link() {
  local src="$REPO/$1" dst="$2"
  [[ -e $src ]] || { warn "missing in repo, skipped: $1"; return; }
  if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
    ok "already linked: $dst"
  elif (( DRY )); then
    [[ -e $dst || -L $dst ]] && printf '  would back up %s\n' "$dst"
    printf '  would link %s -> %s\n' "$dst" "$src"
  else
    mkdir -p "$(dirname "$dst")"
    backup "$dst"
    ln -s "$src" "$dst"
    ok "linked $dst"
  fi
}

copy_tree() {
  local src="$REPO/$1" dst="$2"
  if [[ -d $dst && ! -L $dst ]] && diff -qr "$src" "$dst" >/dev/null; then
    ok "already current: $dst"
  elif (( DRY )); then
    [[ -e $dst || -L $dst ]] && printf '  would back up %s\n' "$dst"
    printf '  would copy %s -> %s\n' "$src" "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    backup "$dst"
    cp -a "$src" "$dst"
    ok "copied $dst"
  fi
}

install_git() {
  local xdg="$CONFIG_HOME/git/config" include="$REPO/git/.gitconfig" old="$HOME/.gitconfig" dst

  detach_git_config() {
    local file=$1 strip_shared=$2
    local tmp="$file.dotbento-migrate"
    if (( DRY )); then
      printf '  would convert %s symlink to a real file\n' "$file"
      return
    fi

    if [[ -e $file ]]; then
      cp -L "$file" "$tmp"
    else
      : > "$tmp"
    fi
    if (( strip_shared )); then
      local section
      for section in merge diff push pull fetch rebase init column branch rerere alias; do
        git config --file "$tmp" --remove-section "$section" 2>/dev/null || true
      done
    fi
    rm "$file"
    mv "$tmp" "$file"
    ok "converted $file symlink to a real file"
  }

  if [[ -L $old && "$(readlink "$old")" == "$include" ]]; then
    detach_git_config "$old" 1
  fi

  [[ -e $old || -L $old ]] && dst=$old || dst=$xdg

  if [[ -L $dst ]]; then
    [[ "$(readlink "$dst")" == "$include" ]] && detach_git_config "$dst" 1 || detach_git_config "$dst" 0
  fi

  if [[ -f $dst ]] && git config --file "$dst" --get-all include.path 2>/dev/null | grep -Fxq "$include"; then
    ok "already included: $include"
  elif (( DRY )); then
    printf '  would add %s to %s\n' "$include" "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    [[ -e $dst ]] && cp -L "$dst" "$dst.bak-$STAMP"
    git config --file "$dst" --add include.path "$include"
    ok "included shared Git settings from $dst"
  fi
}

install_git
link zed/settings.json "$CONFIG_HOME/zed/settings.json"
opencode_json="$CONFIG_HOME/opencode/opencode.json"
if [[ -e $opencode_json || -L $opencode_json ]]; then
  if (( DRY )); then
    printf '  would back up conflicting %s\n' "$opencode_json"
  else
    mv "$opencode_json" "$opencode_json.bak-$STAMP"
    warn "backed up conflicting $opencode_json"
  fi
fi
link opencode/opencode.jsonc "$CONFIG_HOME/opencode/opencode.jsonc"
link opencode/AGENTS.md "$CONFIG_HOME/opencode/AGENTS.md"

if [[ $PLATFORM == macos ]]; then
  link zsh/.zshrc "$HOME/.zshrc"
  link starship/starship.toml "$CONFIG_HOME/starship.toml"
  link ghostty/config "$CONFIG_HOME/ghostty/config"

  ghostty_app="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ -e $ghostty_app && ! -L $ghostty_app ]]; then
    if (( DRY )); then
      printf '  would neutralize %s\n' "$ghostty_app"
    else
      mv "$ghostty_app" "$ghostty_app.bak-$STAMP"
      printf '# Real config: %s/ghostty/config\n' "$CONFIG_HOME" > "$ghostty_app"
      warn "neutralized Ghostty's secondary config"
    fi
  fi

  link nvim "$CONFIG_HOME/nvim"
else
  copy_tree nvim "$CONFIG_HOME/nvim"
fi

if (( PACKAGES )); then
  if [[ $PLATFORM == macos ]]; then
    formulas=(starship eza bat fd ripgrep fzf zoxide lazygit direnv jq neovim lua-language-server stylua shfmt zsh-autosuggestions zsh-syntax-highlighting opencode)
    casks=(ghostty zed font-meslo-lg-nerd-font)
    if (( DRY )); then
      printf '  would run: brew install %s\n' "${formulas[*]}"
      printf '  would run: brew install --cask %s\n' "${casks[*]}"
    else
      brew install "${formulas[@]}"
      brew install --cask "${casks[@]}"
    fi
  else
    packages=(neovim lua-language-server stylua shfmt zed opencode)
    if (( DRY )); then
      printf '  would run: omarchy pkg add %s\n' "${packages[*]}"
    else
      omarchy pkg add "${packages[@]}"
    fi
  fi
fi

echo "Done. Restart OpenCode after configuration changes."
