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
		"norg",
		"svelte",
		"typst",
		"vue",
		"yaml",
		"toml",
		"fish",

		-- Add here more languages with which you want to use tree-sitter
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

	-- Enable tree-sitter after opening a file for a target language
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
		"lua_ls",
		"stylua",
		"tailwindcss",
		"cssls",
		"harper_ls",
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

add({ "https://github.com/pmizio/typescript-tools.nvim" })

local ts_tools_loaded = false
local function setup_ts_tools()
	if ts_tools_loaded then
		return
	end
	ts_tools_loaded = true
	require("typescript-tools").setup({})
end

Config.on_filetype("javascript", setup_ts_tools)
Config.on_filetype("javascriptreact", setup_ts_tools)
Config.on_filetype("typescript", setup_ts_tools)
Config.on_filetype("typescriptreact", setup_ts_tools)

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

later(function()
	add({ "https://github.com/catgoose/nvim-colorizer.lua" })

	require("colorizer").setup({
		options = {
			parsers = { css = true },
		},
	})
end)

-- Render markdown with Latex support!
later(function()
	add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })
	require("render-markdown").setup({
		win_options = {
			conceallevel = {
				default = vim.api.nvim_get_option_value("conceallevel", {}),
				rendered = 3,
			},
			concealcursor = {
				default = vim.api.nvim_get_option_value("concealcursor", {}),
				rendered = "nv",
			},
		},

		completions = {
			lsp = { enabled = true },
		},
		latex = {
			enabled = true,
			render_modes = true,
			converter = { "utftex", "latex2text" },
			highlight = "RenderMarkdownMath",
			position = "center",
			top_pad = 0,
			bottom_pad = 0,
		},
	})
end)

-- Show implementations and references like JetBrains above symbols
-- later(function()
-- 	add({ "https://github.com/Wansmer/symbol-usage.nvim" })
-- local function h(name) return vim.api.nvim_get_hl(0, { name = name }) end
-- vim.api.nvim_set_hl(0, 'SymbolUsageRounding', { fg = h('CursorLine').bg, italic = true })
-- vim.api.nvim_set_hl(0, 'SymbolUsageContent', { bg = h('CursorLine').bg, fg = h('Comment').fg, italic = true })
-- vim.api.nvim_set_hl(0, 'SymbolUsageRef', { fg = h('Function').fg, bg = h('CursorLine').bg, italic = true })
-- vim.api.nvim_set_hl(0, 'SymbolUsageDef', { fg = h('Type').fg, bg = h('CursorLine').bg, italic = true })
-- vim.api.nvim_set_hl(0, 'SymbolUsageImpl', { fg = h('@keyword').fg, bg = h('CursorLine').bg, italic = true })
-- 	local function text_format(symbol)
-- 		local res = {}
--
-- 		local round_start = { "", "SymbolUsageRounding" }
-- 		local round_end = { "", "SymbolUsageRounding" }
--
-- 		-- Indicator that shows if there are any other symbols in the same line
-- 		local stacked_functions_content = symbol.stacked_count > 0 and ("+%s"):format(symbol.stacked_count) or ""
--
-- 		if symbol.references then
-- 			local usage = symbol.references <= 1 and "usage" or "usages"
-- 			local num = symbol.references == 0 and "no" or symbol.references
-- 			table.insert(res, round_start)
-- 			table.insert(res, { "󰌹 ", "SymbolUsageRef" })
-- 			table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
-- 			table.insert(res, round_end)
-- 		end
--
-- 		if symbol.definition then
-- 			if #res > 0 then
-- 				table.insert(res, { " ", "NonText" })
-- 			end
-- 			table.insert(res, round_start)
-- 			table.insert(res, { "󰳽 ", "SymbolUsageDef" })
-- 			table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
-- 			table.insert(res, round_end)
-- 		end
--
-- 		if symbol.implementation then
-- 			if #res > 0 then
-- 				table.insert(res, { " ", "NonText" })
-- 			end
-- 			table.insert(res, round_start)
-- 			table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
-- 			table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
-- 			table.insert(res, round_end)
-- 		end
--
-- 		if stacked_functions_content ~= "" then
-- 			if #res > 0 then
-- 				table.insert(res, { " ", "NonText" })
-- 			end
-- 			table.insert(res, round_start)
-- 			table.insert(res, { " ", "SymbolUsageImpl" })
-- 			table.insert(res, { stacked_functions_content, "SymbolUsageContent" })
-- 			table.insert(res, round_end)
-- 		end
--
-- 		return res
-- 	end
-- 	require("symbol-usage").setup({
--     text_format = text_format,
--     vt_position = 'end_of_line',
--   })
-- end)
