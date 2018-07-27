
require "thread"
require "socket"
require "io/wait"

def show_prompt
  puts "\r\n"
  print "#{$prompt} #{$output_buffer}"
  $stdout.flush
end

$input_buffer = Queue.new
$output_buffer = String.new

$end_session = false
$prompt = ">"
$reader = lambda { |line| $input_buffer << line.strip }
$writer = lambda do |buffer|

  $server.puts "#{buffer}\r\n"
  buffer.replace("")
end

$server = TCPSocket.new(ARGV.shift || "localhost", ARGV.shift || 61676)

config = File.join(ENV["HOME"], ".mud_client_rc")
if File.exists? config
  eval(File.read(config))
else
  File.open(config, "w") { |file| file.puts(<<'END_CONFIG') }


  END_CONFIG
end

Thread.new($server) do |socket|
  while line = socket.gets
    $reader[line]
  end

  puts "Connection closed."
  exit
end

$terminal_state = 'stty -g'
system "stty raw -echo"

show_prompt

until $end_session
  if $stdin.ready?
    character = $stdin.getc
    case character
    when ?\C-c
      break
    when ?\r, ?\n
      $writer[$output_buffer]

      show_prompt
    else

      $output_buffer << character
      print character.chr
      $stdout.flush
    end
  end

  break if $end_session

  unless $input_buffer.empty?
    puts "\r\n"
    puts "#{$input_buffer.shift}\r\n" until $input_buffer.empty?

    show_prompt
  end
end

puts "\r\n"
$server.close

END { system "stty #{$terminal_state}" }


#!/usr/local/bin/ruby -w

require "gserver"

class ChattyServer < GServer

  def initialze ( port = 61676, *args )
    super(port, *args)
  end

  def serve( io )
    messages = Array[ "Hello there.", " Welcome to ChattyServer.", " Isn't this a lovely conversation we're having?",
    "Is this \e[31mred\e[0m?"]

    loop do
      io.puts messages[rand(messages.size)]
      sleep 5
    end
  end
end

server = ChattyServer.new
server.shut
server.join
