# Removes the tool themes and configurations; the tools themselves stay installed
# (`brew uninstall <name>` removes one).

step "tools"
restore "$HOME/.config/btop/themes/hacker.theme"
restore "$HOME/.config/fastfetch/config.jsonc"
remove_created "$HOME/.config/btop/btop.conf"
