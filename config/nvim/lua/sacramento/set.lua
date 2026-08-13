vim.cmd [[set termguicolors]]
vim.opt.termguicolors = true

vim.opt.termsync = false

vim.opt.inccommand = "split"

vim.opt.guicursor = "i:ver1"

vim.o.cursorline = false

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.clipboard = "unnamed"

-- Global statusbar
vim.opt.laststatus = 3

vim.opt.errorbells = false

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true
vim.opt.foldenable = false

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 16
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"
vim.opt.isfname:append("@-@")

vim.opt.encoding = "UTF-8"

-- Give more space for displaying messages
vim.opt.cmdheight = 1

-- Having longer updatetime (default is 4000 ms = 4 s) lead to noticeable
-- delays and poor user experience
vim.opt.updatetime = 50

-- Don't pass messages to |ins-completion-menu|
vim.opt.shortmess:append("c")

vim.g.mapleader = " "
vim.g.maplocalleader = " "
