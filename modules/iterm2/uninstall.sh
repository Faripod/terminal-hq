# Removes the Terminal HQ profile and cheatsheet and puts back the iTerm2 and keyboard preferences.
# iTerm2 and the font stay installed.

step "iTerm2"
PROFILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/terminal-hq.json"
[ -e "$PROFILE" ] && { run rm -f "$PROFILE"; say "removed the Terminal HQ profile"; }
restore "$HOME/.local/bin/itermshortcut"
restore_prefs com.googlecode.iterm2
restore_prefs -g
if [ -f "$THQ_STATE/login-item" ]; then
  run osascript -e 'tell application "System Events" to delete login item "iTerm"' >/dev/null 2>&1
  run rm -f "$THQ_STATE/login-item"
  say "iTerm2 no longer opens at login"
fi
