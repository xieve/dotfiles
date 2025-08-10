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
require("nvim-autopairs").setup {
	check_ts = true,
}
vim.cmd.packadd("nvim-ts-autotag")
require("nvim-ts-autotag").setup {}
vim.cmd.packadd("vim-matchup")
vim.g.matchup_matchparen_deferred = 1

-- Automatic whitespace
vim.cmd.packadd("sleuth")
vim.cmd.packadd("suda.vim")
vim.cmd.packadd("targets.vim")
vim.cmd.packadd("vim-cutlass")
vim.cmd.packadd("vim-indent-object")
vim.cmd.packadd("vim-subversive")
vim.cmd.packadd("vim-surround")
vim.cmd.packadd("vim-textobj-user")
vim.cmd.packadd("vim-textobj-entire")
vim.cmd.packadd("vim-yoink")


-- vim-subversive
-- s<text object> to replace <text object> with selected register. use `cl` for
-- old behaviour.
vim.keymap.set("n", "s", "<plug>(SubversiveSubstitute)")
vim.keymap.set("n", "ss", "<plug>(SubversiveSubstituteLine)")
vim.keymap.set("n", "S", "<plug>(SubversiveSubstituteToEndOfLine)")


-- vim-yoink
vim.g.yoinkSyncNumberedRegisters = 1
vim.g.yoinkIncludeDeleteOperations = 1

if not vim.g.vscode then
	vim.cmd.packadd("which-key.nvim")

	vim.keymap.set("n", "<c-n>", "<plug>(YoinkPostPasteSwapBack)")
	vim.keymap.set("n", "<c-p>", "<plug>(YoinkPostPasteSwapForward)")

	vim.keymap.set("n", "p", "<plug>(YoinkPaste_p)")
	vim.keymap.set("n", "P", "<plug>(YoinkPaste_P)")
end

-- Also replace the default gp with yoink paste so we can toggle paste in this case too
vim.keymap.set("n", "gp", "<plug>(YoinkPaste_gp)")
vim.keymap.set("n", "gP", "<plug>(YoinkPaste_gP)")

vim.keymap.set("n", "y", "<plug>(YoinkYankPreserveCursorPosition)")
vim.keymap.set("x", "y", "<plug>(YoinkYankPreserveCursorPosition)")


vim.cmd.source("~/.vimrc")
