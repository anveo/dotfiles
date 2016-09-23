"Use Vim settings, rather then Vi settings (much better!).
"This must be first, because it changes other options as a side effect.
set nocompatible

" Set mapleader
"let mapleader = ","
"let g:mapleader = ","
let mapleader = "\<Space>"
let g:mapleader = "\<Space>"

filetype off

call plug#begin('~/.vim/plugged')

" Make sure you use single quotes
Plug 'Lokaltog/vim-easymotion'
Plug 'Nemo157/glsl.vim'
Plug 'Raimondi/delimitMate'
"Plug 'Rykka/riv.vim'
Plug 'Rykka/InstantRst'
"Plug 'Shougo/neomru.vim'
"Plug 'Shougo/unite.vim'
"Plug 'Valloric/YouCompleteMe'
Plug 'airblade/vim-gitgutter'
Plug 'altercation/vim-colors-solarized'
Plug 'ap/vim-css-color'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'chrisbra/csv.vim'
Plug 'ecomba/vim-ruby-refactoring'
Plug 'editorconfig/editorconfig-vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'elixir-lang/vim-elixir'
Plug 'ervandew/supertab'
Plug 'fatih/vim-go'
Plug 'gregsexton/gitv'
Plug 'jdonaldson/vaxe'
Plug 'jelera/vim-javascript-syntax'
Plug 'jlanzarotta/bufexplorer'
Plug 'junegunn/vim-easy-align'
Plug 'kana/vim-textobj-entire'
Plug 'kana/vim-textobj-user'
Plug 'kchmck/vim-coffee-script'
Plug 'kien/ctrlp.vim'
Plug 'leafgarland/typescript-vim'
Plug 'majutsushi/tagbar'
Plug 'markcornick/vim-terraform'
Plug 'mattn/emmet-vim'
Plug 'michaeljsmith/vim-indent-object'
Plug 'mileszs/ack.vim'
Plug 'motemen/git-vim'
Plug 'msanders/snipmate.vim'
Plug 'mustache/vim-mustache-handlebars'
Plug 'mxw/vim-jsx'
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'regedarek/ZoomWin'
Plug 'rizzatti/dash.vim'
Plug 'rodjek/vim-puppet'
Plug 'rorymckinley/vim-symbols-strings'
Plug 'rust-lang/rust.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/syntastic'
Plug 'sjl/gundo.vim'
Plug 'sophacles/vim-processing'
Plug 'terryma/vim-expand-region'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-commentary'
"Plug 'tpope/vim-cucumber'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-haml'
Plug 'tpope/vim-liquid'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vividchalk'
Plug 'vim-ruby/vim-ruby'
Plug 'vim-scripts/YankRing.vim'
Plug 'vim-scripts/taglist.vim'
"Plugin 'wincent/ferret'

" Add plugins to &runtimepath
call plug#end()

" These must be loaded before turning filetype back on.
source ~/.vim/config/plugins.vim
" Load plugin and indent settings for the detected filetype.
filetype plugin indent on

source ~/.vim/config/settings.vim
source ~/.vim/config/statusline.vim
source ~/.vim/config/autocommands.vim
source ~/.vim/config/commands.vim
source ~/.vim/config/mappings.vim

"load ftplugins and indent files
filetype plugin on
filetype indent on

"turn on syntax highlighting
syntax on

set encoding=utf8
try
    lang en_US
catch
endtry

" ack
set grepprg=ack
set grepformat=%f:%l:%m

"return the syntax highlight group under the cursor ''
function! StatuslineCurrentHighlight()
    let name = synIDattr(synID(line('.'),col('.'),1),'name')
    if name == ''
        return ''
    else
        return '[' . name . ']'
    endif
endfunction

" set colorscheme
colorscheme jellybeans+

set colorcolumn=120

" subtle red colorcolumn
highlight ColorColumn ctermbg=234 guibg=#261e1e
highlight LineProximity guibg=#212121
highlight LineOverflow guibg=#902020

let w:m1=matchadd('LineProximity', '\%<121v.\%>116v', -1)
let w:m2=matchadd('LineOverflow', '\%>120v.\+', -1)

autocmd VimEnter * autocmd WinEnter * let w:created=1
autocmd VimEnter * let w:created=1

autocmd WinEnter * if !exists('w:created') | let w:m1=matchadd('LineProximity', '\%<121v.\%>116v', -1) | endif
autocmd WinEnter * if !exists('w:created') | let w:m2=matchadd('LineOverflow', '\%>120v.\+', -1) | endif

"set list listchars=tab:>-,trail:.,extends:>
" Enter the middle-dot by pressing Ctrl-k then .M
"set list listchars=tab:\|_,trail::
" Enter the right-angle-quote by pressing Ctrl-k then >>
set list listchars=tab:»·,trail:·
" Enter the Pilcrow mark by pressing Ctrl-k then PI
"set list listchars=tab:>-,eol:¶
" The command :dig displays other digraphs you can use.
highlight SpecialKey guifg=#ffffff guibg=#902020
highlight NonText guifg=#222222
