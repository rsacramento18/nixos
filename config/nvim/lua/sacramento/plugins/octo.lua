return {
  'pwntester/octo.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    -- OR 'ibhagwan/fzf-lua',
    -- OR 'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require "octo".setup({
      keys = {
        { "<localleader>gd", "<cmd>Octo goto_file<CR>", desc = "Go to file (Octo)", ft = "octo" }, goto_file = { lhs = "gd", desc = "go to file" },
      }
    })
  end
}
