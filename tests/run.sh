#!/usr/bin/env bash
# Installs and uninstalls terminal-hq in a throwaway HOME, with brew, git, curl, defaults and osascript
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
cat > "$stubs/curl" <<'EOF'
#!/usr/bin/env bash
echo "curl $*" >> "$STUB_LOG"
echo 'mkdir -p "$HOME/.oh-my-zsh" && touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"'
EOF
cat > "$stubs/defaults" <<'EOF'
#!/usr/bin/env bash
# a tiny store: one "domain|key|value" line per preference
echo "defaults $*" >> "$STUB_LOG"
cmd=$1 domain=$2 key=$3
touch "$STUB_DB"
case "$cmd" in
  read)   grep -F -- "$domain|$key|" "$STUB_DB" | tail -1 | cut -d'|' -f3- | grep . ;;
  write)  grep -vF -- "$domain|$key|" "$STUB_DB" > "$STUB_DB.tmp"; mv "$STUB_DB.tmp" "$STUB_DB"
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
export HOME="$tmp/home" THQ_STATE="$tmp/home/.local/state/terminal-hq" PATH="$stubs:$PATH"
PROFILE="$HOME/Library/Application Support/iTerm2/DynamicProfiles/terminal-hq.json"
mkdir -p "$HOME/.config/fastfetch"
printf 'export MINE=1\n' > "$HOME/.zshrc"
echo '{"mine": true}' > "$HOME/.config/fastfetch/config.jsonc"
echo 'com.googlecode.iterm2|Default Bookmark Guid|old-guid' > "$STUB_DB"
snapshot() { (cd "$HOME" && find . | sort | while read -r f; do [ -f "$f" ] && echo "$f $(shasum < "$f" | cut -c1-12)" || echo "$f"; done); }

# ─── dry run changes nothing ───────────────────────────────────
before=$(snapshot)
"$root/install.sh" --dry-run --transparency 0.3 --default-profile --minimal-ui --fn-keys --login-item >/dev/null
check "dry run leaves HOME untouched" "$(snapshot)" "$before"
check "dry run installs nothing" "$(grep -c -E '^brew install|^git clone|^curl|^defaults write' "$STUB_LOG")" "0"

# ─── install ───────────────────────────────────────────────────
"$root/install.sh" --transparency 0.3 --default-profile --minimal-ui --fn-keys --login-item >/dev/null
check "zshrc keeps its content and gains one line" "$(head -1 "$HOME/.zshrc") / $(grep -c '# terminal-hq' "$HOME/.zshrc")" "export MINE=1 / 1"
check "profile installed with the F12 hotkey" \
  "$(jq -r '.Profiles[0] | "\(.Guid) \(."Has Hotkey") \(."HotKey Key Code")"' "$PROFILE")" "terminal-hq-0001 true 111"
check "transparency applied" "$(jq '.Profiles[0].Transparency' "$PROFILE")" "0.3"
check "itermshortcut linked" "$(readlink "$HOME/.local/bin/itermshortcut")" "$root/bin/itermshortcut"
check "fastfetch config linked" "$(readlink "$HOME/.config/fastfetch/config.jsonc")" "$root/modules/tools/fastfetch.jsonc"
check "your fastfetch config saved aside" "$(cat "$THQ_STATE/backup$HOME/.config/fastfetch/config.jsonc")" '{"mine": true}'
check "btop theme and settings" "$(readlink "$HOME/.config/btop/themes/hacker.theme") $(head -1 "$HOME/.config/btop/btop.conf")" \
  "$root/modules/tools/btop/hacker.theme color_theme = \"hacker\""
check "Oh My Zsh and plugins" "$(ls "$HOME/.oh-my-zsh/custom/plugins" | tr '\n' ' ')$(ls "$HOME/.oh-my-zsh/custom/themes")" \
  "zsh-autosuggestions zsh-completions zsh-syntax-highlighting powerlevel10k"
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
check "itermshortcut removed" "$([ -e "$HOME/.local/bin/itermshortcut" ] && echo there || echo gone)" "gone"
check "your fastfetch config restored" "$(cat "$HOME/.config/fastfetch/config.jsonc")" '{"mine": true}'
check "previous default profile back" "$(defaults read com.googlecode.iterm2 'Default Bookmark Guid')" "old-guid"
check "preferences that did not exist are gone" \
  "$(defaults read com.googlecode.iterm2 HideTab || echo unset) $(defaults read -g com.apple.keyboard.fnState || echo unset)" "unset unset"
check "login item removed" "$(grep -c 'delete login item' "$STUB_LOG")" "1"

# ─── the shipped files are valid ───────────────────────────────
check "zsh file parses" "$(zsh -n "$root/modules/zsh/terminal-hq.zsh" 2>&1 && echo ok)" "ok"
check "profile hotkey is F12" "$(python3 -c "import json,sys; p=json.load(open(sys.argv[1]))['Profiles'][0]; print(hex(ord(p['HotKey Characters'])))" "$root/modules/iterm2/terminal-hq.json")" "0xf70f"
check "bad transparency refused" "$("$root/install.sh" --dry-run --transparency 7 iterm2 >/dev/null 2>&1 && echo accepted || echo refused)" "refused"

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ]
