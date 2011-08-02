require 'rake'

desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Gemfile Rakefile README LICENSE extras scripts vimfiles default.gems].include? file

    if File.exist?(File.join(ENV['HOME'], ".#{file}"))
      if replace_all
        replace_file(file)
      else
        print "overwrite ~/.#{file}? [ynaq] "
        case $stdin.gets.chomp
        when 'a'
          replace_all = true
          replace_file(file)
        when 'y'
          replace_file(file)
        when 'q'
          exit
        else
          puts "skipping ~/.#{file}"
        end
      end
    else
      link_file(file)
    end

  end

  # link weechat scripts
  system %Q{mkdir -p $HOME/.weechat/perl/autoload}
  system %Q{mkdir -p $HOME/.weechat/python/autoload}
  system %Q{ln -fs "$PWD/extras/weechat/buffers.pl" "$HOME/.weechat/perl/autoload/buffers.pl"}
  system %Q{ln -fs "$PWD/extras/weechat/toggle_nicklist.py" "$HOME/.weechat/python/autoload/toggle_nicklist.py"}

  # link scripts
  system %Q{ln -nfs "$PWD/scripts" "$HOME/scripts"}
  system %Q{mkdir -p "$HOME/bin"}
  system %Q{mkdir -p "$HOME/local/bin"}
  system %Q{ln -fs "$PWD/scripts/vcprompt.py" "$HOME/local/bin/vcprompt.py"}
  system %Q{ln -fs "$PWD/scripts/phpm/phpm" "$HOME/local/bin/phpm"}

  # link vimfiles
  system %Q{ln -nfs "$PWD/vimfiles" "$HOME/.vim"}
  system %Q{ln -fs "$PWD/vimfiles/.vimrc" "$HOME/.vimrc"}

  if File.directory?(File.expand_path("~/.rvm"))
    system %Q{rm "$HOME/.rvm/gemsets/default.gems"}
    system %Q{ln -fs "$PWD/default.gems" "$HOME/.rvm/gemsets/default.gems"}
  else
    puts "Please install RVM and re-run this script to set gem defaults."
  end
end

def replace_file(file)
  system %Q{rm "$HOME/.#{file}"}
  link_file(file)
end

def link_file(file)
  puts "linking ~/.#{file}"
  system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
end
