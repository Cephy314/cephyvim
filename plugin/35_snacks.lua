local Snacks = require("snacks")
Snacks.setup({
	indent = {
		enabled = true,
		only_scope = true,
		only_current = true,
		chunk = {
			enabled = true,
			char = {
				corner_top = "╭",
				corner_bottom = "╰",
			},
		},
	},
  image = { enabled = true },
  lazygit = { enabled = true },
  quickfile = { enabled = true },

})
