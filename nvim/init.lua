vim.g.mapleader = ','
vim.g.maplocalleader = ','
vim.opt.relativenumber = true
vim.opt.undofile = true
vim.opt.guicursor = ""

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.expandtab = false 
vim.opt.smartindent = true 
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 10
vim.opt.updatetime = 1000 
vim.opt.signcolumn = 'no'

vim.opt.laststatus = 2
vim.opt.backup=false
vim.opt.writebackup=false
vim.opt.swapfile=false
vim.opt.wrap=false;
vim.opt.ttimeoutlen=0
vim.opt.ttyfast=true
vim.opt.lazyredraw=true
vim.o.background = 'dark'
vim.api.nvim_set_option("clipboard","unnamed")
vim.keymap.set('v', '<leader>y', '"+y<CR>', {silent = true,noremap=true})

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		'nvim-telescope/telescope.nvim',
		branch = '0.1.x',
		treesitter = false,
		dependencies = {
			'nvim-lua/plenary.nvim',
			{
				'nvim-telescope/telescope-fzf-native.nvim',
				build = 'make',
				cond = function()
					return vim.fn.executable 'make' == 1
				end,
			},
		},
		config = function()
			pcall(require('telescope').load_extension, 'fzf')

			local builtin = require 'telescope.builtin'
			vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
			vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
			vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
			vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
			vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
			vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
			vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
			vim.keymap.set('n', '<leader><leader>.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
		end,
	},
	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = {
			{
				"<leader>xa",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
		},
	},
	{
		'neovim/nvim-lspconfig',
		config = function()
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
					end
					map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
					map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
					map('gu', require('telescope.builtin').lsp_implementations, '[g]oto [i]mplementation')
					map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
					map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
					map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
					map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
					map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
				end
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()

			local servers = {
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"-j=12",
						"--query-driver=/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
						"--clang-tidy",
						"--resource-dir=/usr/lib/clang/18",
						"--enable-config",
						"--all-scopes-completion",
						"--cross-file-rename",
						"--completion-style=detailed",
						"--header-insertion-decorators",
						"--header-insertion=iwyu",
						"--pch-storage=memory",
					},
					InlayHints = {
						enabled = false
					}
				},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = 'Replace',
							},
						},
					},
				},
			}

			vim.diagnostic.config { virtual_text = false, signs = true, underline = false }
			local lspconfig = require('lspconfig')
			setup = function(server_name)
				local server = servers[server_name] or {}
				server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
				lspconfig[server_name].setup(server)
			end

			setup("clangd");
			setup("ts_ls");
			-- setup("ast_grep");
			-- setup("zls");
			-- setup("kotlin_language_server");
			-- setup("ocamllsp");
			setup("pylsp");
			setup("gopls");
		end,
	},
	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',
		},
		config = function()
			local cmp = require 'cmp'

			cmp.setup {
				completion = { autocomplete = false, completeopt = 'menu,menuone,noinsert' },
				mapping = cmp.mapping.preset.insert {
					['<C-n>'] = cmp.mapping.select_next_item(),
					['<C-p>'] = cmp.mapping.select_prev_item(),

					-- ['<C-b>'] = cmp.mapping.scroll_docs(-4),
					-- ['<C-f>'] = cmp.mapping.scroll_docs(4),

					['<C-y>'] = cmp.mapping.confirm { select = true },
					['<C-b>'] = cmp.mapping(cmp.mapping.complete({
						reason = cmp.ContextReason.Auto,
					}), {"i", "c"}), 
				},
				sources = {
					{
						name = 'lazydev',
						group_index = 0,
					},
					{ name = 'nvim_lsp' },
					{ name = 'path' },
				},
			}
		end,
	},
	{
		'nvim-treesitter/nvim-treesitter',
		build = ':TSUpdate',
		main = 'nvim-treesitter.configs',
		opts = {
			ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { 'ruby' },
			},
			indent = { enable = false, disable = { 'ruby' } },
		},
	},
	{
		"ellisonleao/gruvbox.nvim", config = function()
			require("gruvbox").setup({
				terminal_colors = true,
				contrast = "hard",
				palette_overrides = {
					dark0_hard = "#181818",
				}
			})
		end
	},
	{
		"stevearc/conform.nvim", config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					rust = { "rustfmt", lsp_format = "fallback" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
				},
			})
		end
	}
})


vim.cmd [[colorscheme gruvbox]]
vim.cmd [[set statusline=%y\ %F\ \%M\ %R\ \%q\ %=Line:\ %l\ Column:\ %v\ (%B'%b')\ Byte\ Offset:\ %o)]]
vim.cmd [[hi StatusLine guifg=#181818 guibg=#deb887]]
vim.cmd [[hi LineNr term=bold ctermfg=50 guifg=#4F4F4F]]
vim.cmd [[hi Pmenu ctermbg=7 guibg=#252528]]
vim.cmd [[hi NormalFloat guifg=#ffffff guibg=#181818]]

vim.cmd [[autocmd BufNewFile,BufRead *.asm, :set makeprg=./build]]
vim.cmd [[autocmd BufNewFile,BufRead *.s, :set makeprg=./build]]
vim.cmd [[autocmd BufNewFile,BufRead *.cpp, :set makeprg=./build]]
vim.cmd [[autocmd BufNewFile,BufRead *.c, :set makeprg=./build]]

build_generic = function(debug)
	debug = debug or false
	local cwd = vim.fn.getcwd()
	local build_file = vim.fn.glob(cwd .. '/' .. "build", false, false)

	if #build_file > 0 then
		vim.cmd('!' .. "./build")
	else
		local c_entry = vim.fn.glob(cwd .. '/' .. "main.c", false, false)
		assert(c_entry, "no 'main.c' found");
		vim.cmd('!' .. "cc $CFLAGS main.c && ./a.out")
	end
end

vim.keymap.set('n', '<leader>b', function() build_generic(false) end, { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<leader>f', function() require("conform").format({ async = true }) end, { desc = 'Move focus to the left window' })
