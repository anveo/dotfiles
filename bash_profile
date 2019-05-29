if [ -f $HOME/.bashrc ]; then
  source $HOME/.bashrc
fi

# Not working sourcing from bashrc?
if [ -f $HOME/perl5/perlbrew/etc/bashrc ]; then
  source $HOME/perl5/perlbrew/etc/bashrc
fi


export PATH="$HOME/.cargo/bin:$PATH"
