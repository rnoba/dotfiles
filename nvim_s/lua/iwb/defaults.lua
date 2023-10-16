-- vim.cmd [[ colorscheme gruvbox ]]
-- vim.cmd [[highlight Normal ctermbg=16 guibg=#000000]]
vim.api.nvim_exec2([[
    let g:gruvbox_contrast_dark = 'hard'
    let g:gruvbox_colors = { 'bg0': ['#000000', 0] }
    colorscheme gruvbox
]], {})

vim.cmd [[ set winbar=%t\ \%m\ \ \ Row:\ %l\ Col:\ %v\ (Pointing:\ (%B'%b')\ Byte\ Offset:\ %o) ]]
vim.cmd [[ hi winbar guibg=#000000 ]]
vim.cmd [[ set laststatus=0 ]]
vim.cmd [[ set noru ]]

vim.api.nvim_exec2([[
    function! OpenMarkdownPreview(url)
	execute 'silent ! firefox --new-window ' . a:url
    endfunction
]], {})

vim.g.mkdp_browserfunc = 'OpenMarkdownPreview'
vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.config/vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "no"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
-- vim.opt.colorcolumn = ""
vim.g.mapleader = " "
