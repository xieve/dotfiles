vim.o.runtimepath = "~/.vim," .. vim.o.runtimepath .. ",~/.vim/after"
vim.o.packpath = vim.o.runtimepath

vim.cmd.packadd("nvim-treesitter")
require("nvim-treesitter.configs").setup {
	auto_install = false,
	highlight = {
		enable = true,
	},
	indent = {
		enable = true,
	},
	matchup = {
		enable = true,
	},
}

vim.cmd.packadd("nvim-autopairs")
require("nvim-autopairs").setup {}
vim.cmd.packadd("nvim-ts-autotag")
require("nvim-ts-autotag").setup {}
vim.cmd.packadd("vim-matchup")
vim.cmd.packadd("which-key.nvim")

vim.cmd.source("~/.vimrc")
