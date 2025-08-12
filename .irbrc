require 'rubygems'
require 'irb/completion'

# For vim integration
begin
  require 'interactive_editor'
rescue LoadError
  puts "interactive_editor is not installed. To enable, run: gem install interactive_editor"
end

# http://drnicutilities.rubyforge.org/map_by_method/
begin
  require 'map_by_method'
rescue LoadError
  puts "map_by_method is not installed. To enable, run: gem install map_by_method"
end

# Dr Nic's gem inspired by
# http://redhanded.hobix.com/inspect/stickItInYourIrbrcMethodfinder.html
begin
  require 'what_methods'
rescue LoadError
  puts "what_methods is not installed. To enable, run: gem install what_methods"
end

# Pretty Print method
require 'pp'

# Awesome Print gem (gem install awesome_print)
begin
  require 'awesome_print'
rescue LoadError
  puts "awesome_print is not installed. To enable, run: gem install awesome_print"
end

# Print information about any HTTP requests being made
begin
  require 'net-http-spy'
rescue LoadError
  puts "net-http-spy is not installed. To enable, run: gem install net-http-spy"
end

# Draw ASCII tables
begin
  require 'hirb'
  require 'hirb/import_object'
  Hirb.enable
  extend Hirb::Console
rescue LoadError
  puts "hirb is not installed. To enable, run: gem install hirb"
end

begin
  # 'lp' to show method lookup path
  require 'looksee'
rescue LoadError
  puts "looksee is not installed. To enable, run: gem install looksee"
end

IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"

# Remove the annoying irb(main):001:0 and replace with >>
IRB.conf[:PROMPT_MODE] = :SIMPLE

# Load the readline module.
IRB.conf[:USE_READLINE] = true

# Automatic Indentation
IRB.conf[:AUTO_INDENT]=true

# Save History between irb sessions
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"

# Wirble is a set of enhancements for irb
# http://pablotron.org/software/wirble/README
# Implies require 'pp', 'irb/completion', and 'rubygems'
begin
  require 'wirble'
  Wirble.init

  # Enable colored output
  Wirble.colorize
rescue LoadError
  puts "wirble is not installed. To enable, run: gem install wirble"
end

# Clear the screen
def clear
  system 'clear'
  if ENV['RAILS_ENV']
    return "Rails environment: " + ENV['RAILS_ENV']
  else
    return "No rails environment - happy hacking!";
  end
end

# Load / reload files faster
# http://www.themomorohoax.com/2009/03/27/irb-tip-load-files-faster
def fl(file_name)
  file_name += '.rb' unless file_name =~ /\.rb/
  @@recent = file_name
  load "#{file_name}"
end

def rl
  fl(@@recent)
end

# Reload the file and try the last command again
# http://www.themomorohoax.com/2009/04/07/ruby-irb-tip-try-again-faster
def rt
  rl
  eval(choose_last_command)
end

# prevent 'rt' itself from recursing.
def choose_last_command
  real_last = Readline::HISTORY.to_a[-2]
  real_last == 'rt' ? @@saved_last : (@@saved_last = real_last)
end

# Method to pretty-print object methods
# Coded by sebastian delmont
# http://snippets.dzone.com/posts/show/2916
class Object
  ANSI_BOLD = "\033[1m"
  ANSI_RESET = "\033[0m"
  ANSI_LGRAY = "\033[0;37m"
  ANSI_GRAY = "\033[1;30m"

  # Print object's methods
  def pm(*options)
    methods = self.methods
    methods -= Object.methods unless options.include? :more
    filter = options.select {|opt| opt.kind_of? Regexp}.first
    methods = methods.select {|name| name =~ filter} if filter

    data = methods.sort.collect do |name|
      method = self.method(name)
      if method.arity == 0
        args = "()"
      elsif method.arity > 0
        n = method.arity
        args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")})"
      elsif method.arity < 0
        n = -method.arity
        args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")}, ...)"
      end
      klass = $1 if method.inspect =~ /Method: (.*?)#/
      [name, args, klass]
    end
    max_name = data.collect {|item| item[0].size}.max
    max_args = data.collect {|item| item[1].size}.max
    data.each do |item|
      print " #{ANSI_BOLD}#{item[0].to_s.rjust(max_name)}#{ANSI_RESET}"
      print "#{ANSI_GRAY}#{item[1].ljust(max_args)}#{ANSI_RESET}"
      print " #{ANSI_LGRAY}#{item[2]}#{ANSI_RESET}\n"
    end
    data.size
  end
end

## http://sketches.rubyforge.org/
#begin
  #require 'sketches'
  #Sketches.config :editor => 'mvim'
#rescue LoadError
  #puts "sketches is not installed. To enable, run: gem install sketches"
#end

# Easily print methods local to an object's class
class Object
  def local_methods
    (methods - Object.instance_methods).sort
  end
end

class Object
  # print documentation
  #
  # ri 'Array#pop'
  # Array.ri
  # Array.ri :pop
  # arr.ri :pop
  def ri(method = nil)
    unless method && method =~ /^[A-Z]/ # if class isn't specified
      klass = self.kind_of?(Class) ? name : self.class.name
      method = [klass, method].compact.join('#')
    end
    puts `ri '#{method}'`
  end
end

def copy(str)
  IO.popen('pbcopy', 'w') { |f| f << str.to_s }
end

def paste
  `pbpaste`
end

# load File.dirname(__FILE__) + '/.railsrc' if $0 == 'irb' && ENV['RAILS_ENV']
