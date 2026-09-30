# Shared by install.sh and uninstall.sh. Every change goes through these helpers so that it can be
# previewed (THQ_DRY_RUN=1) and undone: whatever was in the way (a file or someone else's link) is moved
# under $THQ_STATE/backup, files terminal-hq creates are listed in $THQ_STATE/created, macOS preferences
# keep their previous value in $THQ_STATE/prefs.

THQ_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
THQ_STATE=${THQ_STATE:-$HOME/.local/state/terminal-hq}
THQ_MARK="# terminal-hq"
DRY=${THQ_DRY_RUN:-}
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

say()  { printf '  %s\n' "$*"; }
step() { printf '\n\033[1;32m%s\033[0m\n' "$*"; }
fail() { printf '\033[0;31m  %s\033[0m\n' "$*" >&2; exit 1; }
dry()  { [ -n "$DRY" ]; }

run() {
  if dry; then say "would run: $(printf '%q ' "$@")"; else "$@"; fi
}

# the file's place inside the backup folder
backup_path() { printf '%s/backup%s' "$THQ_STATE" "$1"; }
exists()      { [ -e "$1" ] || [ -L "$1" ]; }
ours()        { [ -L "$1" ] && case "$(readlink "$1")" in "$THQ_ROOT"/*) true ;; *) false ;; esac; }

# moves whatever sits at $1 out of the way, once, so uninstall can put it back
backup() {
  local b
  b=$(backup_path "$1")
  exists "$1" && ! ours "$1" && ! exists "$b" || return 0
  if dry; then say "would save $1 in $(dirname "$b")"; return; fi
  mkdir -p "$(dirname "$b")"
  mv "$1" "$b"
  say "saved $1"
}

# removes what terminal-hq put at $1 and brings back what was there before
restore() {
  local b
  b=$(backup_path "$1")
  if exists "$1" && ! ours "$1" && ! created_here "$1"; then
    exists "$b" && say "left your $1 (the earlier one is in $b)"
    return
  fi
  if dry; then exists "$1" && say "would remove $1"; exists "$b" && say "would put back $1"; return; fi
  exists "$1" && rm -f "$1"
  forget "$1"
  exists "$b" && { mv "$b" "$1"; say "put back $1"; }
}

link() {
  if [ "$(readlink "$2")" = "$1" ]; then say "already linked: $2"; return; fi
  backup "$2"
  if dry; then say "would link $2"; return; fi
  mkdir -p "$(dirname "$2")"
  ln -sfn "$1" "$2"
  say "linked $2"
}

created()      { dry || { mkdir -p "$THQ_STATE"; created_here "$1" || echo "$1" >> "$THQ_STATE/created"; }; }
created_here() { grep -qxF -- "$1" "$THQ_STATE/created" 2>/dev/null; }
forget() {
  created_here "$1" || return 0
  grep -vxF -- "$1" "$THQ_STATE/created" > "$THQ_STATE/created.tmp"
  mv "$THQ_STATE/created.tmp" "$THQ_STATE/created"
}

# for files the app itself rewrites: a copy, and only when the user has none
copy_if_absent() {
  if exists "$2"; then say "kept your $2"; return; fi
  if dry; then say "would copy $2"; return; fi
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
  created "$2"
  say "copied $2"
}

# deletes a file only if terminal-hq created it
remove_created() {
  created_here "$1" || return 0
  if dry; then say "would remove $1"; return; fi
  rm -f "$1"
  forget "$1"
  say "removed $1"
}

# appends a line tagged with the terminal-hq mark, once
add_line() {
  grep -qF "$THQ_MARK" "$1" 2>/dev/null && { say "$1 already loads terminal-hq"; return; }
  if dry; then say "would add to $1: $2"; return; fi
  [ -s "$1" ] && [ -n "$(tail -c1 "$1")" ] && echo >> "$1"
  printf '%s  %s\n' "$2" "$THQ_MARK" >> "$1"
  say "added one line to $1"
}

remove_line() {
  local tmp
  grep -qF "$THQ_MARK" "$1" 2>/dev/null || return 0
  if dry; then say "would remove the terminal-hq line from $1"; return; fi
  tmp=$(mktemp)
  grep -vF "$THQ_MARK" "$1" > "$tmp"
  cat "$tmp" > "$1"
  rm -f "$tmp"
  say "removed the terminal-hq line from $1"
}

# set_pref domain key type value: remembers the previous value the first time
set_pref() {
  local old
  if ! grep -qF -- "$1|$2|" "$THQ_STATE/prefs" 2>/dev/null; then
    old=$(defaults read "$1" "$2" 2>/dev/null) || old="<unset>"
    dry || { mkdir -p "$THQ_STATE"; printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$old" >> "$THQ_STATE/prefs"; }
  fi
  run defaults write "$1" "$2" "-$3" "$4"
  dry || say "set $1 $2 = $4"
}

# puts back every preference recorded for a domain
restore_prefs() {
  local domain key type old
  [ -f "$THQ_STATE/prefs" ] || return 0
  while IFS='|' read -r domain key type old; do
    [ "$domain" = "$1" ] || continue
    # defaults reads booleans back as 1/0 but only writes true/false
    [ "$type" = bool ] && case "$old" in 1) old=true ;; 0) old=false ;; esac
    if [ "$old" = "<unset>" ]; then run defaults delete "$domain" "$key" 2>/dev/null
    else run defaults write "$domain" "$key" "-$type" "$old"; fi
    dry || say "put back $domain $key"
  done < "$THQ_STATE/prefs"
  dry && return
  grep -v -- "^$1|" "$THQ_STATE/prefs" > "$THQ_STATE/prefs.tmp"; mv "$THQ_STATE/prefs.tmp" "$THQ_STATE/prefs"
}

# not pgrep: it leaves out its own ancestors, and iTerm2 is often one
iterm_running() { ps -axo comm= | grep -q "iTerm.app/Contents/MacOS/iTerm2$"; }

brew_install() {
  local missing=() f
  for f in "$@"; do brew list --formula "$f" >/dev/null 2>&1 || missing+=("$f"); done
  [ ${#missing[@]} -eq 0 ] && { say "already installed: $*"; return; }
  run brew install --quiet "${missing[@]}"
}

brew_cask() {
  local missing=() c
  for c in "$@"; do brew list --cask "$c" >/dev/null 2>&1 || missing+=("$c"); done
  [ ${#missing[@]} -eq 0 ] && { say "already installed: $*"; return; }
  run brew install --cask --quiet "${missing[@]}"
}
