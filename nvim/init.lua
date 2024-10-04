vim.g.mapleader = ','
vim.g.maplocalleader = ','

vim.opt.relativenumber = true
vim.opt.undofile = true

vim.opt.guicursor = ""
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false 

vim.opt.smartindent = false 

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.updatetime = 1000 
vim.opt.signcolumn = 'no'

vim.opt.scrolloff = 10

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
		event = 'VimEnter',
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
			require('telescope')
			pcall(require('telescope').load_extension, 'fzf')

			local builtin = require 'telescope.builtin'
			vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
			vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
			vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
			vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
			vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
			vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
			vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
			vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
			vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

			vim.keymap.set('n', '<leader>s/', function()
				builtin.live_grep {
					grep_open_files = true,
					prompt_title = 'Live Grep in Open Files',
				}
			end, { desc = '[S]earch [/] in Open Files' })

			vim.keymap.set('n', '<leader>sn', function()
				builtin.find_files { cwd = vim.fn.stdpath 'config' }
			end, { desc = '[S]earch [N]eovim files' })
		end,
	},
	{
		"folke/trouble.nvim",
		opts = {},
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
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
					map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
					map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
					map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
					map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
					map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
					map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
					map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
				end
			})

	local capabilities = vim.lsp.protocol.make_client_capabilities()

			local servers = {
				zls = { },
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"-j=12",
						"--query-driver=/usr/bin/**/clang-*,/bin/clang,/bin/clang++,/usr/bin/gcc,/usr/bin/g++",
						"--clang-tidy",
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

			vim.diagnostic.config { virtual_text = false, signs = false, underline = false }

			local lspconfig = require('lspconfig')

			setup = function(server_name)
				local server = servers[server_name] or {}
				server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
				require('lspconfig')[server_name].setup(server)
			end

			setup("clangd");
			setup("zls");
			setup("kotlin_language_server");
			setup("ocamllsp");
		end,
	},
	{
		'p00f/clangd_extensions.nvim',
		config = function() 
			require("clangd_extensions").setup({
				inlay_hints = {
					inline = vim.fn.has("nvim-0.10") == 1,
					only_current_line = false,
					only_current_line_autocmd = { "CursorHold" },
					show_parameter_hints = true,
					parameter_hints_prefix = "<- ",
					other_hints_prefix = "=> ",
					max_len_align = false,
					max_len_align_padding = 1,
					right_align = false,
					right_align_padding = 7,
					highlight = "Comment",
					priority = 100,
				},
				ast = {
					role_icons = {
						type = "Type",
						declaration = "Decl",
						expression = "Exp",
						statement = "Stmt",
						specifier = "Spec",
						["template argument"] = "🆃",
					},
					kind_icons = {
						Compound = "Comp",
						Recovery = "Rcvr",
						TranslationUnit = "TU",
						PackExpansion = "🄿",
						TemplateTypeParm = "🅃",
						TemplateTemplateParm = "🅃",
						TemplateParamObject = "🅃",
					},
					highlights = {
						detail = "Comment",
					},
				},
				memory_usage = {
					border = "none",
				},
				symbol_info = {
					border = "none",
				},
			})
		end
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

					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),

					['<C-y>'] = cmp.mapping.confirm { select = true },
					['<Leader>c'] = cmp.mapping.complete {},
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
		"ellisonleao/gruvbox.nvim", priority = 1000 , config = function()
			require("gruvbox").setup({
				terminal_colors = true,
				invert_selection = true,
				invert_signs = true,
				invert_tabline = false,
				invert_intend_guides = false,
				inverse = true,
				contrast = "hard",
				palette_overrides = {
					dark0_hard = "#181818",
					dark0 = "#101010",
					dark1 = "#101010",
					dark2 = "#101010",
					dark3 = "#101010",
				}
			})
		end
	}
})

vim.o.background = 'dark'

vim.cmd[[set laststatus=2]]
vim.cmd[[set statusline=%y\ %F\ \%M\ %R\ \%q\ %=Line:\ %l\ Column:\ %v\ (%B'%b')\ Byte\ Offset:\ %o)]]
vim.cmd[[hi StatusLine guifg=#181818 guibg=#deb887]]
vim.cmd[[hi LineNr term=bold ctermfg=50 guifg=#4F4F4F]]
vim.cmd[[hi Pmenu ctermbg=7 guibg=#252528]]
vim.cmd[[set nocursorline]]
vim.cmd[[set nocursorcolumn]]
vim.cmd [[colorscheme gruvbox]]
vim.cmd [[autocmd BufNewFile,BufRead *.asm, :set filetype=nasm]]
vim.cmd [[autocmd BufNewFile,BufRead *.cpp, :set makeprg=./build]]
vim.cmd [[autocmd BufNewFile,BufRead *.c, :set makeprg=./build]]
