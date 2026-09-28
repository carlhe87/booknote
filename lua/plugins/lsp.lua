-- Language servers: diagnostics, go-to-definition, hover docs, rename, etc.
-- mason.nvim installs the servers themselves (no need to hand-install anything);
-- mason-lspconfig wires them into nvim-lspconfig.
return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      -- lua_ls: for editing this very config, and any other Lua scripts
      -- powershell_es: for your PowerShell automation scripts
      ensure_installed = { "lua_ls", "powershell_es" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keymaps that only apply in buffers with an active language server
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP keymaps",
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Goto definition")
          map("gr", vim.lsp.buf.references, "Goto references")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
        end,
      })

      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            -- Recognize the `vim` global so lua_ls doesn't warn about it
            -- everywhere in this config.
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      require("lspconfig").powershell_es.setup({
        capabilities = capabilities,
      })
    end,
  },
}
