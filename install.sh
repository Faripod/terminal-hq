#!/usr/bin/env bash
#
# terminal-hq installer. AGENTS.md explains how an agent runs it for you.
#
# usage: ./install.sh [--dry-run] [options] [iterm2] [zsh] [tools]     (no module = all three)
#   --transparency N   iTerm2 window transparency, 0 (opaque) to 1; the profile ships with 0.42
#   --default-profile  new iTerm2 windows use Terminal HQ too
#   --minimal-ui       iTerm2 without tab bar, scrollbar and pane titles; inactive panes dimmed
#   --fn-keys          F1, F2... act as standard function keys, so F12 works without fn
#   --login-item       iTerm2 opens at login, so F12 is always ready
#

. "$(cd "$(dirname "$0")" && pwd)/lib/helpers.sh"

usage() { sed -n '4,11p' "$0" | sed 's/^# \{0,1\}//'; }

modules=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)         DRY=1 ;;
    --transparency)    THQ_TRANSPARENCY=$2; shift ;;
    --default-profile) THQ_DEFAULT_PROFILE=1 ;;
    --minimal-ui)      THQ_MINIMAL_UI=1 ;;
    --fn-keys)         THQ_FN_KEYS=1 ;;
    --login-item)      THQ_LOGIN_ITEM=1 ;;
    iterm2|zsh|tools)  modules+=("$1") ;;
    -h|--help)         usage; exit 0 ;;
    *)                 usage >&2; exit 1 ;;
  esac
  shift
done
[ ${#modules[@]} -gt 0 ] || modules=(tools iterm2 zsh)

[ "$(uname -s)" = Darwin ] || fail "terminal-hq is for macOS (see README, Other systems)"
command -v brew >/dev/null || fail "Homebrew is needed first: https://brew.sh"
[ -n "$DRY" ] && step "Dry run: nothing is changed"

for module in "${modules[@]}"; do
  . "$THQ_ROOT/modules/$module/install.sh"
done

step "Done"
say "open a new tab to see the prompt, press F12 for the drop-down terminal"
say "itermshortcut lists the shortcuts; ./uninstall.sh takes everything back"
