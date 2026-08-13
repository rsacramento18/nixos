return {
  {
    "mbbill/undotree",
    config = function()
      vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
    end,
  },
  {
    "norcalli/nvim-colorizer.lua",
  },
  "tpope/vim-commentary",
  "nvim-tree/nvim-web-devicons",
  "yamatsum/nvim-nonicons",
  "L3MON4D3/LuaSnip",
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
  -- {
  --   dir = "~/personal/neovim-plugin/"
  -- }
}
