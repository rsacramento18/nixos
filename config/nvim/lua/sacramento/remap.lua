vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "Y", "yg$")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "<leader>h", "zHzz")
vim.keymap.set("n", "<leader>l", "zLzz")

vim.keymap.set("x", "<leader>p", "\"_dP")
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", ":silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format()
end)

vim.keymap.set("n", "<C-down>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-up>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<C-left>", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<C-right>", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set("n", "<leader>+", ":vertical resize +20<CR>")
vim.keymap.set("n", "<leader>-", ":vertical resize -20<CR>")
vim.keymap.set("n", "<leader>rp", ":vertical resize 100<CR>")

vim.keymap.set("n", "<leader>h+", ":horizontal resize +20<CR>")
vim.keymap.set("n", "<leader>h-", ":horizontal resize -20<CR>")

vim.keymap.set("n", "<leader>t", ":terminal<CR>")
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")

vim.keymap.set("n", "<C-t>", ":tab split<CR>")
