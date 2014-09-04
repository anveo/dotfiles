#!/bin/bash

DOTVIM="$HOME/.vim"

if [ ! -e `which git` ]
then
  echo "You need git. Try running install_git"
  exit 0
fi

if [ ! -d $DOTVIM ]
then
  mkdir $DOTVIM
fi

get_repo() {
    gh_user=$1
    repo=$2
    echo "Checking $repo"
    if [ -d "$DOTVIM/bundle/$repo/" ]
    then
        echo "Pulling latest from $repo"
        cd $DOTVIM/bundle/$repo
        git pull origin master
        cd ..
    else
        echo "Cloning repo for $repo"
        git clone git://github.com/$gh_user/$repo.git
    fi
}

echo "Creating .vim folders if necessary"
mkdir -p $DOTVIM/{autoload,bundle,ftdetect,syntax}
cd $DOTVIM/bundle/

tpope_repos=(rails rbenv haml git cucumber fugitive surround unimpaired abolish repeat markdown endwise ragtag vividchalk liquid bundler)

for r in ${tpope_repos[*]}; do
        repo="vim-$r"
    get_repo "tpope" $repo
done

echo "Installing NERDTree"
get_repo "scrooloose" "nerdtree"

echo "Installing Syntastic"
get_repo "scrooloose" "syntastic"

echo "Installing NERDCommenter"
get_repo "jc00ke" "nerdcommenter"

echo "Installing snipMate"
get_repo "msanders" "snipmate.vim"

echo "Installing vim-ruby"
get_repo "vim-ruby" "vim-ruby"

#echo "Installing vim-ruby-debugger"
#get_repo "astashov" "vim-ruby-debugger"

echo "Installing taglist.vim"
get_repo "jc00ke" "taglist.vim"

echo "Installing tagbar"
get_repo "majutsushi" "tagbar"

echo "Installing ack.vim"
get_repo "mileszs" "ack.vim"

echo "Installing supertab"
get_repo "ervandew" "supertab"

echo "Installing vim-indent-object"
get_repo "michaeljsmith" "vim-indent-object"

echo "Installed vim-textobj-user"
get_repo "kana" "vim-textobj-user"

echo "Installed vim-textobj-rubyblock"
get_repo "nelstrom" "vim-textobj-rubyblock"

echo "Installing git-vim"
get_repo "motemen" "git-vim"

echo "Installing vim-ruby-refactoring"
get_repo "ecomba" "vim-ruby-refactoring"

echo "Installing gundo"
get_repo "sjl" "gundo.vim"

echo "Installing vim-colors-solarized"
get_repo "altercation" "vim-colors-solarized"

echo "Installing mustache.vim"
#get_repo "juvenn" "mustache.vim"
get_repo "mustache" "vim-mustache-handlebars"

echo "Installing vim-coffee-script"
get_repo "kchmck" "vim-coffee-script"

echo "Installing glsl.vim"
get_repo "Nemo157" "glsl.vim"

echo "Installing vim-puppet"
get_repo "rodjek" "vim-puppet"

echo "Installing ctrlp"
get_repo "kien" "ctrlp.vim"

echo "Installing vim-css-color"
get_repo "ap" "vim-css-color"

echo "Installing vim-powerline"
get_repo "Lokaltog" "vim-powerline"

echo "Installing gitv"
get_repo "gregsexton" "gitv"

echo "Installing chrisbra"
get_repo "chrisbra" "csv.vim"

echo "Installing vim-processing"
get_repo "sophacles" "vim-processing"

echo "Installing delimitMate"
get_repo "Raimondi" "delimitMate"

echo "Installing bufexplorer"
get_repo "jlanzarotta" "bufexplorer"

echo "Installing vim-easy-align"
get_repo "junegunn" "vim-easy-align"

#echo "Installing vim-tmux-navigator"
#get_repo "christoomey" "vim-tmux-navigator"

echo "Installing vim-gitgutter"
get_repo "airblade" "vim-gitgutter"

echo "Installing vim-easymotion"
get_repo "Lokaltog" "vim-easymotion"

echo "Installing YankRing"
get_repo "vim-scripts" "YankRing.vim"

#echo "Installing YouCompleteMe"
#get_repo "Valloric" "YouCompleteMe"

echo "Installing vim-symbol-strings"
get_repo "anveo" "vim-symbols-strings"

#echo "Installing jQuery"
#JQUERY=15752

cd $DOTVIM

#curl http://www.vim.org/scripts/download_script.php?src_id=$JQUERY -o "syntax/jquery.vim"

# TODO: find new Gemfile syntax ... https://github.com/hron84/Gemfile.vim ???
#curl https://raw.github.com/jc00ke/Gemfile.vim/master/syntax/Gemfile.vim -o "syntax/Gemfile.vim"
#curl https://raw.github.com/jc00ke/Gemfile.vim/master/ftdetect/Gemfile.vim -o "ftdetect/Gemfile.vim"
#curl https://github.com/juvenn/mustache.vim/raw/master/syntax/mustache.vim -o "syntax/mustache.vim"
#curl https://github.com/juvenn/mustache.vim/raw/master/ftdetect/mustache.vim -o "ftdetect/mustache.vim"

cd $DOTVIM/autoload
echo "Fetching latest pathogen.vim"
curl -O https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim

echo "Checking to see if pathogen has already been added to .vimrc"
pathogen_cmd="call pathogen#infect('bundle/{}')"
contains=`grep "$pathogen_cmd" ~/.vimrc | wc -l`

if [ $contains == 0 ]
then
        echo "Hasn't been added, adding now."
        echo "$pathogen_cmd" >> ~/.vimrc
else
        echo "It was already added. Good to go"
fi
