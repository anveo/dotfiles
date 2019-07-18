require 'rake'

IGNORE_FILES = %w[Brewfile Gemfile Rakefile README.md README.linux.md LICENSE extras scripts vimfiles default.gems]

def error(text) STDERR.puts "!  #{text}" end
def info(text, prefix="*") STDOUT.puts "#{prefix}  #{text}" end
def info_cmd(text) info(text, ">") end
def info_rm(text) info(text, "x") end

desc "install the dot files into user's home directory"
task :install do
  replace_all = false
  Dir['*'].each do |file|
    source = File.join(Dir.pwd, file)
    basename = File.basename(source)
    next if IGNORE_FILES.include?(basename)

    destination = File.expand_path("~/.#{basename}")
    if File.symlink?(destination)
      symlink_to = File.readlink(destination)
      info_rm "Removing symlink #{destination} --> #{symlink_to}" if symlink_to != source
      FileUtils.rm(destination)
    elsif File.exist?(destination)
      error "#{destination} exists. Will not automatically overwrite a non-symlink. Overwrite (y/n)?"
      print "? "
      if STDIN.gets.match(/^y/i)
        info_rm "Removing #{destination}."
        FileUtils.rm_rf(destination)
      else
        next
      end
    end

    FileUtils.ln_s(source, destination)
    info_cmd "ln -s #{source} #{destination}"
  end

  # link blender configs
  #system %Q{ln -fs "$PWD/extras/blender" "$HOME/.blender"}
  #
  info_cmd 'mkdir -p "$HOME/tmp'

  # link scripts
  info_cmd 'ln -nfs "$PWD/scripts" "$HOME/scripts"'

  # link vimfiles
  info_cmd 'ln -nfs "$PWD/vimfiles" "$HOME/.vim"'
  info_cmd 'ln -fs "$PWD/vimfiles/.vimrc" "$HOME/.vimrc"'
  ## neovim
  info_cmd 'mkdir -p "$HOME/.config'
  info_cmd 'ln -fs "$HOME/.config/nvim" "$HOME/.vim"'
end
