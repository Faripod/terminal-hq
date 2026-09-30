# iTerm2: the Terminal HQ profile (green, translucent, F12 drop-down from the top of the screen,
# ⌘/⌥ arrows for line and word jumps), the Hack Nerd Font it uses, and the itermshortcut cheatsheet.
# Options (1 = yes): THQ_TRANSPARENCY (0-1), THQ_NO_HOTKEY, THQ_REPLACE_HOTKEY, THQ_DEFAULT_PROFILE,
# THQ_MINIMAL_UI, THQ_FN_KEYS, THQ_LOGIN_ITEM.

DYNAMIC="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
PROFILE="$DYNAMIC/terminal-hq.json"

step "iTerm2"
brew_cask iterm2 font-hack-nerd-font
command -v jq >/dev/null || brew_install jq

# another drop-down on F12 would fight with ours: set it aside (uninstall brings it back)
if [ "$THQ_REPLACE_HOTKEY" = 1 ]; then
  for other in "$DYNAMIC"/*.json; do
    [ -f "$other" ] && [ "$other" != "$PROFILE" ] || continue
    jq -e '[.Profiles[]? | select(."Has Hotkey" == true and ."HotKey Key Code" == 111)] | length > 0' "$other" >/dev/null 2>&1 \
      && backup "$other"
  done
fi

# copied, not linked: iTerm2 writes the changes made in its settings back into this file
if exists "$PROFILE"; then
  say "kept your Terminal HQ profile"
elif dry; then
  say "would add the Terminal HQ profile ($([ "$THQ_NO_HOTKEY" = 1 ] && echo "no hotkey" || echo "F12"))"
else
  mkdir -p "$DYNAMIC"
  cp "$THQ_ROOT/modules/iterm2/terminal-hq.json" "$PROFILE"
  created "$PROFILE"
  say "added the Terminal HQ profile"
fi

patch_profile() {
  if dry; then say "would set $2 in the profile"; return; fi
  if jq "$1" "$PROFILE" > "$PROFILE.tmp"; then mv "$PROFILE.tmp" "$PROFILE"
  else rm -f "$PROFILE.tmp"; fail "could not edit $PROFILE"; fi
  say "profile: $2"
}
[ -n "$THQ_TRANSPARENCY" ] && patch_profile ".Profiles[0].Transparency = $THQ_TRANSPARENCY" "transparency $THQ_TRANSPARENCY"
[ "$THQ_NO_HOTKEY" = 1 ] && patch_profile '.Profiles[0]."Has Hotkey" = false' "no hotkey"

link "$THQ_ROOT/bin/itermshortcut" "$HOME/.local/bin/itermshortcut"

if [ "$THQ_DEFAULT_PROFILE" = 1 ]; then
  # a running iTerm2 accepts the new default only once it has loaded the profile, and resets the default
  # by itself when the old one was a drop-down set aside above: wait for it, then check it held
  plist="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  knows() { plutil -extract "New Bookmarks" json -o - "$plist" 2>/dev/null | grep -q '"terminal-hq-0001"'; }
  if ! dry && [ -f "$plist" ] && iterm_running; then
    for _ in $(seq 1 20); do knows && break; sleep 0.5; done
    sleep 2
  fi
  set_pref com.googlecode.iterm2 "Default Bookmark Guid" string terminal-hq-0001
  if ! dry && [ -f "$plist" ] && iterm_running; then
    sleep 2
    [ "$(defaults read com.googlecode.iterm2 "Default Bookmark Guid")" = terminal-hq-0001 ] \
      || run defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string terminal-hq-0001
  fi
fi
if [ "$THQ_MINIMAL_UI" = 1 ]; then
  set_pref com.googlecode.iterm2 TabStyleWithAutomaticOption int 5
  set_pref com.googlecode.iterm2 HideTab bool true
  set_pref com.googlecode.iterm2 HideScrollbar bool true
  set_pref com.googlecode.iterm2 ShowPaneTitles bool false
  set_pref com.googlecode.iterm2 SplitPaneDimmingAmount float 0.39
fi
# F12 is the volume key on Mac keyboards until F1, F2... act as standard function keys
[ "$THQ_FN_KEYS" = 1 ] && set_pref -g com.apple.keyboard.fnState bool true

if [ "$THQ_LOGIN_ITEM" = 1 ]; then
  # reading the login items can raise a macOS permission prompt: not during a dry run
  if dry; then
    say "would make iTerm2 open at login, unless it already does"
  elif osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q 'iTerm'; then
    say "iTerm2 already opens at login"
  else
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/iTerm.app", hidden:true}' >/dev/null
    mkdir -p "$THQ_STATE"; touch "$THQ_STATE/login-item"
    say "iTerm2 opens at login"
  fi
fi
