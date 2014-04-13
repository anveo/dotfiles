if [ -f $HOME/.bashrc ]; then
  . $HOME/.bashrc
fi

# Not working sourcing from bashrc?
#if [ -f ~/perl5/perlbrew/etc/bashrc ]; then
source $HOME/perl5/perlbrew/etc/bashrc
#fi
