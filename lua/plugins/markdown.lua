-- Renders markdown (headings, lists, code blocks, tables) inline as you edit,
-- useful for note-taking files. Pure Lua + tree-sitter, no Node/npm required.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown" },
  opts = {},
}
