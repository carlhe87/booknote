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

This is the same file as `init.lua` in this folder. Adjust the two org paths.
Add sections **one at a time**, restarting and checking after each (step 5).

```lua
-- Options --------------------------------------------------------------------
vim.g.mapleader = ' '   -- SPC as leader, like Doom (must come before keymaps)
vim.opt.shellslash = true
vim.cmd.colorscheme('default')

-- Plugins --------------------------------------------------------------------
vim.pack.add({
  'https://github.com/tpope/vim-surround',
  'https://github.com/nvim-orgmode/orgmode',
  'https://github.com/echasnovski/mini.pick',
  'https://github.com/echasnovski/mini.files',
  'https://github.com/echasnovski/mini.extra',
  'https://github.com/folke/which-key.nvim',
  'https://github.com/nvim-lua/plenary.nvim',   -- required by neogit
  'https://github.com/NeogitOrg/neogit',
  'https://github.com/nvim-telescope/telescope.nvim',   -- trial vs mini.pick
})

require('orgmode').setup({
  org_agenda_files = '~/org/**/*',
  org_default_notes_file = '~/org/refile.org',
})

require('mini.files').setup()
require('mini.pick').setup({
  mappings = {
    refine = '<C-e>',   -- instead of <C-Space>; <C-e> isn't used by mini.pick
  },
})
require('mini.extra').setup()

require('which-key').setup()
require('neogit').setup()
require('telescope').setup()

-- Keymaps --------------------------------------------------------------------
local map = vim.keymap.set

-- mini.pick under SPC f, mirrored by Telescope under SPC t below
map('n', '<leader>ff', '<cmd>Pick files<cr>',           { desc = 'Find file' })
map('n', '<leader>fg', '<cmd>Pick grep_live<cr>',       { desc = 'Search text' })
map('n', '<leader>fb', '<cmd>Pick buffers<cr>',         { desc = 'Switch buffer' })
map('n', '<leader>fo', '<cmd>Pick oldfiles<cr>',        { desc = 'Recent files' })
map('n', '<leader>hh', '<cmd>Pick help<cr>',            { desc = 'Search help' })
map('n', '<leader>hk', '<cmd>Pick keymaps<cr>',         { desc = 'Search keymaps' })
map('n', '<leader>e',  function() MiniFiles.open() end, { desc = 'File explorer' })
map('n', '<leader>gg', '<cmd>Neogit<cr>',               { desc = 'Neogit' })

-- Telescope trial: same second letter = same job as SPC f
map('n', '<leader>tf', '<cmd>Telescope find_files<cr>', { desc = 'Telescope files' })
map('n', '<leader>tg', '<cmd>Telescope live_grep<cr>',  { desc = 'Telescope grep' })
map('n', '<leader>tb', '<cmd>Telescope buffers<cr>',    { desc = 'Telescope buffers' })
map('n', '<leader>to', '<cmd>Telescope oldfiles<cr>',   { desc = 'Telescope recent files' })
```

The file has three parts, in this order:

1. **Options**: the leader must be set before any `<leader>` keymap.
   `shellslash` gives `/` in paths, which orgmode links need on Windows.
2. **Plugins**: one `vim.pack.add({...})` with every plugin, then all
   `setup()` calls. `vim.pack` doesn't resolve dependencies, so plenary is
   listed explicitly for neogit (Telescope needs it too).
3. **Keymaps**: every leader mapping, all through `local map`. The `desc` is
   the text which-key shows. The two pickers mirror each other: `SPC f` is
   mini.pick, `SPC t` is Telescope, and the second letter means the same job
   (`f` files · `g` grep · `b` buffers · `o` recent files).

| Plugin | What it does |
|---|---|
| vim-surround | `ysiw"` surround word · `cs"'` change · `ds"` delete |
| orgmode | In an org buffer: Tab fold · S-Tab cycle all · `cit` cycle TODO · `g?` keymaps |
| mini.pick | Fuzzy finder. In picker: S-Tab = all keys · Tab = preview · C-e = refine (`<C-Space>` doesn't reach Neovim on my Windows) |
| mini.files | Edit directories like buffers, then save |
| mini.extra | Extra pickers (keymaps, recent files, ...) |
| which-key | Popup after SPC, like Doom |
| neogit (+ plenary) | Magit-style git UI on `SPC g g` |
| telescope.nvim | Trial, compared against mini.pick (see step 7) |

Maintaining plugins:

- Update: `:lua vim.pack.update()` (review the buffer before applying)
- Remove: delete the URL from `vim.pack.add` **and** `:lua vim.pack.del({ 'name' })`
- Versions are pinned in `nvim-pack-lock.json` next to `init.lua`
- Help: `:h vim.pack`

Pickers search the **current directory**: `:cd ~/org` first.

### Optional: match words in any order

By default `mini.pick` matches the query left to right. To let
space-separated words match in **any** order, replace the
`require('mini.pick').setup(...)` call with:

```lua
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
  mappings = { refine = '<C-e>' },
  source   = { match = match_any_order },
})
```

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
5. Test on **copies** of a few notes first: folding, TODO cycling, `SPC f f`,
   `SPC f g`, `SPC t f`, `SPC e`, `SPC g g`, `SPC` popup.
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

## 7. Telescope trial (mini.pick vs Telescope)

Telescope is installed next to mini.pick (already in the `init.lua` above).
It uses plenary, which is installed anyway for neogit.

| Job | mini.pick | Telescope |
|---|---|---|
| Find files | `SPC f f` | `SPC t f` |
| Search text (grep) | `SPC f g` | `SPC t g` |
| Switch buffer | `SPC f b` | `SPC t b` |
| Recent files | `SPC f o` | `SPC t o` |

- Same second letter = same job, so the two are easy to compare.
- Skip `telescope-fzf-native` (needs compiling) unless Telescope feels slow
  on big lists or fzf-style search is really needed.
- After the trial, remove the loser: delete its URL, its `setup()` and its
  keys from `init.lua`, then `:lua vim.pack.del({ 'name' })`.

---

## 8. Next steps

- [ ] org-roam.nvim (`https://github.com/chipsenkbeil/org-roam.nvim`), added
      after orgmode works; test on **copies** of Doom notes first (each editor
      keeps its own index)
- [ ] Finish the Telescope trial (step 7) and keep one picker

## Help commands

| Command | Shows |
|---|---|
| `:h packages` | The `pack/start/opt` system |
| `:h vim.pack` | Built-in plugin manager |
| `:h MiniPick` · `:h telescope.nvim` · `:h orgmode` · `:h neogit` | Plugin docs |
| `:checkhealth <plugin>` | What a plugin is missing |
| `SPC h h` / `SPC h k` | Fuzzy-search help / keymaps |
| `SPC g g` | Neogit status |
