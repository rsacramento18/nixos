return {
  {
    "tpope/vim-fugitive",
    config = function()
      vim.keymap.set("n", "<leader>gs", "<cmd>0G<CR>")
      -- vim.keymap.set("n", "<leader>gfc", vim.cmd.Gvdiff);

      local Sacramento_Fugitive = vim.api.nvim_create_augroup("Sacramento_Fugitive", {})

      local autocmd = vim.api.nvim_create_autocmd
      autocmd("BufWinEnter", {
          group = Sacramento_Fugitive,
          pattern = "*",
          callback = function()
              if vim.bo.ft ~= "fugitive" then
                  return
              end

              local bufnr = vim.api.nvim_get_current_buf()
              local opts = {buffer = bufnr, remap = false}

              vim.keymap.set("n", "<leader>p", function()
                  vim.cmd.Git({'pull'})
              end, opts)
              vim.keymap.set("n", "<leader>P", function()
                  vim.cmd.Git('push')
              end, opts)

            end,
          })
          vim.keymap.set("n", "gy", "<cmd>diffget //2<CR>")
          vim.keymap.set("n", "gu", "<cmd>diffget //3<CR>")
      end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({})
      vim.keymap.set("n", "<leader>gm", ":Gitsigns blame_line<CR>");
      vim.keymap.set("n", "<leader>gr", ":Gitsigns reset_hunk<CR>");
      vim.keymap.set("n", "<leader>gg", ":Gitsigns preview_hunk<CR>");
      vim.keymap.set("n", "<leader>gn", ":Gitsigns next_hunk<CR>");
      vim.keymap.set("n", "<leader>gp", ":Gitsigns prev_hunk<CR>");
    end,
  },
  {
    "sindrets/diffview.nvim",
    config = function()
      vim.keymap.set("n", "<leader>gf", vim.cmd.DiffviewFileHistory);
      vim.keymap.set("n", "<leader>gfc", ":DiffviewFileHistory %<CR>");
    end,
  }
}
