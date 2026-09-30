# terminal-hq for zsh: Oh My Zsh with the green Powerlevel10k prompt, plugins, colors and aliases.
# ~/.zshrc loads it with one line; whatever comes after that line in your .zshrc wins.

THQ_ROOT=${${(%):-%x}:A:h:h:h}
export ZSH=${ZSH:-$HOME/.oh-my-zsh}
# itermshortcut and other personal commands live here
(( ${path[(I)$HOME/.local/bin]} )) || path=($HOME/.local/bin $path)

# when your .zshrc already loaded Oh My Zsh, its theme and plugins stay
if (( ! ${+functions[omz]} )) && [[ -f $ZSH/oh-my-zsh.sh ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
  zstyle ':omz:update' mode auto
  zstyle ':omz:update' frequency 7
  plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions
           sudo web-search copypath copyfile history jsontools macos)
  fpath+=${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src
  source $ZSH/oh-my-zsh.sh
fi

# ─── History ────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# ─── Aliases ────────────────────────────────────────────────────
if (( $+commands[eza] )); then
  alias ls='eza --icons --color=always'
  alias ll='eza -lah --icons --color=always --git'
  alias la='eza -a --icons --color=always'
  alias l='eza -l --icons --color=always'
  alias lt='eza --tree --level=2 --icons --color=always'
fi
alias cls='clear'
alias reload='source ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias brewup='brew update && brew upgrade && brew cleanup'
alias path='echo -e ${PATH//:/\\n}'
alias h='history | tail -50'
alias sizeof='du -sh'
alias psg='ps aux | grep -v grep | grep -i'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gpom='git pull origin main'

if (( $+commands[bat] )); then
  alias cat='bat --theme=DarkNeon --style=plain'
  alias catn='bat --theme=DarkNeon'
  export BAT_THEME="DarkNeon"
fi
(( $+commands[btop] ))     && alias top='btop'
(( $+commands[lazygit] ))  && alias lg='lazygit'
(( $+commands[cmatrix] ))  && alias matrix='cmatrix -b -C green'
(( $+commands[pipes.sh] )) && alias pipes='pipes.sh -t 0 -p 5 -R -r 0'

# ─── Green syntax highlighting and suggestions ─────────────────
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=green,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=green'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=green'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=green,bold'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=22'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ─── fzf in green ───────────────────────────────────────────────
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS='
    --color=fg:#00ff00,bg:#000000,hl:#00cc00
    --color=fg+:#00ff00,bg+:#003300,hl+:#00ff00
    --color=info:#00aa00,prompt:#00ff00,pointer:#00ff00
    --color=marker:#00ff00,spinner:#00aa00,header:#00cc00
    --height=60% --layout=reverse --border=sharp'
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
fi

(( $+commands[thefuck] )) && eval "$(thefuck --alias)"

# ─── Prompt and banner ─────────────────────────────────────────
# your own ~/.p10k.zsh wins over the green one, and `p10k configure` writes there, not into terminal-hq
if [[ -f ~/.p10k.zsh ]]; then source ~/.p10k.zsh; else source "$THQ_ROOT/modules/zsh/p10k.zsh"; fi
typeset -g POWERLEVEL9K_CONFIG_FILE=$HOME/.p10k.zsh
# THQ_BANNER=off before the terminal-hq line hides it
[[ -o interactive && ${THQ_BANNER:-on} == on ]] && (( $+commands[fastfetch] )) && fastfetch
