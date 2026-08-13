return {
  "nvim-treesitter/nvim-treesitter",
  build = ':TSUpdate',
  init = function()
    -- nvim-treesitter v2 stores queries in runtime/queries/ instead of queries/
    -- at the plugin root, so we need to add that subdir to runtimepath manually.
    vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime")
  end,
  config = function()
    require('nvim-treesitter').setup()

    -- ensure_installed is no longer part of setup() in nvim-treesitter v2;
    -- check via vim.treesitter so we don't re-install parsers that are already
    -- loadable (e.g. previously installed into the lazy plugin dir).
    local want = { "vim", "javascript", "typescript", "vue", "c", "lua", "rust", "go", "zig", "markdown", "markdown_inline" }
    local to_install = vim.tbl_filter(function(p)
      return not pcall(vim.treesitter.language.add, p)
    end, want)
    if #to_install > 0 then
      require('nvim-treesitter.install').install(to_install)
    end
  end,
}
