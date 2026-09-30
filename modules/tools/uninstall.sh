# Removes the tool themes and configurations; the tools themselves stay installed
# (`brew uninstall <name>` removes one).

step "tools"
restore "$HOME/.config/btop/themes/hacker.theme"
restore "$HOME/.config/fastfetch/config.jsonc"
if [ -f "$HOME/.config/btop/btop.conf" ] && grep -q '^color_theme = "hacker"' "$HOME/.config/btop/btop.conf"; then
  run rm -f "$HOME/.config/btop/btop.conf"
  say "removed the btop settings (btop recreates its defaults)"
fi
