return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    {
      'tpope/vim-dadbod',
      update = false,
      lazy = true
    },
    {
      'kristijanhusak/vim-dadbod-completion',
      ft = { 'sql', 'mysql', 'plsql' },
      lazy = true
    },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
  },
  config = function()
    vim.keymap.set("n", "<leader>db", ":DBUIToggle<CR>")
  end,
}
