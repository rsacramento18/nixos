return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "L3MON4D3/LuaSnip",
      "j-hui/fidget.nvim",
    },

    config = function()
      require("fidget").setup({})
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          'ts_ls',
          'eslint',
          'jsonls',
          'vue_ls',
        },
        automatic_enable = true,
      })

      local vue_language_server_path = vim.fn.expand '$MASON/packages' ..
          '/vue-language-server' .. '/node_modules/@vue/language-server'

      vim.lsp.enable("rust_analyzer")
      vim.lsp.enable("lua_ls")   -- binary lua-language-server is on PATH
      vim.lsp.enable("gopls")
      vim.lsp.enable("clangd")
      
      vim.lsp.config('ts_ls', {
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vue_language_server_path,
              languages = { "vue" },
            },
          },
        },
        filetypes = {
          "javascript",
          "typescript",
          "javascriptreact",
          "typescriptreact",
          "vue",
        },
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim", "awesome" },
            }
          }
        }
      })

      vim.lsp.config('eslint', {
        on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
        cmd = { 'pnpm', 'exec', 'eslint', '--stdin' },
        settings = {
          workingDirectories = { { mode = 'auto' } },
          codeActionOnSave = {
            enable = true,
            mode = "all"
          },
          useEslintClass = true,
        }
      })

      vim.lsp.config('gopls', {
        on_attach = function(client, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "lua vim.lsp.buf.format()",
          })
        end,
        settings = {
          gopls = {
            gofumpt = true,
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            }
          }
        }
      })

      vim.diagnostic.config({
        virtual_text = true,
        update_in_insert = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        }
      })
    end,
  },
}
