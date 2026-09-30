# zsh: Oh My Zsh, Powerlevel10k and the plugins, then one line in ~/.zshrc that loads terminal-hq.zsh.
# The rest of the user's .zshrc is left alone.

ZSH_DIR=${ZSH:-$HOME/.oh-my-zsh}
CUSTOM=${ZSH_CUSTOM:-$ZSH_DIR/custom}

step "zsh"
brew_cask font-hack-nerd-font

if [ -f "$ZSH_DIR/oh-my-zsh.sh" ]; then
  say "Oh My Zsh already installed"
elif dry; then
  say "would install Oh My Zsh (your .zshrc is kept)"
else
  # without a .zshrc the Oh My Zsh installer writes its own, whose theme and plugins would win over ours
  [ -e "$HOME/.zshrc" ] || { touch "$HOME/.zshrc"; created "$HOME/.zshrc"; }
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || fail "Oh My Zsh did not install"
fi

clone() {
  if [ -d "$2" ]; then say "already there: ${2#"$HOME"/}"; else run git clone --quiet --depth=1 "$1" "$2"; fi
}
clone https://github.com/romkatv/powerlevel10k.git            "$CUSTOM/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git     "$CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/zsh-users/zsh-completions.git         "$CUSTOM/plugins/zsh-completions"

# a copy of the .zshrc as it was, for reference: uninstall only takes our line out
orig="$(backup_path "$HOME/.zshrc").orig"
if [ -s "$HOME/.zshrc" ] && [ ! -e "$orig" ]; then
  if dry; then say "would keep a copy of ~/.zshrc as it is now in $(dirname "$orig")"
  else mkdir -p "$(dirname "$orig")"; cp "$HOME/.zshrc" "$orig"; fi
fi
add_line "$HOME/.zshrc" "source \"$THQ_ROOT/modules/zsh/terminal-hq.zsh\""
