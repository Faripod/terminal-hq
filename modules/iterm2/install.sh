# iTerm2: the Terminal HQ profile (green, translucent, F12 drop-down from the top of the screen,
# ⌘/⌥ arrows for line and word jumps), the Hack Nerd Font it uses, and the itermshortcut cheatsheet.
# Options: THQ_TRANSPARENCY (0-1), THQ_DEFAULT_PROFILE, THQ_MINIMAL_UI, THQ_FN_KEYS, THQ_LOGIN_ITEM (1 = yes).

PROFILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/terminal-hq.json"

step "iTerm2"
brew_cask iterm2 font-hack-nerd-font

# copied, not linked: iTerm2 writes the changes made in its settings back into this file
if [ -e "$PROFILE" ]; then
  say "kept your Terminal HQ profile"
elif [ -n "$DRY" ]; then
  say "would copy the Terminal HQ profile to $PROFILE"
else
  mkdir -p "$(dirname "$PROFILE")"
  cp "$THQ_ROOT/modules/iterm2/terminal-hq.json" "$PROFILE"
  say "added the Terminal HQ profile (F12)"
fi

if [ -n "$THQ_TRANSPARENCY" ]; then
  case "$THQ_TRANSPARENCY" in 0|1|0.[0-9]*|1.0) ;; *) fail "transparency goes from 0 (opaque) to 1 (invisible)" ;; esac
  command -v jq >/dev/null || brew_install jq
  if [ -n "$DRY" ]; then say "would set the transparency to $THQ_TRANSPARENCY"
  else
    jq --argjson t "$THQ_TRANSPARENCY" '.Profiles[0].Transparency = $t' "$PROFILE" > "$PROFILE.tmp" && mv "$PROFILE.tmp" "$PROFILE"
    say "transparency $THQ_TRANSPARENCY"
  fi
fi

link "$THQ_ROOT/bin/itermshortcut" "$HOME/.local/bin/itermshortcut"

[ "$THQ_DEFAULT_PROFILE" = 1 ] && set_pref com.googlecode.iterm2 "Default Bookmark Guid" string terminal-hq-0001
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
  if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q 'iTerm'; then
    say "iTerm2 already opens at login"
  else
    run osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/iTerm.app", hidden:true}' >/dev/null
    [ -n "$DRY" ] || { mkdir -p "$THQ_STATE"; touch "$THQ_STATE/login-item"; }
    say "iTerm2 opens at login"
  fi
fi
