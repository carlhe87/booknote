-- Entry point. Neovim loads this file automatically when this whole repo is
-- your config directory (~/.config/nvim on Linux/macOS, %LOCALAPPDATA%\nvim
-- on Windows). See README.md for how that's wired up.

-- Leader key must be set before lazy.nvim (and the plugins it loads) so that
-- any leader-based keymaps plugins register use the right key.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.keymaps")
require("core.autocmds")
require("unicode") -- insert-mode abbreviations, e.g. ;mu -> mu, ;pm -> +/-

-- ============================================================================
-- lazy.nvim bootstrap: on first run, clone the plugin manager itself, then
-- hand off to it. This means a fresh machine only needs `git clone` + `nvim`;
-- everything else installs itself.
-- ============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- Every file under lua/plugins/ returns a plugin spec (or list of specs);
    -- lazy.nvim imports them all automatically.
    { import = "plugins" },
  },
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = false }, -- don't auto-check for plugin updates in the background
})

-- Machine-specific overrides (proxy settings, local paths, etc.) that should
-- never be committed. See lua/local.lua.example.
pcall(require, "local")
