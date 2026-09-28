# booknote

Centralized Neovim configuration, shared between a work PC and a home PC
(both Windows) via this repo. Clone it once per machine, and `git pull` to
sync changes; `git push` when you've made changes worth keeping.

This repo root **is** the Neovim config directory - there's no separate
"install" step beyond cloning it to the right place.

## What's in here

- `init.lua` - entry point; sets the leader key, loads `lua/core/*`, then
  bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) (the plugin
  manager) and loads every spec under `lua/plugins/*.lua`.
- `lua/core/` - options, keymaps, autocommands. No plugins involved.
- `lua/plugins/` - one file per plugin (or small group of related plugins).
  Add a new file here to add a new plugin; lazy.nvim picks it up
  automatically the next time you start Neovim.
- `lua/unicode.lua` - insert-mode abbreviations for special characters
  (Greek letters, math symbols, super/subscripts) - type `;mu` in insert mode
  and it expands to `μ`, etc. See the plain-text `unicode` file for the
  reference list.
- `lua/local.lua.example` - template for machine-specific settings (e.g. a
  work proxy) that should never be committed. Copy it to `lua/local.lua`;
  that filename is gitignored.
- `lazy-lock.json` - once it exists (generated automatically on first
  launch), **commit it**. It pins exact plugin versions so both machines run
  identical plugin code, not just "whatever was newest today."
- `psprofiledemo.zip` - unrelated PowerShell profile example, kept for
  reference; ignore it for Neovim setup purposes.

## First-time setup (each machine)

Both your machines are Windows, so on **each** one:

1. **Install Neovim** (0.10+) and **git**, if not already present:
   ```powershell
   winget install Neovim.Neovim
   winget install Git.Git
   ```
   No admin rights at work? Grab the portable `nvim-win64.zip` from the
   [Neovim releases page](https://github.com/neovim/neovim/releases) instead
   and put it somewhere on your `PATH`, e.g. `%LOCALAPPDATA%\Programs\nvim`.

2. **Clone this repo directly into Neovim's config directory.** On Windows
   that's `%LOCALAPPDATA%\nvim`. If that folder already exists (even empty),
   remove or rename it first - `git clone` won't clone into a non-empty
   directory.
   ```powershell
   git clone https://github.com/carlhe87/booknote.git "$env:LOCALAPPDATA\nvim"
   ```

3. **Launch Neovim:**
   ```powershell
   nvim
   ```
   The first launch will look like it's "doing nothing" for a few seconds,
   then a bunch of text will scroll by - that's lazy.nvim installing every
   plugin listed under `lua/plugins/`. Once it settles, restart Neovim once
   more so treesitter/LSP tooling finishes registering.

4. **Verify:** run `:checkhealth` inside Neovim and look for anything in
   red. A few warnings (e.g. missing optional tools) are fine; errors under
   "treesitter" usually mean you need a C compiler (see below).

5. *(Optional, work PC)* If your network needs a proxy for git/GitHub, copy
   `lua/local.lua.example` to `lua/local.lua` and set `HTTP_PROXY` /
   `HTTPS_PROXY` there before your first launch - see the comments in that
   file.

## Day-to-day workflow

- **Made a config change and want it on both machines?**
  ```powershell
  cd $env:LOCALAPPDATA\nvim
  git add -A
  git commit -m "describe the change"
  git push
  ```
  Then on the *other* machine:
  ```powershell
  cd $env:LOCALAPPDATA\nvim
  git pull
  ```
  Restart Neovim afterwards; lazy.nvim will install/remove plugins to match
  whatever changed.

- **Added a new plugin file under `lua/plugins/`?** Nothing else to do -
  lazy.nvim scans that directory automatically on the next launch.

## Keybindings

Leader key is `<space>`. Press it in normal mode and pause: a
[which-key](https://github.com/folke/which-key.nvim) popup shows every
available keybinding below it, grouped by prefix, so you don't need to
memorize this list. A few worth knowing up front:

| Key | Action |
| --- | --- |
| `<space>ff` | Find files |
| `<space>fg` | Live grep (search text across files) |
| `<space>fb` | Switch buffers |
| `<space>w` | Save |
| `<space>q` | Quit window |
| `gd` | Go to definition (when a language server is attached) |
| `K` | Hover documentation |
| `gcc` | Comment/uncomment current line |
| `<C-h/j/k/l>` | Move between split windows |

## Troubleshooting

- **`:TSUpdate` or treesitter install errors on Windows**: nvim-treesitter
  needs a C compiler to build parsers. Install one, e.g.
  `winget install zig.zig`, restart Neovim, and run `:TSUpdate` again.
- **`powershell_es` (the PowerShell language server) doesn't start**: give
  Mason a minute on first use - run `:Mason` to watch its install progress
  and check for errors.
- **Corporate firewall blocks GitHub**: plugin installs (via lazy.nvim) and
  language server installs (via Mason) both need to reach GitHub over
  git/https. If that's blocked at work, set up the proxy in
  `lua/local.lua` (see step 5 above) or ask IT for an exception for
  `github.com`.
