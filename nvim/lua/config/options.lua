-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

-- Absolute line numbers. Relative numbers are a motion aid I don't use, and
-- they fight the italic-as-structure look by adding another changing column.
vim.opt.relativenumber = false

-- Format on save is a surprise in unfamiliar trees. Conform still runs via
-- <leader>cf; LSP format stays on demand.
vim.g.autoformat = false
