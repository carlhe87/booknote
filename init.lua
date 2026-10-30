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
