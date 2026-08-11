#  ═══════════════════════════════════════════════════════════════════════════
#  ~/.zshrc
#  ═══════════════════════════════════════════════════════════════════════════
#
#  Load order matters and is enforced by the section order below:
#
#    1. PATH & environment    — nothing depends on it yet
#    2. Tool initialization   — hooks/widgets that need the final PATH
#    3. Aliases
#    4. Integrations
#    5. zsh plugins           — MUST be last (see the note in that section)
#
#  ═══════════════════════════════════════════════════════════════════════════


# ── 1. PATH & environment ──────────────────────────────────────────────────

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# uv / local binaries
. "$HOME/.local/bin/env"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# JBang
export PATH="$HOME/.jbang/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

export BAT_THEME="Catppuccin Mocha"

# Must be set BEFORE section 3 — the edit* aliases are defined with double
# quotes, so $EDITOR is expanded at definition time, not at call time.
export EDITOR="${EDITOR:-vim}"

# SDKMAN — must come after the other PATH exports so its shims win for
# java/gradle/maven. (Its own installer insists on "end of file"; what it
# actually needs is to be last among PATH mutations, which it now is.)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"


# ── 2. Tool initialization ─────────────────────────────────────────────────

# Prompt
eval "$(starship init zsh)"

# direnv — per-directory env vars. The starship [direnv] module surfaces
# whether the current .envrc is loaded or blocked.
eval "$(direnv hook zsh)"

# zoxide — frecency-ranked `cd`. Learns the dirs you actually use.
#   z dash        jump to the best match for "dash" from anywhere
#   zi            interactive picker (uses fzf)
#   z -           previous directory
eval "$(zoxide init zsh)"

# fzf — Ctrl-R fuzzy history, Ctrl-T file picker, Alt-C directory jump.
# Native integration (fzf >= 0.48); replaces the old key-bindings.zsh sourcing.
source <(fzf --zsh)

# fd powers the pickers so they respect .gitignore and skip .git/ — much
# faster and far less noise than the default `find`.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Catppuccin Mocha palette for fzf, so the picker matches Ghostty and Zed.
export FZF_DEFAULT_OPTS=" \
--height 60% --layout=reverse --border=rounded --info=inline \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a"

# Preview file contents with syntax highlighting in the Ctrl-T picker.
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
# Preview directory contents in the Alt-C picker.
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {}'"


# ── 3. Aliases ─────────────────────────────────────────────────────────────

# eza — modern ls
alias ls="eza --icons"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias lt="eza --tree --level=2 --icons --git-ignore"

# bat — cat with syntax highlighting.
# Deliberately NOT aliased over `cat`: shadowing a coreutil is the kind of
# thing that bites you inside a one-off pipeline at 2am. Type `b` instead.
alias b="bat --paging=never"

# git
alias gs="git status --short --branch"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gd="git diff"               # routed through delta, see ~/.gitconfig
alias gl="git log --oneline --graph --decorate -20"
alias lg="lazygit"

# Config editing
alias editstarship="$EDITOR ~/.config/starship.toml"
alias editghost="$EDITOR ~/.config/ghostty/config"
alias editzsh="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc"

# Navigation
alias dev="cd ~/Documents/programming/snimmagadda1"
alias docs="cd ~/Documents"


# ── 4. Integrations ────────────────────────────────────────────────────────

# >>> arbord begin <<<
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_LOGS_EXPORTER=otlp
export OTEL_METRICS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317
# <<< arbord end >>>

# Logi build haptics
[ -f ~/.config/logi-build-haptics/integration.zsh ] && \
    source ~/.config/logi-build-haptics/integration.zsh

# OpenClaw completion (disabled)
# source "$HOME/.openclaw/completions/openclaw.zsh"


# ── 5. zsh plugins — KEEP LAST ─────────────────────────────────────────────
#
# zsh-syntax-highlighting wraps every ZLE widget that exists at the moment it
# is sourced. Anything that defines widgets afterwards (fzf, zoxide, direnv)
# ends up unhighlighted or, worse, breaks the highlighting entirely. Its own
# README is explicit: source it last.
#
# Previously this sat mid-file with fzf/zoxide loading after it.

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
