return {
  'nvim-telescope/telescope.nvim',
  version = '*',
  dependencies = {
    "nvim-lua/plenary.nvim",
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    local telescope = require('telescope');
    local builtin = require('telescope.builtin');

    telescope.setup({
      defaults = {
        layout_strategy = 'vertical',
        selection_caret = " ❯ ",
        entry_prefix = "   ",
        preview = {
          treesitter = true,
        },
        mappings = {
          i = {
            ["<C-x>"] = false,
            ["<C-q>"] = require('telescope.actions').send_to_qflist,
          },
        }
      },
    })

    require('telescope').load_extension('fzf')

    vim.keymap.set("n", "<leader>vh", builtin.help_tags, {})
    vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
    vim.keymap.set("n", "<C-p>", builtin.git_files, {})
    vim.keymap.set("n", "<C-s>", function()
      builtin.live_grep({
        additional_args = function(opts)
          return { "--hidden" }
        end
      })
    end)

    vim.keymap.set("n", "<leader>pb", builtin.buffers, {})
    vim.keymap.set("n", "<leader>ps", function()
      builtin.grep_string({
        search = vim.fn.input("Grep all projects > "),
        cwd = "~/work",
        additional_args = function(opts)
          return { "--hidden" }
        end
      })
    end)

    vim.keymap.set("n", "<leader>pw", function()
      local word = vim.fn.expand("<cword>")
      builtin.grep_string({ search = word })
    end)

    vim.keymap.set("n", "<leader>pW", function()
      local word = vim.fn.expand("<cWORD>")
      builtin.grep_string({ search = word })
    end)

    vim.keymap.set("n", "<leader>pn", function()
      require("telescope").extensions.monorepo.monorepo()
    end, { desc = "Nx project" })

    vim.keymap.set("n", "<leader>pm", function()
      require("monorepo").toggle_project()
    end, { desc = "Toggle project" })
  end,
}
