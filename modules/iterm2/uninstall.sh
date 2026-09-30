# Removes the Terminal HQ profile (only if terminal-hq added it) and the cheatsheet, brings back any
# drop-down profile set aside by --replace-hotkey and the iTerm2 and keyboard preferences.
# iTerm2 and the font stay installed.

DYNAMIC="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

step "iTerm2"
remove_created "$DYNAMIC/terminal-hq.json"
for saved in "$(backup_path "$DYNAMIC")"/*.json; do
  [ -e "$saved" ] && restore "$DYNAMIC/$(basename "$saved")"
done
restore "$HOME/.local/bin/itermshortcut"
restore_prefs com.googlecode.iterm2
restore_prefs -g
if [ -f "$THQ_STATE/login-item" ]; then
  run osascript -e 'tell application "System Events" to delete login item "iTerm"' >/dev/null 2>&1
  run rm -f "$THQ_STATE/login-item"
  dry || say "iTerm2 no longer opens at login"
fi
