# terminal-hq 🟩

A green, translucent terminal that drops from the top of the screen with **F12**, over any app — plus
the prompt, plugins and tools that go with it. macOS, iTerm2, zsh.

## Install

**Don't install it by hand.** Open Claude Code (or another coding agent), paste this and send it:

```
Install https://github.com/Faripod/terminal-hq
```

The agent follows [AGENTS.md](AGENTS.md): it looks at your Mac and your `.zshrc` first, asks what you
want (modules, transparency, F12 behavior), shows you the plan, installs, runs the tests and asks you to
press F12. If something breaks it fixes it and proposes the fix here. Everything can be taken back.

<details>
<summary>By hand</summary>

Requires [Homebrew](https://brew.sh).

```bash
git clone https://github.com/Faripod/terminal-hq ~/.local/share/terminal-hq
cd ~/.local/share/terminal-hq
./install.sh --dry-run          # see what would change
./install.sh                    # all modules, default options
./install.sh --help             # modules and options
```
</details>

## What you get

| Module | What |
|---|---|
| `iterm2` | The **Terminal HQ** profile: green on black, 42% transparency with blur, Hack Nerd Font, a full-width drop-down window on F12, errors highlighted in red, ⌘←/→ for start/end of line, ⌥←/→ to jump words, ⌘⌫ to delete the line. The `itermshortcut` cheatsheet (`-w` for the illustrated page). |
| `zsh` | Oh My Zsh with the green Powerlevel10k prompt, autosuggestions, syntax highlighting and completions in green, 50k lines of shared history, aliases for git and the tools below. |
| `tools` | eza, bat, fzf (green), fd, ripgrep, btop (hacker theme), lazygit, thefuck, fastfetch (the banner), cmatrix and pipes.sh. |

Options: `--transparency 0.3`, `--default-profile` (all new iTerm2 windows green), `--minimal-ui` (no tab
bar, no scrollbar, dimmed inactive panes), `--fn-keys` (F12 without fn), `--login-item` (iTerm2 at
login, so F12 always works), `--replace-hotkey` (set aside another drop-down already on F12),
`--no-hotkey` (the green profile without the drop-down). `./install.sh --check` shows what is already
there; `export THQ_BANNER=off` before the terminal-hq line hides the banner.

## Shortcuts

| Keys | |
|---|---|
| F12 | show / hide the terminal |
| ⌘D · ⌘⇧D | split right · split below |
| ⌘⌥ + arrows | move between panes |
| ⌘T · ⌘⇧[ ⌘⇧] · ⌘1…9 | new tab · previous/next tab · tab number |
| ⌘← ⌘→ · ⌥← ⌥→ · ⌘⌫ | start/end of line · word back/forward · delete line |

`itermshortcut` prints them in the terminal.

## Safe to try

- Your `~/.zshrc` is not replaced: one line is appended, and anything after it wins. Your own
  `~/.p10k.zsh` wins over the green prompt.
- Every file or link it would replace is saved under `~/.local/state/terminal-hq/backup`, every
  iTerm2 or macOS preference keeps its previous value, and uninstall only deletes files it created.
- `./uninstall.sh` puts all of it back. Installed apps and tools stay (`brew uninstall` removes them).
- `tests/run.sh` installs and uninstalls in a throwaway HOME to prove it.

## Pairs well with

[radio-hq](https://github.com/Faripod/radio-hq): Claude Code sessions announce themselves with a banner and
a radio voice when they wait for you, handy when they live in a drop-down you keep hiding.

## Other systems

macOS only. The zsh and tools modules would port to Linux with little work (apt/dnf instead of brew);
the drop-down has equivalents (Guake, Yakuake, Windows Terminal quake mode). Ask your agent to start a
port in a fork and propose it here.

## License

MIT. Oh My Zsh, Powerlevel10k, the plugins and the tools are installed from their own projects under
their own licenses.
