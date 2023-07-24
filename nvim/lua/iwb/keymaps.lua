local Job = require("plenary.job")
vim.keymap.set('n', '<leader>ll', ":Ex <Cr>")
vim.keymap.set('n', '<c-s>', ":w <cr>")
vim.keymap.set('i', '<C-s>', "<ESC>:w <Cr>")

vim.keymap.set('n', '<C-b>', function()
    vim.cmd [[echo system(['justbuild'])]]
    -- vim.cmd [[split]]
    -- vim.cmd [[term]]
    -- vim.cmd [[startinsert]]
    -- vim.api.nvim_input(cmd)
end)
