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
Plug 'ryanoasis/vim-devicons'
Plug 'Lokaltog/vim-easymotion'
Plug 'Raimondi/delimitMate'
Plug 'airblade/vim-gitgutter'
Plug 'ap/vim-css-color'
Plug 'chrisbra/csv.vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'editorconfig/editorconfig-vim'
Plug 'ekalinin/Dockerfile.vim'
Plug 'jlanzarotta/bufexplorer'
Plug 'junegunn/vim-easy-align'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'markcornick/vim-terraform'
Plug 'mattn/emmet-vim'
Plug 'michaeljsmith/vim-indent-object'
Plug 'mileszs/ack.vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'elzr/vim-json'
Plug 'regedarek/ZoomWin'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/syntastic'
Plug 'sjl/gundo.vim'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-rsi'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vividchalk'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'vim-ruby/vim-ruby'
" Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Plug 'Shougo/neosnippet.vim'
" Plug 'Shougo/neosnippet-snippets'
Plug 'davidhalter/jedi-vim'
Plug 'chriskempson/base16-vim'
Plug 'cespare/vim-toml'
Plug 'rust-lang/rust.vim'

" neovim specific
if has('nvim')
  " Plug 'slashmili/alchemist.vim'
  " Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  " Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
  " Plug 'neomake/neomake'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  "Plug 'c-brenn/phoenix.vim'
  Plug 'tpope/vim-projectionist' " required for some navigation features
  Plug 'powerman/vim-plugin-AnsiEsc'

  Plug 'neovim/nvim-lspconfig'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'

  " For vsnip users.
  Plug 'hrsh7th/cmp-vsnip'
  Plug 'hrsh7th/vim-vsnip'

  " For luasnip users.
  " Plug 'L3MON4D3/LuaSnip'
  " Plug 'saadparwaiz1/cmp_luasnip'
  " For ultisnips users.
  " Plug 'SirVer/ultisnips'
  " Plug 'quangnguyen30192/cmp-nvim-ultisnips'
  " For snippy users.
  " Plug 'dcampos/nvim-snippy'
  " Plug 'dcampos/cmp-snippy
else
  " Plug 'Shougo/deoplete.nvim'
  " Plug 'roxma/nvim-yarp'
  " Plug 'roxma/vim-hug-neovim-rpc'
endif

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
