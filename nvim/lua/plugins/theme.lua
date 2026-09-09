-- Colorscheme for this machine.
--
-- On Omarchy, `omarchy theme set` writes neovim.lua into the current theme
-- directory. Load that at startup so nvim matches the desktop without a
-- second file to keep in sync. The symlink Omarchy used to drop in this
-- path is *not* portable — it points at a Linux-only state dir — so this
-- file is a real loader instead.
--
-- Everywhere else (macOS, non-Omarchy Linux), fall back to the Gruvy Glass
-- / aether snapshot this repo was built against. Restart nvim after an
-- Omarchy theme switch; the hotreload plugin still covers in-session
-- LazyReload events.

local omarchy = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(omarchy) == 1 then
  local ok, spec = pcall(dofile, omarchy)
  if ok and type(spec) == "table" then
    return spec
  end
end

return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#282828",
        dark_bg = "#1e1e1e",
        darker_bg = "#141414",
        lighter_bg = "#282828",

        fg = "#d4be98",
        dark_fg = "#3c3836",
        light_fg = "#d4be98",
        bright_fg = "#d4be98",
        muted = "#3c3836",

        red = "#ea6962",
        yellow = "#d8a657",
        orange = "#d8a657",
        green = "#a9b665",
        cyan = "#89b482",
        blue = "#7daea3",
        magenta = "#d3869b",
        brown = "#6c532c",

        bright_red = "#ea6962",
        bright_yellow = "#d8a657",
        bright_green = "#a9b665",
        bright_cyan = "#89b482",
        bright_blue = "#7daea3",
        bright_magenta = "#d3869b",

        accent = "#7daea3",
        cursor = "#d4be98",
        foreground = "#d4be98",
        background = "#282828",
        selection = "#d65d0e",
        selection_foreground = "#ebdbb2",
        selection_background = "#d65d0e",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
