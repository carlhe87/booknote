-- Syntax highlighting and code understanding via tree-sitter parsers.
--
-- NOTE for Windows: building parsers requires a C compiler. If `:TSUpdate`
-- fails with a compiler error, install one first, e.g.:
--   winget install zig.zig
-- then restart Neovim (nvim-treesitter will find `zig cc` automatically).
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "vimdoc",
      "query",
      "markdown",
      "markdown_inline",
      "powershell",
      "bash",
      "json",
      "yaml",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
