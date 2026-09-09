return {
	{
		name = "theme-hotreload",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		config = function()
			local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

			local function reload_theme()
				-- Unload the theme module
				package.loaded["plugins.theme"] = nil

				vim.schedule(function()
					local ok, theme_spec = pcall(require, "plugins.theme")
					if not ok then
						return
					end

						-- Find the theme plugin and unload it
						local theme_plugin_name = nil
						for _, spec in ipairs(theme_spec) do
							if spec[1] and spec[1] ~= "LazyVim/LazyVim" then
								theme_plugin_name = spec.name or spec[1]
								break
							end
						end

						-- Clear all highlight groups before applying new theme
						vim.cmd("highlight clear")
						if vim.fn.exists("syntax_on") then
							vim.cmd("syntax reset")
						end

						-- Reset background to default so colorscheme can set it properly (light themes will set to light)
						vim.o.background = "dark"

						-- Unload theme plugin modules to force full reload
						if theme_plugin_name then
							local plugin = require("lazy.core.config").plugins[theme_plugin_name]
							if plugin then
								-- Unload all lua modules from the plugin directory
								local plugin_dir = plugin.dir .. "/lua"
								require("lazy.core.util").walkmods(plugin_dir, function(modname)
									package.loaded[modname] = nil
									package.preload[modname] = nil
								end)
							end
						end

						-- Find and apply the new colorscheme
						for _, spec in ipairs(theme_spec) do
							if spec[1] == "LazyVim/LazyVim" and spec.opts and spec.opts.colorscheme then
								local colorscheme = spec.opts.colorscheme

								-- Load the colorscheme plugin. If it's already loaded (old and new
								-- theme sharing the same plugin, e.g. generic themes on aether.nvim),
								-- lazy won't rerun setup() on a spec reload and keeps the old
								-- resolved opts in the plugin's property cache, so fully reload it
								-- to reapply setup() with the new theme's opts.
								local theme_plugin = theme_plugin_name and require("lazy.core.config").plugins[theme_plugin_name]
								if theme_plugin and theme_plugin._.loaded then
									require("lazy.core.loader").reload(theme_plugin)
								else
									require("lazy.core.loader").colorscheme(colorscheme)
								end

								vim.defer_fn(function()
									-- Apply the colorscheme (it will set background itself)
									pcall(vim.cmd.colorscheme, colorscheme)

									-- Force redraw to update all UI elements
									vim.cmd("redraw!")

									-- Reload transparency settings
									if vim.fn.filereadable(transparency_file) == 1 then
										vim.defer_fn(function()
											vim.cmd.source(transparency_file)

											-- Trigger UI updates for various plugins
											vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
											vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })

											-- Final redraw
											vim.cmd("redraw!")
										end, 5)
									end
								end, 5)

								break
							end
						end
					end)
			end

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyReload",
				callback = reload_theme,
			})

			-- Omarchy swaps ~/.local/state/omarchy/current/theme as a directory,
			-- which invalidates a watch on neovim.lua itself. theme.name is a
			-- regular file rewritten in place — a stable inode to watch so a
			-- running nvim picks up `omarchy theme set` without a restart.
			-- No-op on machines without Omarchy (macOS, plain Linux).
			local theme_name = vim.fn.expand("~/.local/state/omarchy/current/theme.name")
			if vim.fn.filereadable(theme_name) == 1 then
				local uv = vim.uv or vim.loop
				local handle = uv.new_fs_event()
				if handle then
					handle:start(theme_name, {}, vim.schedule_wrap(function(err)
						if not err then
							reload_theme()
						end
					end))
				end
			end
		end,
	},
}
