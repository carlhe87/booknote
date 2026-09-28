return {
  {
    -- gcc to comment/uncomment a line, gc in visual mode for a selection
    "numToStr/Comment.nvim",
    opts = {},
  },
  {
    -- Auto-closes brackets/quotes
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    -- Git status in the sign column (added/changed/removed lines), plus
    -- :Gitsigns blame_line, hunk staging, etc.
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
}
