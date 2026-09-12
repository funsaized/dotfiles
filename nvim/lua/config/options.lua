-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = true

-- Format on save is a surprise in unfamiliar trees. Conform still runs via
-- <leader>cf; LSP format stays on demand.
vim.g.autoformat = false
