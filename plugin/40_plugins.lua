-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now_if_args, later = Config.now_if_args, Config.later

-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
	-- Define hook to update tree-sitter parsers after plugin is updated
	local ts_update = function()
		vim.cmd("TSUpdate")
	end
	Config.on_packchanged("nvim-treesitter", { "update" }, ts_update, ":TSUpdate")

	add({
		"https://github.com/nvim-treesitter/nvim-treesitter",
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	})

	-- Define languages which will have parsers installed and auto enabled
	-- After changing this, restart Neovim once to install necessary parsers. Wait
	-- for the installation to finish before opening a file for added language(s).
	local languages = {
		-- These are already pre-installed with Neovim. Used as an example.
		"lua",
		"vimdoc",
		"markdown",
		"markdown_inline",
		"javascript",
		"typescript",
		"tsx",
		"jsx",
		"css",
		"scss",
		"rust",
		"html",
		"latex",
		"svelte",
		"typst",
		"vue",
		"yaml",
		"toml",
		"fish",
		"python",
		-- Add here more languages with which you want to use Tree-sitter
		-- To see available languages:
		-- - Execute `:=require('nvim-treesitter').get_available()`
		-- - Visit 'SUPPORTED_LANGUAGES.md' file at
		--   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
	}
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, languages)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	-- Enable Tree-sitter after opening a file for a target language
	local filetypes = {}
	for _, lang in ipairs(languages) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		vim.treesitter.start(ev.buf)
	end
	Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
	add({ "https://github.com/neovim/nvim-lspconfig" })

	-- Use `:h vim.lsp.enable()` to automatically enable language server based on
	-- the rules provided by 'nvim-lspconfig'.
	-- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
	-- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
	vim.lsp.enable({
		-- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
		"jsonls",
		"lua_ls",
		"stylua",
		"tailwindcss",
		"cssls",
		"harper_ls",
		"pyright",
		"ts_ls",
	})
end)

-- vim.lsp.codelens.enable(true)
-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
	add({ "https://github.com/stevearc/conform.nvim" })

	-- See also:
	-- - `:h Conform`
	-- - `:h conform-options`
	-- - `:h conform-formatters`
	require("conform").setup({
		default_format_opts = {
			-- Allow formatting from LSP server if no dedicated formatter is available
			lsp_format = "fallback",
		},
		-- Map of filetype to formatters
		-- Make sure that necessary CLI tool is available
		formatters_by_ft = {
			lua = { "stylua" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			css = { "stylelint", "prettierd" },
			scss = { "stylelint", "prettierd" },
			rust = { "rustfmt" },
		},
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	})
end)

-- add({ "https://github.com/pmizio/typescript-tools.nvim" })
--
-- local ts_tools_loaded = false
-- local function setup_ts_tools()
-- 	if ts_tools_loaded then
-- 		return
-- 	end
-- 	ts_tools_loaded = true
-- 	require("typescript-tools").setup({})
-- end
--
-- Config.on_filetype("javascript", setup_ts_tools)
-- Config.on_filetype("javascriptreact", setup_ts_tools)
-- Config.on_filetype("typescript", setup_ts_tools)
-- Config.on_filetype("typescriptreact", setup_ts_tools)

now_if_args(function()
	add({ "https://github.com/mrcjkb/rustaceanvim" })
end)

now_if_args(function()
	add({ "https://github.com/saecki/crates.nvim" })
	require("crates").setup()
end)
-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
	add({ "https://github.com/rafamadriz/friendly-snippets" })
end)

-- later(function()
-- 	add({ "https://github.com/catgoose/nvim-colorizer.lua" })
--
-- 	require("colorizer").setup({
-- 		options = {
-- 			parsers = { css = true },
-- 		},
-- 	})
-- end)

later(function()
	add({ "https://github.com/OXY2DEV/markview.nvim" })
	require("markview").setup({
		markdown = {
			enabled = true,
			wrap = true,
		},
	})
end)

-- Render markdown with Latex support!
--
-- later(function()
-- 	add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
-- 	require("render-markdown").setup({
-- 		-- anti_conceal = { enabled = true },
-- 		pipe_table = {
-- 			enabled = false,
-- 		},
-- 		completions = {
-- 			lsp = { enabled = true },
-- 		},
-- 		win_options = {
-- 			conceallevel = { default = vim.o.conceallevel, rendered = 2 },
-- 		},
-- 		link = { enabled = false },
-- 	})
-- end)
--

-- MARKKDOWN TABLE WRAP
-- later(function()
-- 	add({ "https://github.com/ice345/markdown-table-wrap.nvim" })
-- 	require("markdown-table-wrap").setup({
-- 		max_width_ratio = 0.9,
-- 		min_col_width = 6,
-- 		max_col_width = 80,
-- 		border = "rounded",
-- 		use_unicode_border = true,
-- 		fit_to_window = true,
-- 		row_separator = true,
-- 		preview_mode = "reader",
-- 		inline_mode = "replace",
-- 		inline_position = "above",
-- 		dim_source = true,
-- 		auto_preview = true,
-- 		render_all = true,
-- 		auto_preview_in_insert = false,
-- 		clear_on_cursor_leave = true,
-- 		clear_on_insert = true,
-- 		clear_on_visual = true,
-- 		highlight_preset = "teide",
-- 		themes = {
-- 			teide = {
-- 				border = { fg = "#75a0d6" },
-- 				inline = { fg = "#cdd6f4" },
-- 				source = { link = "Comment" },
-- 				header = { fg = "#5CCEFF", bold = true },
-- 				code = { fg = "#5CCEFF", bg = "#1e2329" },
-- 				link = { fg = "#41FFDC", underline = true },
-- 				bold = { bold = true },
-- 				italic = { italic = true },
-- 				strike = { strikethrough = true },
-- 				mark = { fg = "#b2a3ff", bg = "#f9e2af" },
-- 				wiki_link = { fg = "#cba6f7", underline = true },
-- 				image = { fg = "#94e2d5" },
-- 				blank = { link = "Normal" },
-- 			},
-- 		},
-- 		link = false,
-- 	})
-- end)

later(function()
	add({ "https://github.com/rachartier/tiny-inline-diagnostic.nvim" })
	require("tiny-inline-diagnostic").setup({
		preset = "modern",
	})
end)

later(function()
	add({ "https://github.com/sphamba/smear-cursor.nvim" })
	require("smear_cursor").setup({
		stiffness = 0.8, -- 0.6      [0, 1]
		trailing_stiffness = 0.6, -- 0.45     [0, 1]
		stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
		trailing_stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
		damping = 0.95, -- 0.85     [0, 1]
		damping_insert_mode = 0.95, -- 0.9      [0, 1]
		distance_stop_animating = 0.5, -- 0.1      > 0
	})
end)

later(function()
	vim.pack.add({
		{
			src = "https://github.com/eero-lehtinen/oklch-color-picker.nvim",
			version = vim.version.range("*"),
		},
	})
	require("oklch-color-picker").setup({})

	vim.keymap.set("n", "<leader>c", function()
		require("oklch-color-picker").pick_under_cursor()
	end, { desc = "Color pick under cursor" })
end)
