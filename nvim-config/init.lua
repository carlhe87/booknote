-- Options --------------------------------------------------------------------
vim.g.mapleader = ' '   -- SPC as leader, like Doom (must come before keymaps)
vim.opt.shellslash = true
vim.cmd.colorscheme('default')
vim.opt.autoread = true  -- reload files changed outside nvim (e.g. by Claude Code)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, { command = 'checktime' })
vim.opt.ignorecase = true  -- case-insensitive search (/, ?, *, :s)
vim.opt.smartcase  = true  -- ...unless the pattern has a capital letter

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
  'https://github.com/nvim-telescope/telescope.nvim',   -- preferred over mini.pick
})

require('orgmode').setup({
  org_agenda_files = { '~/proj/notes/**/*' },  -- nvim only track this folder
  org_default_notes_file = '~/proj/notes/todo.org', -- nvim not track refile.org
  -- states named as in Doom Emacs; after | they count as closed
  org_todo_keywords = { 'TODO(t)', 'STRT(s)', 'WAIT(w)', '|', 'DONE(d)', 'KILL(k)' },
  org_todo_keyword_faces = {
    STRT = ':foreground #e5c07b :weight bold',   -- in progress
    WAIT = ':foreground #c678dd :weight bold',   -- waiting on others / a process
    KILL = ':foreground #e06c75 :slant italic',  -- cancelled
  },
  org_hide_emphasis_markers = true,          -- hide * / ~ = markers (needs conceallevel)
  -- agenda view (see ../notes/nvim-orgmode.org)
  org_agenda_span = 'week',
  org_agenda_start_on_weekday = 1,           -- week starts on Monday
  org_deadline_warning_days = 5,             -- default 14 crowds the agenda
  org_agenda_skip_scheduled_if_done = true,
  org_agenda_skip_deadline_if_done = true,
  org_agenda_custom_commands = {
    n = {
      description = 'Next: today + undated TODOs',
      types = {
        { type = 'agenda', org_agenda_span = 'day' },
        { type = 'tags_todo', match = '-wish/-WAIT',
          org_agenda_todo_ignore_scheduled = 'all',
          org_agenda_overriding_header = 'Unscheduled' },
        { type = 'tags_todo', match = '/WAIT',
          org_agenda_overriding_header = 'Waiting' },
      },
    },
  },
})

-- org: show link descriptions instead of [[target][desc]], hide emphasis markers
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nc'  -- concealed on the cursor line too, except insert/visual
  end,
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

map('n', '<leader>cd', '<Cmd>cd %:h<CR><Cmd>pwd<CR>',   { desc = 'cd to current file folder' })

-- Telescope (preferred: instant preview) under SPC f
map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find file' })
map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>',  { desc = 'Search text' })
map('n', '<leader>fb', '<cmd>Telescope buffers<cr>',    { desc = 'Switch buffer' })
map('n', '<leader>fo', '<cmd>Telescope oldfiles<cr>',   { desc = 'Recent files' })
-- Doom Emacs shortcuts
map('n', '<leader>,', '<cmd>Telescope buffers<cr>',     { desc = 'Switch buffer' })
map('n', '<leader>.', function()
  require('telescope.builtin').find_files({ cwd = vim.fn.expand('%:p:h') })
end,                                                    { desc = 'Find file in this folder' })

-- mini.pick under SPC t: same second letter = same job as SPC f
map('n', '<leader>tf', '<cmd>Pick files<cr>',           { desc = 'Pick files' })
map('n', '<leader>te', '<cmd>Pick explorer<cr>',        { desc = 'Pick folder' })
map('n', '<leader>tg', '<cmd>Pick grep_live<cr>',       { desc = 'Pick grep' })
map('n', '<leader>tb', '<cmd>Pick buffers<cr>',         { desc = 'Pick buffers' })
map('n', '<leader>to', '<cmd>Pick oldfiles<cr>',        { desc = 'Pick recent files' })

map('n', '<leader>hh', '<cmd>Telescope help_tags<cr>',  { desc = 'Search help' })
map('n', '<leader>hk', '<cmd>Telescope keymaps<cr>',    { desc = 'Search keymaps' })
map('n', '<leader>e',  function() MiniFiles.open() end, { desc = 'File explorer' })
map('n', '<leader>gg', '<cmd>Neogit<cr>',               { desc = 'Neogit' })

-- Image viewer: local plugin in pack/local/opt/image-viewer, added on first use
-- (see ../notes/nvim-images.org)
-- vim.g.image_viewer = 'chafa'   -- WT pane instead of the default WPF window
map('n', '<leader>iv', function()
  vim.cmd.packadd('image-viewer')
  require('image-viewer').toggle()
end, { desc = 'Toggle image viewer' })

-- PowerShell in Neovim
-- Open PowerShell in a horizontal split
vim.keymap.set("n", "<leader>th", ":split | terminal powershell<CR>", { desc = 'Terminal in horizontal split' })
-- Open PowerShell in a vertical split
vim.keymap.set("n", "<leader>tv", ":vsplit | terminal powershell<CR>", { desc = 'Terminal in vertical split' })
-- Exit terminal input mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = 'Exit terminal mode' })
