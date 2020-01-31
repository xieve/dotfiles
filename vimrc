set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'edkolev/promptline.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ

let g:airline_powerline_fonts = 1

syntax on
set laststatus=2    " display statusline for every window

" Use mouse input
set ttymouse=xterm2
set mouse=a

" Line numbering
set number
set relativenumber

set tabstop=4       " tabs are at proper location
set expandtab       " don't use actual tab character (ctrl-v)
set shiftwidth=4    " indenting is 4 spaces
set autoindent      " turns it on
set smartindent     " does the right thing (mostly) in programs
set cindent         " stricter rules for c programs

" Show invisibles
set list
set showbreak=↪\
set listchars=tab:\ ->,nbsp:␣,trail:·,extends:›,precedes:‹

" Allow saving of files as sudo when I forgot to start vim using sudo.
cnoremap w!! execute 'write !sudo tee % >/dev/null' <bar> edit!

