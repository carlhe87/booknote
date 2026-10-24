# Neovim setup guide: packages for org notes (Windows)

Step-by-step instructions to rebuild my Neovim note-taking setup on a new
machine. Built on Neovim 0.12's built-in plugin manager `vim.pack`.

## 0. The model in one sentence

A plugin is a folder; `pack/*/start` loads always, `pack/*/opt` waits for
`:packadd`; `vim.pack.add()` in `init.lua` clones into `site\pack\core\opt\`
and runs `packadd` for me, so **`init.lua` is the single source of truth**.

---

## 1. Install the tools

| Tool | Why | With winget | Without winget (work PC) |
|---|---|---|---|
| Neovim ≥ 0.12 | `vim.pack` needs 0.12 | `winget install Neovim.Neovim` | `nvim-win64.zip` from Neovim's GitHub releases |
| Git | `vim.pack` downloads plugins with git | `winget install Git.Git` | Software Center / portable Git |
| ripgrep (`rg`) | Fast text search across notes | `winget install BurntSushi.ripgrep.MSVC` | zip from ripgrep's GitHub releases |
| C compiler (zig) | orgmode compiles its org parser | `winget install zig.zig` | zip from ziglang.org |

Check exact winget IDs with `winget search <name>` if one fails.

**Work computer:** check Software Center / Company Portal and IT rules first.
For portable zips: unpack into `C:\Users\<me>\tools\...` and add the folder
containing the `.exe` to the **user** PATH (no admin needed):

```powershell
$p = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$p;C:\Users\<me>\tools\zig", "User")
```

**Set the locale once** (fixes the checkhealth UTF-8 error):

```powershell
[Environment]::SetEnvironmentVariable("LANG", "en_US.UTF-8", "User")
```

After any PATH/environment change: **close the terminal app completely** and
reopen it (new tabs keep the old environment). Then verify:

```powershell
nvim --version   # 0.12 or newer
git --version
rg --version
zig version
```

---

## 2. Safety first

**Back up an existing config:**

```powershell
Copy-Item "$env:LOCALAPPDATA\nvim" "$env:LOCALAPPDATA\nvim-backup-<date>" -Recurse
```

(No output = success. Check with `Get-ChildItem <path>`.)

**Try changes in a sandbox** that can't touch the real config:

```powershell
$env:NVIM_APPNAME = "nvim-lab"   # this PowerShell window only
nvim
```

- Config: `...\AppData\Local\nvim-lab\` · Data: `...\AppData\Local\nvim-lab-data\`
- Am I in the sandbox? `:echo $NVIM_APPNAME` (empty = real config)
- Leave it: `Remove-Item Env:NVIM_APPNAME` or close the window
- Tip: put `vim.cmd.colorscheme('desert')` in the sandbox `init.lua` only, to
  see at a glance where I am

**Roll back Neovim** if an upgrade breaks things:

```powershell
winget install Neovim.Neovim --version <old-version>
```

---

## 3. Create the config file

Inside Neovim:

```vim
:call mkdir(stdpath('config'), 'p')
:execute 'edit' stdpath('config') .. '/init.lua'
```

(`mkdir` avoids `E212: Can't open file for writing` when the folder is missing.
After the next restart, `:e $MYVIMRC` opens this file directly.)

---

## 4. The full `init.lua`

Adjust the two org paths. Add sections **one at a time**, restarting and
checking after each (step 5).

```lua
-- =====================================================================
-- Basics (must come before plugins and keymaps)
-- =====================================================================
vim.g.mapleader = ' '          -- SPC as leader, like Doom
vim.opt.shellslash = true      -- '/' in paths; orgmode links need this on Windows

-- =====================================================================
-- Plugins
--   Update:  :lua vim.pack.update()   (review buffer before applying)
--   Remove:  delete the line below AND :lua vim.pack.del({ 'name' })
--   Help:    :h vim.pack
-- =====================================================================
vim.pack.add({
  'https://github.com/nvim-orgmode/orgmode',
  'https://github.com/nvim-mini/mini.pick',
  'https://github.com/nvim-mini/mini.files',
  'https://github.com/nvim-mini/mini.extra',
  'https://github.com/folke/which-key.nvim',
})

-- =====================================================================
-- Orgmode: outline, folding, TODOs
--   In an org buffer: Tab fold · S-Tab cycle all · cit cycle TODO · g? keymaps
-- =====================================================================
require('orgmode').setup({
  org_agenda_files = '~/org/**/*',
  org_default_notes_file = '~/org/refile.org',
})

-- =====================================================================
-- mini.pick: fuzzy finder
--   Space-separated words match in ANY order (custom match below).
--   In picker: S-Tab = all keys · Tab = preview · C-e = refine
-- =====================================================================
local pick = require('mini.pick')

local match_any_order = function(stritems, inds, query)
  local prompt = table.concat(query)
  local words = vim.split(prompt, '%s+', { trimempty = true })
  if #words <= 1 then
    return pick.default_match(stritems, inds, query)
  end
  for _, word in ipairs(words) do
    local chars = vim.fn.split(word, '\\zs')  -- umlaut-safe
    inds = pick.default_match(stritems, inds, chars, { sync = true })
  end
  return inds
end

pick.setup({
  mappings = { refine = '<C-e>' },   -- <C-Space> doesn't reach Neovim on my Windows
  source   = { match = match_any_order },
})

require('mini.files').setup()   -- edit directories like buffers, then save
require('mini.extra').setup()   -- extra pickers (keymaps, ...)
require('which-key').setup()    -- popup after SPC, like Doom

-- =====================================================================
-- Keymaps (desc = text shown in which-key)
-- =====================================================================
local map = vim.keymap.set
map('n', '<leader>.',  '<cmd>Pick files<cr>',     { desc = 'Find file' })
map('n', '<leader>sp', '<cmd>Pick grep_live<cr>', { desc = 'Search text' })
map('n', '<leader>bb', '<cmd>Pick buffers<cr>',   { desc = 'Switch buffer' })
map('n', '<leader>hh', '<cmd>Pick help<cr>',      { desc = 'Search help' })
map('n', '<leader>hk', '<cmd>Pick keymaps<cr>',   { desc = 'Search keymaps' })
map('n', '<leader>e',  function() MiniFiles.open() end, { desc = 'File explorer' })
```

Pickers search the **current directory**: `:cd ~/org` first.

---

## 5. First start and verification

1. Start Neovim and confirm the `vim.pack` install prompt.
2. **Restart** before trusting any health check (stale results are common
   right after installing).
3. Run the checks:

```vim
:checkhealth vim.health
:checkhealth orgmode
```

4. If orgmode says the grammar is missing:
   `:Org install_treesitter_grammar`, then restart and check again.
5. Test on **copies** of a few notes first: folding, TODO cycling, `SPC .`,
   `SPC s p`, `SPC` popup.
6. Only then point the org paths at the real notes folder.

---

## 6. Troubleshooting

**Narrow it down layer by layer:**

1. On disk? → look in `<stdpath('data')>\site\pack\core\opt\`
2. Loaded? → `:scriptnames`
3. Keys registered? → `:nmap <keys>`, and `:verbose nmap <keys>` shows which file defined it
4. Keystrokes reaching Neovim? → Insert mode, `Ctrl-V` then the key

| Symptom | Cause / fix |
|---|---|
| `E212: Can't open file for writing` | Folder missing → `:call mkdir(stdpath('config'), 'p')` |
| checkhealth: locale doesn't support UTF-8 | Set `LANG` (step 1), fully restart the terminal app |
| orgmode: "Failed to compile parser" | No C compiler on PATH → install zig |
| orgmode: "Failed to move … parser … Access is denied" | Windows locks loaded files: quit **all** Neovim windows, start fresh **without** opening an `.org` file, rerun. If it persists, antivirus/policy may block new `.dll` files |
| orgmode: "Setup not called" with settings ✅ | Usually stale: restart, open an `.org` file, recheck |
| `<C-Space>` does nothing in picker | Windows/terminal swallows it → remap (`refine = '<C-e>'`) |
| A key like `"` seems ignored | Dead key on keyboard layout → `"` + Space |
| Two plugins on the same key | Last definition in `init.lua` wins; check with `:verbose nmap` |
| git: "Filename too long" when installing | `git config --global core.longpaths true`, then reinstall |
| `$MYVIMRC` empty | No config file existed when Neovim started → restart |

---

## 7. Optional: Telescope (for comparison)

Needs plenary as a dependency (`vim.pack` doesn't resolve dependencies):

```lua
vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
})
require('telescope').setup({})
local tb = require('telescope.builtin')
vim.keymap.set('n', '<leader>tf', tb.find_files, { desc = 'Telescope files' })
vim.keymap.set('n', '<leader>tg', tb.live_grep,  { desc = 'Telescope grep' })
```

- Use a separate `<leader>t` prefix to avoid colliding with mini.pick keys.
- Skip `telescope-fzf-native` (needs compiling) unless fzf-style
  any-order search in Telescope is really needed.
- Decide on one picker, then remove the other with `vim.pack.del()`.

---

## 8. Next steps

- [ ] org-roam.nvim (`https://github.com/chipsenkbeil/org-roam.nvim`), added
      after orgmode works; test on **copies** of Doom notes first (each editor
      keeps its own index)
- [ ] Decide mini.pick vs Telescope

## Help commands

| Command | Shows |
|---|---|
| `:h packages` | The `pack/start/opt` system |
| `:h vim.pack` | Built-in plugin manager |
| `:h MiniPick` · `:h orgmode` | Plugin docs |
| `:checkhealth <plugin>` | What a plugin is missing |
| `SPC h h` / `SPC h k` | Fuzzy-search help / keymaps |
