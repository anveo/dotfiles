require 'rake'

IGNORE_FILES = %w[Gemfile Rakefile README LICENSE extras scripts vimfiles default.gems]

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

    contents = File.read(source) rescue ""

    if contents.include?('<.replace ')
      info "#{source} has <.replace> placeholders."

      contents.gsub!(/<\.replace (.+?)>/) {
        begin
          File.read(File.expand_path("~/.#{$1}"))
        rescue => e
          error "Could not replace `#{$&}`: #{e.message}"
          ""
        end
      }

      File.open(destination, 'w') {|f| f.write contents }
      info_cmd "wrote file #{destination}"
    else
      FileUtils.ln_s(source, destination)
      info_cmd "ln -s #{source} #{destination}"
    end
  end

  # link blender configs
  system %Q{ln -fs "$PWD/extras/blender" "$HOME/.blender"}

  # link scripts
  system %Q{ln -nfs "$PWD/scripts" "$HOME/scripts"}

  # link atom configs
  # system %Q{mkdir -p "$HOME/.atom"}
  # system %Q{ln -fs "$PWD/atom/config.cson" "$HOME/.atom/config.cson"}
  # system %Q{ln -fs "$PWD/atom/init.coffee" "$HOME/.atom/init.coffee"}
  # system %Q{ln -fs "$PWD/atom/keymap.cson" "$HOME/.atom/keymap.cson"}
  # system %Q{ln -fs "$PWD/atom/styles.less" "$HOME/.atom/styles.less"}

  # link vimfiles
  system %Q{ln -nfs "$PWD/vimfiles" "$HOME/.vim"}
  system %Q{ln -fs "$PWD/vimfiles/.vimrc" "$HOME/.vimrc"}
end
