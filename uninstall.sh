#!/usr/bin/env bash
#
# Takes back what install.sh did: the Terminal HQ profile, the .zshrc line, the configurations,
# the macOS and iTerm2 preferences (to their previous values) and the files it had moved aside.
# Installed apps and tools stay.
#
# usage: ./uninstall.sh [--dry-run] [iterm2] [zsh] [tools]     (no module = all three)
#

. "$(cd "$(dirname "$0")" && pwd)/lib/helpers.sh"

modules=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)        DRY=1 ;;
    iterm2|zsh|tools) modules+=("$1") ;;
    *)                sed -n '8p' "$0" | sed 's/^# //' >&2; exit 1 ;;
  esac
  shift
done
[ ${#modules[@]} -gt 0 ] || modules=(zsh iterm2 tools)
[ -n "$DRY" ] && step "Dry run: nothing is changed"

for module in "${modules[@]}"; do
  . "$THQ_ROOT/modules/$module/uninstall.sh"
done
step "Done"
