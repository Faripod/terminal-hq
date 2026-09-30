# ./install.sh --check: what is already on this Mac that terminal-hq would meet. Reads only.
# One "name: value" line per fact; AGENTS.md step 3 says what to do with each.

DYNAMIC="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
yes_no() { if "$@" >/dev/null 2>&1; then echo yes; else echo no; fi; }

echo "macos: $(sw_vers -productVersion 2>/dev/null || echo no)"
echo "homebrew: $(command -v brew || echo missing)"
echo "iterm2 installed: $(yes_no test -d /Applications/iTerm.app)"
echo "iterm2 running: $(yes_no iterm_running)"
echo "running inside iterm2: $([ "$TERM_PROGRAM" = iTerm.app ] && echo yes || echo no)"

# drop-down windows already on F12 (key code 111), in dynamic and in regular profiles
others=()
for f in "$DYNAMIC"/*.json; do
  [ -f "$f" ] && [ "$(basename "$f")" != terminal-hq.json ] || continue
  while IFS= read -r name; do others+=("$name (dynamic, $(basename "$f"))"); done < <(
    jq -r '.Profiles[]? | select(."Has Hotkey" == true and ."HotKey Key Code" == 111) | .Name' "$f" 2>/dev/null)
done
if [ -f "$ITERM_PLIST" ]; then
  while IFS= read -r name; do [ -n "$name" ] && others+=("$name (iTerm2 settings)"); done < <(
    plutil -extract "New Bookmarks" json -o - "$ITERM_PLIST" 2>/dev/null \
      | jq -r '.[] | select(."Has Hotkey" == true and ."HotKey Key Code" == 111 and ."Dynamic Profile Filename" == null) | .Name' 2>/dev/null)
fi
echo "other F12 drop-downs: ${others[*]:-none}"
echo "iterm2 default profile: $(defaults read com.googlecode.iterm2 'Default Bookmark Guid' 2>/dev/null || echo unset)"
echo "fn keys as standard: $(defaults read -g com.apple.keyboard.fnState 2>/dev/null || echo 0)"

rc="$HOME/.zshrc"
if [ -L "$rc" ]; then echo "zshrc: symlink to $(readlink "$rc")"
elif [ -f "$rc" ]; then echo "zshrc: file, $(wc -l < "$rc" | tr -d ' ') lines"
else echo "zshrc: none"; fi
if [ -f "$rc" ]; then
  echo "zshrc loads terminal-hq: $(yes_no grep -qF '# terminal-hq' "$rc")"
  echo "zshrc loads oh my zsh: $(yes_no grep -qE 'oh-my-zsh\.sh' "$rc")"
  echo "zshrc theme: $(grep -E '^\s*ZSH_THEME=' "$rc" | tail -1 | cut -d= -f2- | tr -d '"'"'" || true)"
  echo "zshrc banner: $(grep -oE '^\s*(neofetch|fastfetch|screenfetch)' "$rc" | tr -d ' ' | tr '\n' ' ' || true)"
  echo "zshrc sources p10k config: $(yes_no grep -qE 'p10k\.zsh' "$rc")"
fi
echo "own ~/.p10k.zsh (wins over the green one): $(yes_no test -e "$HOME/.p10k.zsh")"
echo "oh my zsh: $(yes_no test -f "${ZSH:-$HOME/.oh-my-zsh}/oh-my-zsh.sh")"
echo "previous terminal-hq install: $(yes_no test -d "$THQ_STATE")"
