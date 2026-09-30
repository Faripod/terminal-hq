#!/usr/bin/env bash
# Installs and uninstalls terminal-hq in throwaway HOMEs, with brew, git, curl, defaults and osascript
# replaced by stubs that only record what they are asked. Nothing on the machine changes.

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/terminal-hq-tests.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
pass=0 fail=0

check() {
  if [ "$2" = "$3" ]; then pass=$((pass + 1)); echo "ok    $1"
  else fail=$((fail + 1)); echo "FAIL  $1"; echo "      expected: $3"; echo "      got:      $2"; fi
}

# ─── stubs ─────────────────────────────────────────────────────
stubs="$tmp/stubs"; mkdir -p "$stubs"
export STUB_LOG="$tmp/calls.log" STUB_DB="$tmp/defaults.db"
cat > "$stubs/brew" <<'EOF'
#!/usr/bin/env bash
echo "brew $*" >> "$STUB_LOG"
case "$1" in list) exit 1 ;; esac
EOF
cat > "$stubs/git" <<'EOF'
#!/usr/bin/env bash
echo "git $*" >> "$STUB_LOG"
[ "$1" = clone ] && mkdir -p "${@: -1}"
EOF
# like the real Oh My Zsh installer: it writes its own .zshrc only when there is none
cat > "$stubs/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >> "$STUB_LOG"
echo 'mkdir -p "$HOME/.oh-my-zsh" && touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"'
echo '[ -e "$HOME/.zshrc" ] || printf "ZSH_THEME=robbyrussell\nsource \$ZSH/oh-my-zsh.sh\n" > "$HOME/.zshrc"'
EOF
# a tiny store, one "domain|key|value" line per preference; as strict as the real one on booleans
cat > "$stubs/defaults" <<'EOF'
#!/usr/bin/env bash
echo "defaults $*" >> "$STUB_LOG"
cmd=$1 domain=$2 key=$3
touch "$STUB_DB"
case "$cmd" in
  read)   grep -F -- "$domain|$key|" "$STUB_DB" | tail -1 | cut -d'|' -f3- | grep . ;;
  write)  [ "$4" = -bool ] && case "$5" in true|false|yes|no|YES|NO) ;; *) exit 255 ;; esac
          grep -vF -- "$domain|$key|" "$STUB_DB" > "$STUB_DB.tmp"; mv "$STUB_DB.tmp" "$STUB_DB"
          echo "$domain|$key|$5" >> "$STUB_DB" ;;
  delete) grep -vF -- "$domain|$key|" "$STUB_DB" > "$STUB_DB.tmp"; mv "$STUB_DB.tmp" "$STUB_DB" ;;
esac
EOF
cat > "$stubs/osascript" <<'EOF'
#!/usr/bin/env bash
echo "osascript $*" >> "$STUB_LOG"
case "$*" in *"get the name of every login item"*) echo "Finder" ;; esac
EOF
chmod +x "$stubs"/*
unset ZSH ZSH_CUSTOM
export PATH="$stubs:$PATH"

# a HOME with the things a dotfiles user already has
home() {
  export HOME="$tmp/$1" THQ_STATE="$tmp/$1/.local/state/terminal-hq"
  DYNAMIC="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  PROFILE="$DYNAMIC/terminal-hq.json"
  mkdir -p "$HOME"
}
home user
mkdir -p "$HOME/.config/fastfetch" "$HOME/.config/btop" "$HOME/.local/bin" "$DYNAMIC" "$tmp/dotfiles"
printf 'export MINE=1\n' > "$HOME/.zshrc"
echo '{"mine": true}' > "$HOME/.config/fastfetch/config.jsonc"
echo 'color_theme = "hacker"  # mine' > "$HOME/.config/btop/btop.conf"
echo 'echo mine' > "$tmp/dotfiles/itermshortcut"; ln -s "$tmp/dotfiles/itermshortcut" "$HOME/.local/bin/itermshortcut"
echo '{"Profiles":[{"Name":"Old","Guid":"old","Has Hotkey":true,"HotKey Key Code":111}]}' > "$DYNAMIC/old.json"
printf '%s\n' 'com.googlecode.iterm2|Default Bookmark Guid|old' '-g|com.apple.keyboard.fnState|0' > "$STUB_DB"
snapshot() { (cd "$HOME" && find . | sort | while read -r f; do [ -f "$f" ] && echo "$f $(shasum < "$f" | cut -c1-12)" || echo "$f"; done); }
all_options=(--transparency 0.3 --replace-hotkey --default-profile --minimal-ui --fn-keys --login-item)

# ─── check and dry run change nothing ──────────────────────────
before=$(snapshot)
check "check sees the other F12 drop-down" "$("$root/install.sh" --check | grep 'other F12')" "other F12 drop-downs: Old (dynamic, old.json)"
"$root/install.sh" --dry-run "${all_options[@]}" >/dev/null
check "dry run leaves HOME untouched" "$(snapshot)" "$before"
check "dry run installs and asks nothing" "$(grep -c -E '^brew install|^git clone|^curl|^defaults write|^osascript' "$STUB_LOG")" "0"

# ─── install ───────────────────────────────────────────────────
"$root/install.sh" "${all_options[@]}" >/dev/null
check "zshrc keeps its content and gains one line" "$(head -1 "$HOME/.zshrc") / $(grep -c '# terminal-hq' "$HOME/.zshrc")" "export MINE=1 / 1"
check "profile installed with the F12 hotkey" \
  "$(jq -r '.Profiles[0] | "\(.Guid) \(."Has Hotkey") \(."HotKey Key Code")"' "$PROFILE")" "terminal-hq-0001 true 111"
check "transparency applied" "$(jq '.Profiles[0].Transparency' "$PROFILE")" "0.3"
check "other F12 drop-down set aside" "$([ -e "$DYNAMIC/old.json" ] && echo there || echo aside)" "aside"
check "itermshortcut linked to terminal-hq" "$(readlink "$HOME/.local/bin/itermshortcut")" "$root/bin/itermshortcut"
check "fastfetch config linked" "$(readlink "$HOME/.config/fastfetch/config.jsonc")" "$root/modules/tools/fastfetch.jsonc"
check "your btop settings kept" "$(cat "$HOME/.config/btop/btop.conf")" 'color_theme = "hacker"  # mine'
check "Oh My Zsh and plugins" "$(find "$HOME/.oh-my-zsh/custom" -mindepth 2 -maxdepth 2 | sed 's|.*/||' | sort | tr '\n' ' ')" \
  "powerlevel10k zsh-autosuggestions zsh-completions zsh-syntax-highlighting "
check "apps and tools from Homebrew" "$(grep -c -E '^brew install' "$STUB_LOG")" "3"
check "default profile, UI and F-keys set" \
  "$(defaults read com.googlecode.iterm2 'Default Bookmark Guid') $(defaults read com.googlecode.iterm2 HideTab) $(defaults read -g com.apple.keyboard.fnState)" \
  "terminal-hq-0001 true true"
check "login item added" "$(grep -c 'make login item' "$STUB_LOG")" "1"

# ─── a second run changes nothing more ─────────────────────────
jq '.Profiles[0].Transparency = 0.5' "$PROFILE" > "$tmp/p" && cp "$tmp/p" "$PROFILE"
"$root/install.sh" >/dev/null
check "second run: still one zshrc line" "$(grep -c '# terminal-hq' "$HOME/.zshrc")" "1"
check "second run: profile edits kept" "$(jq '.Profiles[0].Transparency' "$PROFILE")" "0.5"
check "second run: previous values not overwritten" "$(grep -c 'Default Bookmark Guid' "$THQ_STATE/prefs")" "1"

# ─── uninstall puts everything back ────────────────────────────
"$root/uninstall.sh" >/dev/null
check "zshrc back as it was" "$(cat "$HOME/.zshrc")" "export MINE=1"
check "profile removed" "$([ -e "$PROFILE" ] && echo there || echo gone)" "gone"
check "other F12 drop-down back" "$(jq -r '.Profiles[0].Name' "$DYNAMIC/old.json")" "Old"
check "your itermshortcut link back" "$(readlink "$HOME/.local/bin/itermshortcut")" "$tmp/dotfiles/itermshortcut"
check "your fastfetch config back" "$(cat "$HOME/.config/fastfetch/config.jsonc")" '{"mine": true}'
check "your btop settings still there" "$(cat "$HOME/.config/btop/btop.conf")" 'color_theme = "hacker"  # mine'
check "previous default profile back" "$(defaults read com.googlecode.iterm2 'Default Bookmark Guid')" "old"
check "previous F-key setting back" "$(defaults read -g com.apple.keyboard.fnState)" "false"
check "preferences that did not exist are gone" "$(defaults read com.googlecode.iterm2 HideTab || echo unset)" "unset"
check "login item removed" "$(grep -c 'delete login item' "$STUB_LOG")" "1"

# ─── a brand-new Mac: no .zshrc, no Oh My Zsh ──────────────────
home fresh
"$root/install.sh" zsh >/dev/null
check "fresh: Oh My Zsh did not write its own theme" "$(grep -c robbyrussell "$HOME/.zshrc")" "0"
check "fresh: zshrc loads terminal-hq" "$(grep -c '# terminal-hq' "$HOME/.zshrc")" "1"
check "fresh: ~/.local/bin on PATH, p10k configure writes ~/.p10k.zsh" \
  "$(zsh -f -c 'source "$1"; print $(( ${path[(I)$HOME/.local/bin]} > 0 )) $POWERLEVEL9K_CONFIG_FILE' _ "$root/modules/zsh/terminal-hq.zsh" 2>/dev/null)" \
  "1 $HOME/.p10k.zsh"
"$root/uninstall.sh" zsh >/dev/null
check "fresh: the empty zshrc it created is gone" "$([ -e "$HOME/.zshrc" ] && echo there || echo gone)" "gone"

# ─── options ───────────────────────────────────────────────────
home options
"$root/install.sh" --no-hotkey iterm2 >/dev/null
check "--no-hotkey: green profile without drop-down" "$(jq '.Profiles[0]."Has Hotkey"' "$PROFILE")" "false"
for t in 0.5x 7 ""; do
  check "transparency '$t' refused" "$("$root/install.sh" --dry-run --transparency $t iterm2 >/dev/null 2>&1 && echo accepted || echo refused)" "refused"
done
for t in .5 1.00 0; do
  check "transparency '$t' accepted" "$("$root/install.sh" --dry-run --transparency $t iterm2 >/dev/null 2>&1 && echo accepted || echo refused)" "accepted"
done

# ─── the shipped files are valid ───────────────────────────────
check "zsh file parses" "$(zsh -n "$root/modules/zsh/terminal-hq.zsh" 2>&1 && echo ok)" "ok"
check "profile hotkey is F12" "$(python3 -c "import json,sys; p=json.load(open(sys.argv[1]))['Profiles'][0]; print(hex(ord(p['HotKey Characters'])))" "$root/modules/iterm2/terminal-hq.json")" "0xf70f"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
