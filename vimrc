" Unicode support for unrecognized locales
if has("multi_byte")
    if &termencoding == ""
        let termencoding = &encoding
    endif
    set encoding=utf-8
    setglobal fileencoding=utf-8
    set fileencodings=ucs-bom,utf-8,latin1
endif


" Airline setup
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_min_count = 2
let g:airline_skip_empty_sections = 1
"let g:airline_theme='base16_shell'
" vim/autoload/airline/themes/base16.vim, managed by flavours
let g:airline_theme='flavours'

" Slant seperator
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
            \ 'space' : ' '}

let g:tmuxline_preset = {
            \ 'a': '#S',
            \ 'win': ['#I', '#W'],
            \ 'cwin': ['#I', '#W'],
            \ 'z': '#H',
            \ 'options': {
                \'status-justify': 'left'}
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


syntax on
set laststatus=2    " display statusline for every window


" Use mouse input
set ttymouse=xterm2
set mouse=a


" Line numbering
set number
set relativenumber


" Tabs
set tabstop=4       " tabs are at proper location
set expandtab       " don't use actual tab character (ctrl-v)
set shiftwidth=4    " indenting is 4 spaces
set autoindent
set smartindent     " does the right thing (mostly) in programs
set cindent         " stricter rules for c programs
filetype plugin indent on


" Show invisibles
set list
set showbreak=↪\
set listchars=tab:——→,nbsp:␣,trail:·,extends:›,precedes:‹


" Allow saving of files as sudo when I forgot to start vim using sudo.
cnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!
