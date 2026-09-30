# Command-line tools and their green themes: eza, bat, fzf, fd, ripgrep, btop, lazygit, thefuck,
# fastfetch (the banner), cmatrix and pipes.sh (the toys).

step "tools"
brew_install eza bat fzf fd ripgrep btop lazygit thefuck fastfetch cmatrix pipes-sh tree jq
link "$THQ_ROOT/modules/tools/btop/hacker.theme" "$HOME/.config/btop/themes/hacker.theme"
# btop rewrites its settings on exit, so it gets a copy
copy_if_absent "$THQ_ROOT/modules/tools/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link "$THQ_ROOT/modules/tools/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
