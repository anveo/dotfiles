"allow backspacing over everything in insert mode
set backspace=indent,eol,start

"store lots of :cmdline history
set history=1000

" Set temporary directory (don't litter local dir with swp/tmp files)
set directory=/tmp/

set showcmd     "show incomplete cmds down the bottom
set showmode    "show current mode down the bottom

set incsearch   "find the next match as we type the search
set hlsearch    "hilight searches by default

set nowrap      "dont wrap lines
set linebreak   "wrap lines at convenient points

"indent settings
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent

" Show line numbers
set number
set numberwidth=3

" Ignore case
set ignorecase
" Case sentisive searching if using uppercase letter
set smartcase

" Don't highlight search matches
" "set nohlsearch

" Use _ as a word-separator
"set iskeyword-=_

"folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=3       "deepest fold is 3 levels
set nofoldenable        "dont fold by default

set wildmode=list:longest:full   "make cmdline tab completion similar to bash
set wildmenu                "enable ctrl-n and ctrl-p to scroll thru matches

"stuff to ignore when tab completing and CommandT
set wildignore+=*~,*.scssc,*.sassc,*.png,*.PNG,*.JPG,*.jpg,*.GIF,*.gif,*.dat,*.doc,*.DOC,*.log,*.pdf,*.PDF,*.ppt,*.docx,*.pptx,*.wpd,*.zip,*.rtf,*.eps,*.psd,*.ttf,*.otf,*.eot,*.svg,*.woff,*.mp3,*.mp4,*.m4a,*.wav,"log/**","vendor/**","coverage/**","tmp/**"
" Disable output and VCS files
"set wildignore+=*.o,*.out,*.obj,*.rbc,*.rbo,*.class,.svn,*.gem
"" Disable archive files
"set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
"" Ignore bundler and sass cache
"set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*
"" Ignore librarian-chef, vagrant, test-kitchen and Berkshelf cache
"set wildignore+=*/tmp/librarian/*,*/.vagrant/*,*/.kitchen/*,*/vendor/cookbooks/*
"" Ignore rails temporary asset caches
"set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*
"" Disable temp and backup files
"set wildignore+=*.swp,*~,._*

set complete-=i

"some stuff to get the mouse going in term
set mouse=a
if !has('nvim')
  set ttymouse=xterm2
endif

"tell the term has 256 colors
set t_Co=256

"hide buffers when not displayed
set hidden

"Jump 5 lines when running out of the screen
set scrolljump=5

"Indicate jump out of the screen when 3 lines before end of the screen
set scrolloff=3

" tmux will only forward escape sequences to the terminal if surrounded by a DCS sequence
" http://sourceforge.net/mailarchive/forum.php?thread_name=AANLkTinkbdoZ8eNR1X2UobLTeww1jFrvfJxTMfKSq-L%2B%40mail.gmail.com&forum_name=tmux-users
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" load .bashrc
"set shellcmdflag=-ic
