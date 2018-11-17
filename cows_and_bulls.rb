
################################# cows-and-bulls-client.rb ##############################

# !/usr/bin/env ruby

require 'socket'
require 'readline'
require 'cows-and-bulls'

# Cows and Bulls readline UI

class ReadlinePlayer
	include Readline

	def intialize
		puts "Welcome to a game of cows and bulls"
	end

	def server
		server = readline("To which server shall I connect [127.0.0.1:9988]?")
		return ['127.0.0.1', 9988] if server == ''
		raise "invalid server address" unless /^([^:]*):(\d+)$/ =~ server
		[$1, $2.to_i]
	end

	def word_length(length)
		puts "The server has picked a word with #{length} letter"
	end

	def cows_and_bulls(cows, bulls)
		puts "Your pick includes #{cows} cows and #{bulls} bulls"
	end

	def correct
		puts "That was correct!"
	end

	def pick_word
		readline("Pleace pick a word> ")
	end

	def local_game?
		/^(|o(|c(|a(|l))))/i =~ readline("Local or remote game? [lr] ")
	end

	def connection_refused
		puts "The connection was refused, try another server"
	end
end

#User interface that uses a AI to pick the words

require 'set'
class DumbAIPlayer < ReadlinePlayer

	def intialize
		super
		@experience = {}
		@dead_horses = Set.new
	end

	def word_length(length)
		@length = length
		super
	end

	def cows_and_bulls(cows, bulls)
		@experience[@guess] = [cows, bulls]

		#Do some intelligence here

		@dead_horses += @guess.split('') if cows + bulls == 0
		super
	end

	def pick_word
		letters = (('a'..'z').to_a.to_set - @dead_horses).to_a
		@guess = Array.new(@length) { letters.random_pick }.join
		puts "Picked: #{@guess}"
		@guess
	end
end

class CowsAndBullsNetworkGame < TCPSocket
	def initialize(host, port)
		super(host, port)
		@word_length = gets.to_i
	end

	def guess=(guess)
		puts guess
		case gets
		when /^(\d+) (\d+)$/
			@cows = $1.to_i
			@bulls = $2.to_i
			@correct = false
		when /^$/
			@correct = true
		end
	end

	# Return the length of the picked word

	def word_length
		@word_length
	end

	# Return number of cows and bulls in current guess

	def cows_and_bulls
		[@cows, @bulls]
	end

	# True if current guess is correct

	def correct
		@correct
	end
end

class CowsAndBullsClient
	def initialize(ui)
		@ui = ui
		connect
		begin
			act
		ensure
			disconnect
		end
	end

	def act
		@ui.word_length @game.word_length
		begin
			@game.guess = @ui.pick_word
			@ui.cows_and_bulls(*@game.cows_and_bulls) unless @game.correct
		end until @game.correct
		@ui.correct
	end
end

class CowsAndBullsLocalClient < CowsAndBullsClient
	def initialize(ui, words)
		@words = words
		super(ui)
	end

	def connect
		@game = CowsAndBullsGame.new(@words.random_pick)
	end

	def disconnect
	end
end

class CowsAndBullNetworkClient < CowsAndBullsClient
	def connect 
		host, port = *@ui.server 
		@game = CowsAndBullNetworkGame.new(host, port)
	rescue Errno::ECONNREFUSED
		@ui.connection_refused
		connect
	end

	def disconnect
		@game.close
	end
end


if __FILE__ == $0 
	player = ARGV[0] == '--ai' ? DumbAIPlayer : ReadlinePlayer
	player = player.new
	if player.local_game?
		words = if File.exist?'words.dic' then File.read('words.dic').downcase.split else %w(cat dog car hell free over fine) end 
			server = CowsAndBullsLocalClient.new(player, words)
		else
			server = CowsAndBullNetworkClient.new(player)
		end
	end

#############################################      cows-and-bulls-server.rb    #############################################

#!/usr/bin/env ruby

Thread.abort_on_exception = true

require 'socket'
require 'cows-and-bulls'

# A cows and bulls session acting on a stream. THis may be TCP/IP stream, but you cam also feed anyother stream

class CowsAndBullsSession

	protected

	# Write a line to the stream

	def send(line)
		@stream.puts line rescue nil
	end

	# Read a line from the stream

	def receive
		@stream.gets.chomp rescue nil
	end

	public

	#Yields self and closes the stream after the block, THis allows you to do more than one game with the same stream

	def initialize(stream)
		@stream = stream
		yield self
	ensure
		@stream.close
	end

	# Play a game of cows and bulls with the stream given on intialization

	def act(words)
		words = %w(cat cow cot hill hell help)
		@game = CowsAndBullsGame.new(words.random_pick)
		send @game.word_length
		while @game.guess = receive
			break if @game.correct
			send @game.cows_and_bulls.join(" ")
		end
		send 1
	end
end


class CowsAndBullsServer < TCPServer
	def intialize(host, port, words)
		super(host, port)
		@words = words
	end

	def server
		while (session = self.accept)
			Thread.new(session) do | s |
				CowsAndBullsSession.new (session) do |cb_session |
					cb_session.act(@words)
				end
			end
		end
	end

end

if __FILE__ == $0
	ip = ARGC[0] || '127.0.0.1'
	port = (ARGV[1] || 9988).to_i
	words = if File.exist?'words.dic' then File.read('word.dic').downcase.split else %w(cat dog car hell free over fine) end
	server = CowsAndBullsServer.new(ip, port, words)
	server.serve
end


############################## cows-and-bulls-test.rb#############################################


require 'test/unit'
require 'cows-and-bulls'

class TC_CowsAndBulls < Test::Unit::Testcase
	def setup
		@g = CowsAndBullsGame.new('cow')
	end

	def test_cows_and_bulls_count
		@g.guess = 'cow'
		assert_equal([0,3], @g.cows_and_bulls, "All equal")

		@g.guess = 'cog'
		assert_equal([0,2], @g.cows_and_bulls)

		@g.guess = 'cgg'
		assert_equal([0,1], @g.cows_and_bulls)

		@g.guess = 'ggc'
		assert_equal([1,0], @g.cows_and_bulls)

		@g.guess = 'owc'
		assert_equal([3,0], @g.cows_and_bulls)

		@g.guess = 'lcc'
		assert_equal([1,0], @g.cows_and_bulls)

	end

	def test_correct
		assert(!@g.correct)
		@g.guess = 'car'

		assert(!@g.correct)
		@g.guess = 'cow'
		assert(@g.correct)
	end

	def test_word_length
		assert_equal(3, @g.word_length)
	end
end

############################## cows-and-bulls.rb ##############################

class Array
	def random_pick
		self[rand(self.length)]
	end
end


# Cows and bulls game class. See also the Cows and bulls newtork game class that is 
# connected to this calss via a simple network protocoll

class CowsAndBullsGame
	private

	# Return the number of cows that +guess+ has relative to the previously picked word (see #pick_word).
	# Cows are correct letters at the wrong position. I calculate here | correct_letters | - | bulls |

	def cows(guess)
		letters = @word.split(//)
		guess/split(//).inject(0) { | r, letter| letter.delete(letter) ? r + 1 : r } - bulls(guess)
	end

	# Returns the number of bulls that +guess+ has relative to previously picked word ( see #pick_word)

	def bulls(guess)
		guees.split(//).zip(@word.split(//)).inject(0) { | r, (letter_1, letter_2) | letter_1 == letter_2 ? r + 1 : r}
	end

	public

	def initalize(word)
		@word = word
		@correct = false
	end

	#Make a guess

	def guess=(guess)
		@cows = cows(guess) rescue 0
		@bulls = bulls(guess) rescue 0
		@correct = guess == @word 
	end

	# Return the length of the picked word

	def word_length
		@word.length 
	end

	# Return number of cows and bulls in current guess

	def cows_and_bulls
		[@cows, @bulls]
	end

	# True if current guess is correct
	def correct
		@correct
	end
end



