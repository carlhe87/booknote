return {
  "folke/tokyonight.nvim",
  lazy = false, -- load at startup since it's the colorscheme
  priority = 1000, -- load before other plugins
  config = function()
    vim.cmd.colorscheme("tokyonight")
  end,
}
