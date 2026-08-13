return {
  "L3MON4D3/LuaSnip",
  version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  build = "make install_jsregexp",
  dependencies = { "rafamadriz/friendly-snippets" },
  after = 'nvim-cmp',
  config = function()
    local ls = require('luasnip')
    require("luasnip.loaders.from_vscode").lazy_load()
    local snippet = ls.s
    local t = ls.text_node

    ls.config.set_config {
      history = true,
      updateevents = "textChanged,TextChangedI",
      enable_autosnippets = true,
    }

    ls.add_snippets("all", {
      snippet("simple", t "-- this is what was expanded!"),
    })

    vim.keymap.set({ "i", "s" }, "<c-k>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true })

    vim.keymap.set({ "i", "s" }, "<c-j>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true })

    vim.keymap.set("i", "<c-l>", function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end)

    vim.keymap.set("i", "<c-u>", require "luasnip.extras.select_choice")

    vim.keymap.set("n", "<leader><leader>s", "<cmd>source ~/.config/nvim/after/plugin/luasnip.lua<CR>")
  end,
}
