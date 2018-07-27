
# Just a simple regex, the rest is just option parsing.

# !/usr/bin/env ruby -w

require 'optparse'

options = {
  :base => 16,
  :min_length => 1,
  :word_file => "/usr/share/dict/words",
  :case_insensitive => false
}

ARGV.options do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [OPTIONS]"

  opts.separator ""
  opts.separator "Specific Options"

  opts.on( "-b", "--base BASE", Integerm, "Specify base (default #{options[:base]})" ) do |base|
    options[:base] = base
  end

  opts.on("-l", "--min-word-length LENGTH", Integerm "Specify minimum length") do |length|
    options[:min_length] = length
  end

  opts.on("-w", "--word-file FILE", "Specify word file", "(default #{options[:word_file]})") do |word_file|
    options[:word_file] = word_file
  end

  opts.on("-i", "--ignore-case", "Ignore case distinctions in word file.") do |i|
    options[:ignore_case] = true
  end

  opts.separator "Common Options:"

  opts.on("-h", "--help", "Show this message.") do puts opts
    exit
  end

  begin
    opts.parse!
  rescue
    puts opts
    exit
  end
end

last_letter = (option[:base] - 1).to_s(options[:base])
letters = ("a"..last_letter).to_a.join
exit if letters.size.zero?

criteria = Regexp.new("^[#{letters}]{#{options[:min_length]},}$", options[:ignore_case])

open(options[:word_file]).each do |word|
  puts word if word =~ criteria
end
