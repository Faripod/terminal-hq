# Takes the terminal-hq line out of ~/.zshrc. Oh My Zsh, Powerlevel10k and the plugins stay:
# the user's own configuration may rely on them.

step "zsh"
remove_line "$HOME/.zshrc"
# an empty .zshrc that terminal-hq itself created goes too
[ -s "$HOME/.zshrc" ] || remove_created "$HOME/.zshrc"
