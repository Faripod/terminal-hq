# Shared by install.sh and uninstall.sh. Every change goes through these helpers so that it can be
# previewed (THQ_DRY_RUN=1) and undone: files replaced are moved under $THQ_STATE/backup, macOS
# preferences keep their previous value in $THQ_STATE/prefs.

THQ_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
THQ_STATE=${THQ_STATE:-$HOME/.local/state/terminal-hq}
THQ_MARK="# terminal-hq"
DRY=${THQ_DRY_RUN:-}
PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

say()  { printf '  %s\n' "$*"; }
step() { printf '\n\033[1;32m%s\033[0m\n' "$*"; }
fail() { printf '\033[0;31m  %s\033[0m\n' "$*" >&2; exit 1; }

run() {
  if [ -n "$DRY" ]; then say "would run: $*"; else "$@"; fi
}

# the file's place inside the backup folder
backup_path() { printf '%s/backup%s' "$THQ_STATE" "$1"; }

# moves a real file out of the way, once, so uninstall can put it back
backup() {
  local b
  b=$(backup_path "$1")
  if [ -e "$1" ] && [ ! -L "$1" ] && [ ! -e "$b" ]; then
    run mkdir -p "$(dirname "$b")"
    run mv "$1" "$b"
    say "saved $1"
  fi
}

# restore dst: removes what we put there and brings back the backup, if any
restore() {
  local b
  b=$(backup_path "$1")
  if [ -L "$1" ] || [ -e "$b" ]; then run rm -f "$1"; fi
  if [ -e "$b" ]; then run mv "$b" "$1"; say "restored $1"; fi
}

link() {
  backup "$2"
  run mkdir -p "$(dirname "$2")"
  run ln -sfn "$1" "$2"
  say "linked $2"
}

# for files the app itself rewrites: a copy, and only when the user has none
copy_if_absent() {
  if [ -e "$2" ]; then say "kept your $2"; return; fi
  run mkdir -p "$(dirname "$2")"
  run cp "$1" "$2"
  say "copied $2"
}

# appends a line tagged with the terminal-hq mark, once
add_line() {
  grep -qF "$THQ_MARK" "$1" 2>/dev/null && { say "$1 already loads terminal-hq"; return; }
  if [ -n "$DRY" ]; then say "would add to $1: $2"; return; fi
  [ -s "$1" ] && [ -n "$(tail -c1 "$1")" ] && echo >> "$1"
  printf '%s  %s\n' "$2" "$THQ_MARK" >> "$1"
  say "added one line to $1"
}

remove_line() {
  local tmp
  grep -qF "$THQ_MARK" "$1" 2>/dev/null || return 0
  if [ -n "$DRY" ]; then say "would remove the terminal-hq line from $1"; return; fi
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
    [ -n "$DRY" ] || { mkdir -p "$THQ_STATE"; printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$old" >> "$THQ_STATE/prefs"; }
  fi
  run defaults write "$1" "$2" "-$3" "$4"
  say "set $1 $2 = $4"
}

# puts back every preference recorded for a domain
restore_prefs() {
  local domain key type old
  [ -f "$THQ_STATE/prefs" ] || return 0
  while IFS='|' read -r domain key type old; do
    [ "$domain" = "$1" ] || continue
    if [ "$old" = "<unset>" ]; then run defaults delete "$domain" "$key" 2>/dev/null
    else run defaults write "$domain" "$key" "-$type" "$old"; fi
    say "restored $domain $key"
  done < "$THQ_STATE/prefs"
  [ -n "$DRY" ] && return
  grep -v "^$1|" "$THQ_STATE/prefs" > "$THQ_STATE/prefs.tmp"; mv "$THQ_STATE/prefs.tmp" "$THQ_STATE/prefs"
}

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
