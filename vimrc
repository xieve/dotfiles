packadd ReplaceWithRegister
packadd sleuth
packadd suda.vim
packadd targets.vim
packadd vim-cutlass
packadd vim-indent-object
packadd vim-subversive
packadd vim-surround
packadd vim-textobj-user
packadd vim-textobj-entire
packadd vim-yoink

" Unicode support for unrecognized locales
if has("multi_byte")
	if &termencoding == ""
		let termencoding = &encoding
	endif
	set encoding=utf-8
	setglobal fileencoding=utf-8
	set fileencodings=ucs-bom,utf-8,latin1
endif


if has('nvim')
	let g:yoinkSavePersistently = 1
	if exists('g:vscode')
		" Keep undo/redo lists in sync with VSCode
		nmap <silent> u <Cmd>call VSCodeNotify('undo')<CR>
		nmap <silent> <C-r> <Cmd>call VSCodeNotify('redo')<CR>
		nmap <silent> <C-f> <Cmd>call VSCodeNotify('actions.find')<CR>
	endif

	" Highlight yanked text
	autocmd TextYankPost * silent! lua vim.hl.on_yank {higroup='Visual', timeout=300}
else
	" Use mouse input
	set ttymouse=xterm2
endif


if !exists("g:vscode")
	packadd vim-fugitive
	packadd vim-airline
	packadd vim-airline

	" Airline setup
	let g:airline_powerline_fonts = 1
	let g:airline#extensions#tabline#enabled = 1
	let g:airline#extensions#tabline#buffer_min_count = 2
	let g:airline_skip_empty_sections = 1
	"let g:airline_theme='base16_shell'
	" vim/autoload/airline/themes/base16.vim, managed by flavours
	let g:airline_theme='flavours'

	" Slant separator
	if !exists('g:airline_symbols')
		let g:airline_symbols = {}
	endif
	let g:airline_left_sep = ''
	let g:airline_left_alt_sep = ''
	let g:airline_right_sep = ''
	let g:airline_right_alt_sep = ''

	let g:tmuxline_separators = {
		\ 'left' : g:airline_left_sep,
		\ 'left_alt': g:airline_left_alt_sep,
		\ 'right' : g:airline_right_sep,
		\ 'right_alt' : g:airline_right_alt_sep,
		\ 'space' : ' '
	\}

	let g:tmuxline_preset = {
		\ 'a': '#S',
		\ 'win': ['#I', '#W'],
		\ 'cwin': ['#I', '#W'],
		\ 'z': '#H',
		\ 'options': {
			\'status-justify': 'left'
		\}
	\}

	" Make vim's window separator match tmux
	set fillchars+=vert:│
	au User AirlineAfterInit,AirlineAfterTheme call FixSplitColours()
	fun! FixSplitColours()
		let l:termColour = g:airline#themes#{g:airline_theme}#palette['normal']['airline_a'][3]
		exec 'hi VertSplit ctermfg=' . l:termColour . ' ctermbg=NONE cterm=NONE'
		exec 'hi StatusLine ctermfg=' . l:termColour
		exec 'hi StatusLineNC ctermfg=' . l:termColour
	endfun


	" https://gist.github.com/romainl/379904f91fa40533175dfaec4c833f2f
	function! MyHighlights() abort
		highlight SpecialKey ctermbg=grey
	endfunction

	augroup MyColors
		autocmd!
		autocmd ColorScheme * call MyHighlights()
	augroup END


	" Color theme generated by flavours
	colorscheme flavours
	set termguicolors	" this one makes text more grey-ish, FIXME
	syntax on
	set laststatus=2	" display statusline for every window

	set mouse=a


	" Line numbering
	set number
	set relativenumber


	" Folding
	set foldmethod=syntax  " folds are appropriately created for supported languages
	set nofoldenable  " all folds open by default
endif


" Use system clipboard
set clipboard=unnamed,unnamedplus


" Tabs
set tabstop=4
set shiftwidth=4
set autoindent
set cindent cinkeys-=0#
filetype plugin indent on


" Show invisibles
set list
set showbreak=↪\
set listchars=tab:\│\ ,nbsp:␣,trail:·,extends:›,precedes:‹


" Scroll window before reaching edges
set scrolloff=7


" Ignore case while searching if entire search term is lowercase
set ignorecase
set smartcase


" Allow saving of files as sudo when I forgot to start vim using sudoedit.
cnoremap w!! SudaWrite


" vim-subversive
" s<text object> to replace <text object> with selected register. use `cl` for
" old behaviour.
nmap s <plug>(SubversiveSubstitute)
nmap ss <plug>(SubversiveSubstituteLine)
nmap S <plug>(SubversiveSubstituteToEndOfLine)


" vim-yoink
let g:yoinkSyncNumberedRegisters = 1
let g:yoinkIncludeDeleteOperations = 1

if !exists('g:vscode')
	nmap <c-n> <plug>(YoinkPostPasteSwapBack)
	nmap <c-p> <plug>(YoinkPostPasteSwapForward)

	nmap p <plug>(YoinkPaste_p)
	nmap P <plug>(YoinkPaste_P)
endif

" Also replace the default gp with yoink paste so we can toggle paste in this case too
nmap gp <plug>(YoinkPaste_gp)
nmap gP <plug>(YoinkPaste_gP)

nmap y <plug>(YoinkYankPreserveCursorPosition)
xmap y <plug>(YoinkYankPreserveCursorPosition)


" vim-cutlass
" uses `x` as the new cutting operation. `dl` will also delete a single
" character
nnoremap x d
xnoremap x d

nnoremap xx dd
nnoremap X D


" ~ now accepts a motion
set tildeop


" Automatically insert comment leaders when creating a new line from a comment
set formatoptions+=ro/

set textwidth=100
