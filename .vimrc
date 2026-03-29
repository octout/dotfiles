" --- 基本 ---
set nocompatible
set encoding=utf-8
set belloff=all
set backspace=indent,eol,start
set mouse=a
set directory=~/.vim/swap//

" --- 表示 ---
syntax on
set number
set ruler
set laststatus=2
set wildmenu

" --- 検索 ---
set incsearch
set hlsearch
set ignorecase
set smartcase

" --- インデント ---
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4

" --- Git ---
set updatetime=100
set signcolumn=yes
highlight SignColumn      ctermbg=NONE
highlight GitGutterAdd    ctermfg=2 ctermbg=NONE
highlight GitGutterChange ctermfg=3 ctermbg=NONE
highlight GitGutterDelete ctermfg=1 ctermbg=NONE
