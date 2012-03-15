"Use Vim settings, rather then Vi settings (much better!).
"This must be first, because it changes other options as a side effect.
set nocompatible

" Set mapleader
let mapleader = ","
let g:mapleader = ","

" Load pathogen
" Needed on some linux distros.
" see http://www.adamlowe.me/2009/12/vim-destroys-all-other-rails-editors.html
filetype off
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

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
