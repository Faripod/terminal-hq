# AGENTS.md — installing terminal-hq for your user

You are an AI coding agent (Claude Code or similar). Your user gave you this repository and asked you to
install it. They may not know how to set up a terminal: you do the work, they choose, confirm and press
F12 when you ask. Follow the steps in order.

**Ground rules**

- Speak the user's language. Short messages; group the choices of step 3 in one question.
- Ask before installing anything, changing a macOS or iTerm2 setting, or touching their `~/.zshrc`.
  `install.sh --dry-run` shows exactly what will happen: show it before the real run.
- Never open an issue or pull request without the user's explicit OK, and never put their personal data
  in one (usernames, home paths, their .zshrc content).
- If a step fails, go to [When something breaks](#when-something-breaks) instead of improvising.

## 1. Explain and confirm

In two or three sentences: a green, translucent terminal that drops from the top of the screen with F12,
over any app; a green prompt (Powerlevel10k) with suggestions and syntax colors; modern tools (eza, bat,
fzf, btop, lazygit…); `itermshortcut` to remember the shortcuts. Everything can be taken back with
`./uninstall.sh`. Ask for a go.

## 2. Look at the Mac first

```bash
uname -s; sw_vers -productVersion
command -v brew git; ls /Applications | grep -i iterm
cat ~/.zshrc; ls -la ~/.zshrc ~/.p10k.zsh ~/.oh-my-zsh 2>&1
ls ~/Library/Application\ Support/iTerm2/DynamicProfiles/ 2>/dev/null
```

- **Not macOS**: terminal-hq is macOS-only. Say so; offer to adapt the zsh and tools modules to their
  system in a fork and propose it upstream (see README, Other systems).
- **No Homebrew**: it needs the user's password, so they install it. Give them the command to run
  with `!` in front, from https://brew.sh, and wait.
- **Their ~/.zshrc**: terminal-hq only appends one line, and whatever comes after it wins. If it already
  loads Oh My Zsh with another theme, or sources its own `~/.p10k.zsh`, tell them their setup keeps
  priority and ask whether they want the green prompt instead (then the line should go after theirs, or
  their theme line goes away: their call). If `~/.zshrc` is a symlink (dotfiles), say that the line will
  be written into the file it points to.
- **Another iTerm2 hotkey window on F12** (a JSON in `DynamicProfiles` with `"Has Hotkey": true`, or
  iTerm2 Settings › Keys › Hotkey): two windows on one key fight. Ask which one they keep.

## 3. Their choices

Ask, with the defaults shown:

- **Modules**: `iterm2` (profile, F12, shortcuts), `zsh` (prompt and plugins), `tools` (the CLI tools).
  All three by default.
- **Transparency**: 0.42 by default (0 = opaque, 1 = invisible). More or less see-through?
- **iTerm2**: `--default-profile` (every new window green, not only the drop-down) and `--minimal-ui`
  (no tab bar, no scrollbar, inactive panes dimmed).
- **F12**: on Mac keyboards F12 is the volume key. `--fn-keys` makes F1, F2… standard function keys
  (the media functions move to fn+key); without it they press fn+F12.
- **At login**: `--login-item` opens iTerm2 at login, so F12 always works.

## 4. Get it

```bash
git clone https://github.com/Faripod/terminal-hq ~/.local/share/terminal-hq \
  || git -C ~/.local/share/terminal-hq pull
cd ~/.local/share/terminal-hq
bash tests/run.sh
```

Every test line must say `ok` (they install into a throwaway HOME and change nothing). A failure is a
bug: [When something breaks](#when-something-breaks).

## 5. Preview, then install

```bash
./install.sh --dry-run <options> <modules>
```

Summarize the plan for the user in plain words (what gets installed, which files are saved aside and
where, which settings change). With their OK run the same command without `--dry-run`. Homebrew may take
a few minutes for iTerm2 and the tools.

## 6. Check it with them

1. If iTerm2 is not running: `open -a iTerm`.
2. Ask them to press **F12** (or fn+F12): a green, translucent terminal should slide down from the top,
   and F12 again hides it. If nothing happens:
   - iTerm2 must be running;
   - iTerm2 › Settings › Profiles › Terminal HQ › Keys › *Hotkey Window* should show F12;
   - with `--fn-keys`, the change sometimes needs a log out and back in; fn+F12 works meanwhile;
   - another hotkey window on F12 (step 2).
3. In that terminal a new tab (⌘T) shows the green prompt and the system banner. Squares instead of
   icons: quit and reopen iTerm2 (the font was just installed). A Powerlevel10k configuration wizard
   means the prompt configuration did not load: that is a bug.
4. `itermshortcut` prints the shortcuts; `itermshortcut -w` opens the illustrated page.

## 7. Finish

Recap in a few lines: F12, `itermshortcut`, how to change the transparency
(`./install.sh iterm2 --transparency 0.3`, or iTerm2 › Settings › Profiles › Terminal HQ › Window),
how to update (`git -C ~/.local/share/terminal-hq pull`), how to undo (`./uninstall.sh`).
If they use Claude Code, mention [radio-hq](https://github.com/Faripod/radio-hq): announcements when a
session waits for them, made to live in this drop-down.

## When something breaks

1. Reproduce it: `tests/run.sh`, `./install.sh --dry-run`, or the failing step.
2. Find the cause. The map: `install.sh` / `uninstall.sh` parse options and run the modules,
   `lib/helpers.sh` does every change (backup, link, preferences), `modules/<name>/` holds each part and
   its files, `tests/run.sh` is the contract.
3. Fix it in a fork, never in the user's copy only:
   `gh repo fork Faripod/terminal-hq --clone && cd terminal-hq`. Add a check to `tests/run.sh` that fails
   before the fix, fix, run the tests, show the user the diff in plain words.
4. With the user's OK: `gh pr create --repo Faripod/terminal-hq` with what broke, the macOS version and
   the test output; if you could not fix it, `gh issue create --repo Faripod/terminal-hq` with the same.
   Without `gh`, write the text for them to paste on GitHub.

## Uninstall

```bash
cd ~/.local/share/terminal-hq && ./uninstall.sh
```

It removes the profile, the `.zshrc` line and the configurations, puts back the files it had saved and
the iTerm2 and macOS preferences as they were. iTerm2, the font, Oh My Zsh and the tools stay: offer
`brew uninstall` for any they do not want. Then `rm -rf ~/.local/share/terminal-hq`.

## Working on this repo

- `tests/run.sh` must pass before every commit; a behavior change comes with a check.
- Every change to the user's machine goes through `lib/helpers.sh`, so that `--dry-run` shows it and
  `uninstall.sh` can take it back.
- Commits: `<type>: <gitmoji> <description>` (`feat: ✨ ...`, `fix: 🐛 ...`).
