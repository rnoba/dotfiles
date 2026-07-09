vim.g.mapleader = ","
vim.g.maplocalleader = ","

vim.g.have_nerd_font = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.relativenumber = true
vim.opt.colorcolumn = "100"

vim.o.mouse = "a"
vim.o.showmode = false

vim.g.netrw_sort_sequence = [[[\/]$,\<core\%(\.\d\+\)\=,\.[a-np-z]$,\.cpp$,*,\.o$,\.obj$,\.info$,\.swp$,\.bak$,\~$]]
vim.g.netrw_sort_by = "name"

vim.opt.wrap = false
vim.opt.backup = false
vim.opt.laststatus = 2
vim.opt.writebackup = false
vim.opt.swapfile = false

vim.o.breakindent = true
vim.o.undofile = true

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.inccommand = "split"

vim.o.scrolloff = 10

vim.opt.clipboard = "unnamed"
vim.opt.cinoptions:append("l1,t0")
vim.opt.completeopt = "menu,menuone,noinsert"

vim.keymap.set("v", "<leader>y", '"+y', { silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

vim.keymap.set("n", "<C-b>", function()
  local cwd    = vim.fn.getcwd()
  local script = cwd .. "/build.sh"
  if vim.fn.filereadable(script) ~= 1 then
    vim.notify("build.sh not found", vim.log.levels.WARN)
    return
  end
  vim.cmd("belowright split | terminal" .. vim.fn.shellescape(script))
  vim.cmd("startinsert")
end, { desc = "Run build.sh" })

vim.cmd.colorscheme("warm")

vim.keymap.set("n", "<leader>ww", vim.cmd.UndotreeToggle)

vim.pack.add({
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/folke/trouble.nvim",
  "https://github.com/mbbill/undotree",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

vim.api.nvim_create_user_command("PackList", function()
  vim.print(vim.pack.get())
end, {})

vim.api.nvim_create_user_command("PackRemove", function(opts)
  local plugins = opts.fargs
  if #plugins == 0 then
    vim.notify('Usage: :Uninstall plugin1 [plugin2 ...]', vim.log.levels.ERROR)
    return
  end

  vim.ui.select(plugins, {
    prompt = 'Confirm uninstall?',
    format_item = function(item)
      return 'Remove: ' .. item
    end,
  }, function(choice)
    if not choice then return end

    local ok, err = pcall(vim.pack.del, plugins)
    if ok then
      vim.notify('Uninstalled: ' .. table.concat(plugins, ', '), vim.log.levels.INFO)
      vim.cmd('redraw')
      vim.notify('→ Run :restart to finish', vim.log.levels.WARN)
    else
      vim.notify('Error: ' .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end,
{
  nargs = '+',
  desc = 'Uninstall one or more vim.pack plugins',
})

require("gitsigns").setup({
  signs = {
    add          = { text = "+" },
    change       = { text = "~" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
  },
})

require("telescope").setup({})

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>sh", builtin.help_tags,    { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps,      { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sf", builtin.find_files,   { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>ss", builtin.builtin,      { desc = "[S]earch [S]elect Telescope" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string,  { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep,    { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics,  { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sr", builtin.resume,       { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader>s.", builtin.oldfiles,     { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

vim.keymap.set("n", "<leader>/", function()
  builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    winblend  = 10,
    previewer = false,
  }))
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>s/", function()
  builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
end, { desc = "[S]earch [/] in Open Files" })

vim.keymap.set("n", "<leader>sn", function()
  builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("rnoba-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    map("gO", require("telescope.builtin").lsp_document_symbols,                  "Open Document Symbols")
    map("gd", require("telescope.builtin").lsp_definitions,                       "[G]oto [D]efinition")
    map("gr", require("telescope.builtin").lsp_references,                        "[G]oto [R]eferences")
    map("gu", require("telescope.builtin").lsp_implementations,                   "[G]oto [I]mplementation")
    map("<leader>D",  require("telescope.builtin").lsp_type_definitions,          "Type [D]efinition")
    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
    map("<leader>rn", vim.lsp.buf.rename,      "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
    map("gD",         vim.lsp.buf.declaration, "[G]oto [D]eclaration")

    local function client_supports_method(client, method, bufnr)
      return client:supports_method(method, { bufnr = bufnr })
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = false })
    end

    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup("rnoba-lsp-highlight", { clear = false })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer   = event.buf,
        group    = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer   = event.buf,
        group    = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("rnoba-lsp-detach", { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = "rnoba-lsp-highlight", buffer = event2.buf })
        end,
      })
    end

    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map("<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
      end, "[T]oggle Inlay [H]ints")
    end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  float         = { border = "rounded", source = "if_many" },
  underline     = { severity = vim.diagnostic.severity.ERROR },
  signs         = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN]  = "󰀪 ",
      [vim.diagnostic.severity.INFO]  = "󰋽 ",
      [vim.diagnostic.severity.HINT]  = "󰌶 ",
    },
  } or {},
  virtual_text = {
    source  = "if_many",
    spacing = 2,
    format  = function(diagnostic)
      return diagnostic.message
    end,
  },
})

local capabilities = vim.lsp.protocol.make_client_capabilities()

local servers = {
  clangd = {
    on_attach = function(client)
      client.server_capabilities.documentFormattingProvider      = false
      client.server_capabilities.documentRangeFormattingProvider = false

      vim.diagnostic.config({
        underline    = { severity = vim.diagnostic.severity.ERROR },
        signs        = false,
        virtual_text = false,
      })
    end,
  },
  ts_ls = {
    cmd = { "bunx", "typescript-language-server", "--stdio" },
  },
  -- nixd = {},
  -- prismals = {},
  -- tailwindcss = {},
  -- gopls = {},
  -- svelte = {},
  -- pyright = {},
  -- lua_ls = {
  --   settings = {
  --     Lua = {
  --       completion = {
  --         callSnippet = "Replace",
  --       },
  --     },
  --   },
  -- },
}

local function setup(server_name)
  local server = servers[server_name] or {}
  server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
  vim.lsp.config(server_name, server)
  vim.lsp.enable(server_name)
end

for _, server_name in ipairs(vim.tbl_keys(servers)) do
  setup(server_name)
end

require("trouble").setup({})
vim.keymap.set("n", "<leader>xa", "<cmd>Trouble diagnostics toggle<cr>",              { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>",      { desc = "Symbols (Trouble)" })
