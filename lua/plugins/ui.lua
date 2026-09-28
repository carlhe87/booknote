return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },
  {
    -- Pops up a menu of available keymaps whenever you pause after pressing
    -- a prefix key (like <leader>). The main way you'll "discover" this
    -- config instead of memorizing it.
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
}
