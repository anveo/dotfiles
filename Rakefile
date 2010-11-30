require 'rake'

desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    next if %w[Gemfile Rakefile README LICENSE scripts vimfiles].include? file

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

  # link scripts
  system %Q{ln -s "$PWD/scripts" "$HOME/scripts"}
  system %Q{mkdir -p "$HOME/bin"}
  system %Q{mkdir -p "$HOME/local/bin"}
  system %Q{ln -s "$PWD/scripts/vcprompt.py" "$HOME/local/bin/vcprompt.py"}
  system %Q{ln -s "$PWD/scripts/phpm/phpm" "$HOME/local/bin/phpm"}

  # link vimfiles
  system %Q{ln -s "$PWD/vimfiles" "$HOME/.vim"}
  system %Q{ln -s "$PWD/vimfiles/.vimrc" "$HOME/.vimrc"}
end

def replace_file(file)
  system %Q{rm "$HOME/.#{file}"}
  link_file(file)
end

def link_file(file)
  puts "linking ~/.#{file}"
  system %Q{ln -s "$PWD/#{file}" "$HOME/.#{file}"}
end
