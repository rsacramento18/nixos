require("sacramento.remap")
require("sacramento.lazy")
require("sacramento.set")

local augroup = vim.api.nvim_create_augroup
local SacramentoGroup = augroup('Sacramento', {})

local autocmd = vim.api.nvim_create_autocmd

autocmd('BufEnter', {
  group = SacramentoGroup,
  pattern = ".env*",
  command = [[set filetype=sh]],
})

autocmd('LspAttach', {
  group = SacramentoGroup,
  callback = function(e)
    local opts = { buffer = e.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>vq", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<leader>va", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ff", vim.lsp.buf.format, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

    vim.keymap.set('v', '<leader>va', vim.lsp.buf.code_action, { buffer = e.buf, desc = 'Lsp: code_action' })
  end,
})
