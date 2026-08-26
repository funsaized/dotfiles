#  ═══════════════════════════════════════════════════════════════════════════
#  Shell syntactic sugar — sourced from ~/.bashrc after Omarchy defaults.
#  ═══════════════════════════════════════════════════════════════════════════
#
#  Omarchy already ships eza/zoxide/fzf/starship. This file adds the extras
#  from zsh/.zshrc that Omarchy does not define, and does not shadow Omarchy
#  aliases (ls, g, gcm, cd).

# ── Environment ────────────────────────────────────────────────────────────

export BAT_THEME="${BAT_THEME:-Catppuccin Mocha}"
export EDITOR="${EDITOR:-nvim}"

# ── fzf pickers ────────────────────────────────────────────────────────────
# fd so pickers respect .gitignore; bat/eza for previews.
# Only set if the user has not already customized them.

if command -v fd >/dev/null && command -v fzf >/dev/null; then
  : "${FZF_DEFAULT_COMMAND:=fd --type f --hidden --follow --exclude .git}"
  : "${FZF_CTRL_T_COMMAND:=$FZF_DEFAULT_COMMAND}"
  : "${FZF_ALT_C_COMMAND:=fd --type d --hidden --follow --exclude .git}"
  export FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND
fi

if [[ -z ${FZF_DEFAULT_OPTS-} ]]; then
  export FZF_DEFAULT_OPTS=" \
--height 60% --layout=reverse --border=rounded --info=inline \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a"
fi

if command -v bat >/dev/null; then
  : "${FZF_CTRL_T_OPTS:=--preview 'bat -n --color=always --line-range :500 {}'}"
  export FZF_CTRL_T_OPTS
fi

if command -v eza >/dev/null; then
  : "${FZF_ALT_C_OPTS:=--preview 'eza --tree --level=2 --icons --color=always {}'}"
  export FZF_ALT_C_OPTS
fi

# ── Aliases ────────────────────────────────────────────────────────────────

# eza extras (Omarchy already owns `ls` / `lsa` / `lt`)
if command -v eza >/dev/null; then
  alias ll='eza -l --icons --git'
  alias la='eza -la --icons --git'
fi

# bat — do not shadow `cat`
if command -v bat >/dev/null; then
  alias b='bat --paging=never'
fi

# git extras (Omarchy already owns `g` / `gcm` / `gcam` / `gcad`)
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
if command -v lazygit >/dev/null; then
  alias lg='lazygit'
fi

# Config editing — $EDITOR is expanded at definition time on purpose
alias editstarship="$EDITOR ~/.config/starship.toml"
alias editghost="$EDITOR ~/.config/ghostty/config"
alias editbash="$EDITOR ~/.bashrc"
alias editzed="$EDITOR ~/.config/zed/settings.json"
alias reload='source ~/.bashrc'

# Navigation
alias docs='cd ~/Documents'
alias work='cd ~/Work'
