" Easier non-interactive command insertion
nnoremap <Space> :

" Make it easy to update/reload .vimrc
nmap <leader>s :source ~/.vimrc<CR>
nmap <leader>vi :tabe ~/.vimrc<CR>

" Columns are cooler than rows
noremap ' `
noremap ` '
noremap g' g`
noremap g` g'

" Jump to end of line in insert mode
imap <C-j> <End>

" Make Q useful and avoid the confusing Ex mode.
noremap Q <nop>
" Close window.
noremap QQ :q<CR>
" Close a full tab page.
noremap QW :windo bd<CR>
" Close all.
noremap QA :qa<CR>
" Close, damn you!
noremap Q! :q!<CR>

" Yank to OS X pasteboard.
noremap <leader>y "*y

" Paste from OS X pasteboard without messing up indent.
noremap <leader>p :set paste<CR>"*p<CR>:set nopaste<CR>

" Default searches to "very magic", more like the world outside Vim.
nnoremap / /\v
vnoremap / /\v
nnoremap ? ?\v
vnoremap ? ?\v

" Select the text that was last edited/pasted.
" http://vimcasts.org/episodes/bubbling-text/
nmap gV `[v`]

" Smart way to move between windows
nmap <S-j> <C-W>j
nmap <S-k> <C-W>k
nmap <S-h> <C-W>h
nmap <S-l> <C-W>l

" No Help, please
nmap <F1> <Esc>
map! <F1> <Esc>

" Emacs-like beginning and end of line.
imap <c-e> <c-o>$
imap <c-a> <c-o>^

" Other <F*> binds
nmap <F3> :set paste<CR>
nmap <F4> :set nopaste<CR>
nmap <F5> :GundoToggle<CR>

" map ,d to toggle NERDTree window
nmap <leader>d :NERDTreeToggle<CR>

" Shift + left/right to switch tabs.
noremap <S-Left> :tabp<CR>
noremap <S-Right> :tabn<CR>

" open tabs with command-<tab number>
map <D-1> :tabn 1<CR>
map <D-2> :tabn 2<CR>
map <D-3> :tabn 3<CR>
map <D-4> :tabn 4<CR>
map <D-5> :tabn 5<CR>
map <D-6> :tabn 6<CR>
map <D-7> :tabn 7<CR>
map <D-8> :tabn 8<CR>
map <D-9> :tabn 9<CR>

" Tab navigation
nmap <leader>tn :tabnext<CR>
nmap <leader>tp :tabprevious<CR>
nmap <leader>te :tabedit

"make <c-l> clear the highlight as well as redraw
nnoremap <C-L> :nohls<CR><C-L>
inoremap <C-L> <C-O>:nohls<CR>

"map Q to something useful
noremap Q gq

"make Y consistent with C and D
nnoremap Y y$

"nmap <leader>v :vsplit<CR> <C-w><C-w>
"nmap <leader>s :split<CR> <C-w><C-w>

" Open URL from this line (OS X only).
map <leader>u :call OpenURI()<CR>

" Tab/shift-tab to indent/outdent in visual mode.
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv
" Keep selection when indenting/outdenting.
vnoremap > >gv
vnoremap < <gv
