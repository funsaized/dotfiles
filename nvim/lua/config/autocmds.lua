-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Semantic italics for Operator Mono Book Italic (comments/keywords/types/params).
-- Re-applied on ColorScheme so Omarchy theme hot-reload does not drop it.
local function apply_semantic_italics()
  local groups = {
    "Comment",
    "Keyword",
    "Type",
    "Parameter",
    "@comment",
    "@comment.documentation",
    "@keyword",
    "@keyword.function",
    "@keyword.return",
    "@keyword.operator",
    "@keyword.import",
    "@keyword.conditional",
    "@keyword.repeat",
    "@type",
    "@type.builtin",
    "@type.definition",
    "@parameter",
    "@variable.parameter",
    "@attribute",
    "@lsp.type.comment",
    "@lsp.type.keyword",
    "@lsp.type.type",
    "@lsp.type.parameter",
    "@lsp.type.decorator",
  }
  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl and next(hl) ~= nil then
      hl.italic = true
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

local italic_group = vim.api.nvim_create_augroup("semantic_italics", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = italic_group,
  callback = apply_semantic_italics,
})
vim.api.nvim_create_autocmd("User", {
  group = italic_group,
  pattern = "VeryLazy",
  callback = apply_semantic_italics,
})
apply_semantic_italics()
