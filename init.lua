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

-- Keymaps --------------------------------------------------------------------
local map = vim.keymap.set

map('n', '<leader>.',  '<cmd>Pick files<cr>',           { desc = 'Find file' })
map('n', '<leader>sp', '<cmd>Pick grep_live<cr>',       { desc = 'Search text' })
map('n', '<leader>bb', '<cmd>Pick buffers<cr>',         { desc = 'Switch buffer' })
map('n', '<leader>hh', '<cmd>Pick help<cr>',            { desc = 'Search help' })
map('n', '<leader>hk', '<cmd>Pick keymaps<cr>',         { desc = 'Search keymaps' })
map('n', '<leader>e',  function() MiniFiles.open() end, { desc = 'File explorer' })
map('n', '<leader>gg', '<cmd>Neogit<cr>',               { desc = 'Neogit' })
