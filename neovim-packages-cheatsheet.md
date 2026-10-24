# Neovim package management (cheat sheet)

Neovim 0.12+ on Windows · built from a hands-on session

## Core idea

A plugin is **just a folder** of Lua/Vimscript files. Neovim finds plugins by
folder layout under its data directory:

```
<stdpath('data')>\site\pack\<any-name>\start\<plugin>\   → loaded at every startup
<stdpath('data')>\site\pack\<any-name>\opt\<plugin>\     → dormant until :packadd
```

A plugin manager only automates three jobs:

1. **Fetch:** `git clone` into a `pack/*/` folder
2. **Load:** `packadd` it (deciding *when* = "lazy-loading")
3. **Maintain:** update, remove, pin exact versions in a lockfile

## Finding paths

| Command | Shows |
|---|---|
| `:echo stdpath('data')` | Data folder (plugins live under `site\pack\`) |
| `:echo stdpath('config')` | Config folder (`init.lua` lives here) |
| `:let @+ = stdpath('data')` | Copy a value to the system clipboard |
| `:put =stdpath('data')` | Paste a value into the buffer as text |

## Loading and checking

| Command | Does |
|---|---|
| `:packadd <plugin>` | Load a plugin from an `opt/` folder now |
| `:packloadall` | Load all `start/` plugins (normally automatic) |
| `:scriptnames` | List every script file loaded this session |
| `:nmap <keys>` | Check whether a normal-mode mapping exists |
| `:checkhealth` | Neovim self-diagnosis (look for ERROR lines) |
| `:checkhealth vim.health` | Just the core checks |

## vim.pack (built-in manager, 0.12+)

In `init.lua`:

```lua
vim.pack.add({ 'https://github.com/tpope/vim-surround' })
```

- Clones into `site\pack\core\opt\` and runs `packadd` for you
- Because it's in `opt/`, **`init.lua` is the single source of truth**:
  remove the line → plugin no longer loads
- A lockfile appears in the config folder next to `init.lua` (exact versions,
  for rollback)

| Function | Does |
|---|---|
| `vim.pack.add({...})` | Install (if missing) and load |
| `vim.pack.update()` | Update; shows a review buffer before applying |
| `vim.pack.del({ 'name' })` | Remove plugin files from disk |
| `vim.pack.get()` | Info about installed plugins |

Removing the `add` line stops loading, but **files stay on disk** until `vim.pack.del`.

## Safety net

**Sandbox config** (never touches the real one):

```powershell
$env:NVIM_APPNAME = "nvim-lab"   # this PowerShell session only
nvim
```

Uses `...\AppData\Local\nvim-lab\` (config) and `...\nvim-lab-data\` (data).

**Back up the real config before big changes:**

```powershell
Copy-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim-backup-<date>" -Recurse
```

**Upgrade / roll back Neovim (installed via .msi / winget):**

```powershell
winget upgrade Neovim.Neovim
winget install Neovim.Neovim --version 0.11.4   # go back to a specific version
```

## Troubleshooting checklist

When a plugin "doesn't work", narrow it down layer by layer:

1. **Is it on disk?** Check the `pack\...` folder.
2. **Is it loaded?** `:scriptnames`
3. **Did it register its keys/commands?** `:nmap <keys>`, `:command`
4. **Do my keystrokes reach Neovim?** Normal mode? Typed fast enough
   (about 1 s between keys)? Dead keys on the layout (e.g. `"`)?

## Gotchas met so far

| Symptom | Cause / fix |
|---|---|
| `E212: Can't open file for writing` | Folder doesn't exist → `:call mkdir(stdpath('config'), 'p')` |
| checkhealth: locale doesn't support UTF-8 | `[Environment]::SetEnvironmentVariable("LANG","en_US.UTF-8","User")`, then fully restart the terminal app (new tabs keep the old environment) |
| `ysiw"` does nothing | `"` never reached Neovim (dead key / missed keystroke). Test with `yss)` |
| `Copy-Item` printed nothing | That means success; verify with `Get-ChildItem <path>` |

## Getting help

| Command | Does |
|---|---|
| `:h packages` | The whole `pack/start/opt` system |
| `:h :packadd` · `:h stdpath()` · `:h NVIM_APPNAME` · `:h vim.pack` | Specific topics (`:` = command, `()` = function) |
| `:h pack` + Tab / Ctrl-D | Cycle / list matching topics |
| `Ctrl-]` · `Ctrl-O` | Follow link · jump back |
| `:helpgrep <word>` then `:cnext` / `:cprev` | Full-text search across all help |

## Next steps

- [ ] Pick note-taking plugins (markdown, links between notes, search)
- [ ] Add each with one `vim.pack.add` line in the sandbox, then move to the real config
