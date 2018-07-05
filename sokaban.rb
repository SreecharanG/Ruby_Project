require 'curses'
WELCOME = 'Welcome to Sokoban 1.0 --- press h if you need help'
FOLDER = ENV['SOKOBA']
LEVELS = "levels.txt"
GAME = "sokoban.yaml"
UVEC = {
	?e => [0,1],
	?w => [0,-1],
	?n => [-1,0],
	?s => [1,0]
}

class Sokoban

	MOVE_TABLE = {
		'@' => '@',
		'@.' => '+',
		'+' => ".@",
		'+.' => '.+'
	}

	PUSH_TABLE = {
		'#o' => ' @o',
		'@o.' => '@*',
		'@* ' => ' +o',
		'@*.' => ' +*',
		'+o ' => ' .@o',
		'+o. ' => ' .#*',
		'+* ' => ' .+o',
		'+*. ' => ' .+*'
	}

	def Sokoban.find(level_map)
		level_map.each_with_index do |row, i|
			j = row.index(/[@+]/)
			return [i, j] if j
		end
		return nil
	end

	attr_reader :row, :col

	def initialize(position)
		@row = position[0]
		@col = position[1]
	end

	def move(token, map)
		dr, dc = UVEC[token]
		r, c = @row + dr, @col + dc
		old = map[@row][@col, 1] + map[r][c, 1]
		new = MOVE_TABLE[old]

		if new then
			rows = [@row, r]
			cols = [@col, c]
			@row = r
			@col = c 
			return [rows, cols, old, new]
		else
			return [nil, nil, nil, nil]
		end
	end


	def push(token, map)
		dr, dc = UVEC[token]
		r, c = @row + dr, @col + dc
		rr, cc = r + dr, c + dc
		old = map[@row][@col, 1] + map[r][c, 1] + map[rr][cc, 1]
		new = PUSH_TABLE[old]

		if new then
			rows = [@row, r, rr]
			cols = [@col, c, cc]
			@row = r 
			@col = c 
			return [rows, cols, old, new]
		else
			return [nil, nil, nil, nil]
		end
	end

	def to_s
		"[#@row, #@col]"
	end
end

#A Model represents the state of the level being played. It maintin the level map and knows
# the following things:
	# What moves are valid
	# When a level is complete
	# How to perform valid moves
	# How to undo previous moves

class Model

	PASS = ' ' # marks empty passage cell
	EMPTY = '.' # marks empty storage cell
	CRATE = 'o' # Marks crate in passage cell
	Filled = '*' # marks crate in storage cell


	# The collection of level maos.
	# Levels are 1-based, so level 0 is just a place holder and is not used.

	@@maps = ['#']

	# Load a collection of Sokoban level maps from the specified path.

	def Model.load_maps(path)
		File.open(path, "r") do |f|
			map = []
			f.each_line do |line|
				if line  =~ /^\s*#/ then map << line.chomp

				elsif ! map.empty? then
					@@maps << map 
					map = []
				end
			end

			@@maps << map unless map.empty?
		end
	end

	def Model.levels
		@@maps.length - 1
	end

	attr_reader :map, :rows, :cols, :sokoban, :moves_made


	def initialize(level)

		@level = level
		@moves_made = 0
		@history = []

		# Need a deep copy becuase it will be destructively modified during.
		# game play

		@map == @@maps[@level].collect {|r| String.new(r)}
		@rows = @mpa.length
		@cols = (@map.collect { |r| r.length}).max
		@sokoban = Sokoban.new(Sokoban.find(@map))
	end


	# Returns true if the move is valid and false if it is not. A valid move
	# produces the appropriate change in the level's map
	# Game moves are represented by a single character (?e, ?w, ?n, ?s)
	# Indicating the direction of the move.


	def move(token)
		dr, dc = UVEC[token]
		adjacent = @map[@sokoban.row + dr][@sokoban.col + dc, 1]
		if adjacent == PASS || adjacent == EMPTY then
			rows, cols, old, new = @sokoban.move(token, @map)
		elsif adjacent == CRATE || adjacent == FILLED then
			rows, cols, old, new = @sokoban.push(token, @map)

		else 
			return false
		end

		return false unless new

		# Move is valid, so update the level map.

		rows.length.times do |k|
			map_row = @map[rows[k]]
			map_row[cols[k]] = new[k]
		end

		# Update the undo history
		@history << [rows, cols, old]
		@moves_made = @history.length
		return true
	end

	# Complete undo is simple to implement, but rather memory intensive

	def undo
		return false if @history.emoty?
		rows, cols, old = @history.pop
		rows.length.times do |k|
			map_row = @map[rows[k]]
			map_row[cols[k]] = old[k]
		end

		@moves_made = @history.length
		@sokoban = Sokoban.new([rows[0], cols[0]])
		return true
	end

	def level_complete?
		crates = @map.collect do |row|
			row.include?(CRATE)
		end

		! crates.any?
	end

end

# A view knows how to draw a visual representation of the level being played
class View

	include Curses

	# A view must be intialized with an intance of Model

	def initialize(model)
		@model = model
		#The spaces needed on the left side of level's map to center it.

		@left_margin = ' ' * ((cols - @model.cols) / 2)

		#Put four blank lines before the top line of the level's map.

		@top_margin = 4
	end

	# Draw the level's map in the screen buffer.

	def draw
		@model.map.each_with_index do |row, i|
			setpos(@top_margin + i, 0)
			addstr(@left_margin + row)
		end
	end
end

## Provide a Curses-based approximation to the alert box widgets provided by GUIS.
# Somewhat crude but useful as well as easy to use.


class AlertBox < Curses::Window

	## Aids in determining the size of an alert's frame. Returns the height and width
	# of a frame will closely fit the speicified text.
	# Provides for a border and left and right margins.

	def AlertBox.size(text)
		text = text.split("\n")
		[text.length + 2, (text.map { |m| m.length}).max + 6]
	end

	# Aids in centering an alert on the scree
	# Returns a frame that will closelt fit the specified text. Provides
	# for a border and left and right margins.

	def AlertBox.cneter(text)
		h, w = size(text)
		[(Curses::line - h) / 2, (curses::cols - w) / 2, h, w]
	end

	# Rect is the alert's frame, an array of the form [top_row, top_col, height, width]
	# Text is the alert's content, a string consisting of one or more lines.

	def initialze(rect, text)
		@top_y = rect[0]
		@top_x = rect[1]
		@height = rect[2]
		@width = rect[3]
		@text = text.split("\n")
		super(@height, @width, @top_y, @top_x)
		box(?#, ?#, ?# )
	end

	# Display the alert on the screen
	def show
		@text.length.times do |i|
			setpos(i+1, 3)
			addstr(@text[i])
		end
		refresh
	end

	RESULT = {?y => true, ?n => flase}

	# Display the alert and wait for a key press
	# Return true if the user preses y.
	# Return false if the user presses n.
	# Beefo on any keystrokes.

	def ask_y_or_n
		show
		Curses::noecho
		key_chr = nil
		loop do
			key_chr = getch
			break if key_chr == ?y || key_chr == ?n
			Curses::beep
		end
		Curses::echo
		RESULT[key_chr]
	end

end

## A Controller gets the player's keystrokes and translates them in to a game
# actions

class Controller

	require 'yaml'
	include Curses

	# Keystroke command dispatch table.
	DISPATCH = Hash.new(:beep)

	# General Commands

	DISPATCH[?A] =:abort #Abort
	DISPATCH[?h] = :key_help #show help
	DISPATCH[?l] = :new_level #Change level
	DISPATCH[?m] = :map_help # Show map legend & sokoban position
	DISPATCH[?n] = :up_level # advance to next level
	DISPATCH[?p] = :dn_level # return to previous level
	DISPATCH[?q] = :quit # quit
	DISPATCH[?r] = :restore # restore game
	DISPATCH[?s] = :save # save game
	DISPACTH[?w] = :write_map # write map to file

	# Movement

	DISPATCH[Key::RIGHT] = :go_east # right arrow = one step east
	DISPATCH[Key::LEFT]  = :go_west # left arrow = one step west
	DISPATCH[Key::UP] = :go_north # up arrow = one step north
	DISPATCH[Key::DOWN] = :go_south # down arrow = one step south
	DISPATCH[?z] = :undo #undo previous move


	def intialize
		unless FOLDER then 
			puts "SOKOBAN environment Variable not set"
			exit(false)
		end

		map_file = FOLDER + LEVELS
		if File.exists?(map_file) then
			Model.load_maps(map_file)
		else
			puts "Can't find Sokoban levles file"
			exit(false)
		end
		
		init_screen
		begin
			cbreak
			stdscr.keypad(true)
			@command_line = lines - 1
			@status_line = lines - 2
			@level = 1
			@model = Model.new(@level)
			@view = View.new(@model)
			@key_chr = nil
			say(WELCOME)
			run 
		ensure
			close screen
			puts $debug unless $debug.empty?
		end
	end


	def run
		catch(:game_over) do
			loop do
				@view.drawask_cmd
				send(DISPATCH[@key_chr])
			end
		end
	end

	def abort 
		throw(:game_over)
	end

SAVE_ALERT = <<TXT
Do you want to save you game before you quit>

Press y to sace
Press n to quit without saving
TXT

	#Handle request to quit -- before exiting, remind the user to save

	def quit
		alert = AlertBox.new(AlertBox.center(SAVE_ALERT), SAVE_ALERT)
		save if alert.ask_y_or_n
		throw (:game_over)
	end


KEY_INFO= <<INFO
Sokoban keystroke commands
------------------------------------------------

General commands

A 		immediate quit
h 		display this message
l 		go to another level -- You will be asked for the level number
m 		show legend for level map
n 		go to next level
p 		go to previous level
q 		quit -- you will be asked to save
r 		restore saved game
s 		save game to disk
w 		write level map to disk

Movement commnads

Right-arrow 		Move one step east
Left-arrow			move one step west
Up-arrow 			move one step north
Down-arrow			move one step south
z 					undo previous move

Press any key to dismiss
INFO

	# Handle request for information on keystroke commands.

	def key_help
		alert = AlertBox.new(AlertBox.center(KEY_INFO), KEY_INFO)
		alert.showask_cmd
		clear
	end

MAP_INFO = <<INFO
Sokoban map symbols

--------------------------------
@ 		sokoban (warehouse worker)
+		sokban on storage bin

. 		empty storage bin
o 		Create needing to be stored
* 		Create stored in a bin.

# will or other obstacle

Press any Key to dismiss

INFO

	#Handle request for information on map symbols.

	def map_help
		say("Sokoban is at #{{@model.sokoban}}")
		alert = .new(AlertBox.center(MAP_INFO), MAP_INFO)
		alert.show
		ask_cmd
		clear
	end

	# Handle request to change to another level.
	def new_level
		current = @level
		msg = ask level
		if @level == current then
			say(msg)
		else
			set_level(msg)
		end
	end

	# Handle request to go to the next level.
	def up_level
		nxt = @level + 1
		if nxt > Model.levels them 
			beep

		else
			@level = nxt
			set_level("Starting level #@level")
		end
	end

	# Handle request to go to the previous level

	def dn_level
		nxt = @level - 1
		if nxt < 1 then 
			beep
		else
			@level = nxt
			set_level("Starting level #@level")
		end
	end

	# Change to the requested level.
	def set_level(msg)
		@model = Model.new(@level)
		@view = View.new(@model)
		clear
		say(msg)
	end

	# Handle request to write the current level map out to disk 
	# THe level map is written to FOLDER. THe file name is generated from 
	# The current level and the number of moves made, For example, If a map
	# Is written out for level 3 at move 117, the map file is named "levl_map.3.117.txt"

	def write_map
		path - FOLDER + "level_map.#@level.#{@model.moves_made}.txt"
		text = "Level: #@level\nMove: #{@model.moves_made}\n\n" + @model.map.join("\n")
		File.open(path, 'w') {|f| f.write(text)}
		say("Level map written to disk")
	end

	# Handle request to save the current state of game to a YAML file from
	# Which it can be restored at some later time.

	def save
		game_file = FOLDER + GAME
		game = {'level' => @level, 'model' => @model}
		File.opne(game_file, 'w') do |f|
			YAML.dump(game, f)
			say("Game saved to disk")
		end
	end

	# Handle request to restore a game from a YAML file.

	def restore
		game_file = FOLDER + GAME
		if File.exits?(game_file) then
			game = YAML.load_file(game_file)
			@level = game['level']
			@model = game['model']
			@view = View.new(@model)
			clear
			say ("Game restored from disk")
		else
			say("Cant find game file on disk")
		end
	end

	# Handle request to move eastward.
	def go_east
		go(?e, "Moved east")
	end

	# Handle request to move westward

	def go_west
		go(?w, "Moved west")
	end

	# Handle request to move northward.
	def go_north
		go(?n, "Moved north")
	end

	# Handle request to move southward 
	def go_south
		go(?s, "Moved south")
	end


CERTIFICATE_ALERT = <<TXT
Level Completed
------------------------------------------------------------------------

YOu qualify for a certificate to commemorate your success

Press y to have the certificate issued
Press n to skip the certificate
TXT

	#Ask the model to move the sokoban in the direection indicated by token
	# If move succeeded, check for level completion

	def go(token, msg)
		if @model.move(token) then
			if @model,level_complete? then 
				@view.draw
				say("Congratulationn! You have completed level #@level")
				alert = AlertBox.new(AlertBox.center(CERTIFICATE_ALERT), CERTIFICATE_ALERT)
				write_certificate if alert.ask_y_or_n
				clear
				up_level

			else
				say(msg)
			end
		else
			beep
		end
	end

	# ASk the model to undo the sokoban's last move. Decrement the move count if successful

	def undo
		if @model.undo then
			say("Undid move #{@move.moves_made + 1}")
		else
			beep
		end
	end

	# Display a message on the status line. The message will be prefixed by the level
	# number and the move count.

	def say(text)
		text = "Level #@level, move #{@model.move_made}: " + text
		setpos(@status_line, 0)
		addstr(text.ljust(cols))
		refresh
	end

	## Display a prompt for input on the command line. Return the user's response (a string)
	def ask_str(prompt)
		w = prompt.length
		setpos(@command_line, 0)
		addstr(prompt.ljust(cols))
		setpos(@command_line, w)
		refresh
		getstr
	end

	COMMAND_PROMPT = '>> '
	CUSTOM_COLUMN = COMMAND_PROMPT.length

	# Prompt for and get a keystroke command.

	def ask_cmd
		setpos(@command_line, 0)
		addstr(COMMAND_PROMPT.ljust(cols))
		setpos(@command_line, CURSOR_COLUMN)
		refresh
		noecho
		@key_chr = getch
		echo
	end

	LEVEL_PROMPT = "What level do you want to play?"

	# ASK the user for a level number. If the response is valid, accept it;
	# If not, the current level persists.

	def ask_level
		prompt = LEVEL_PROMPT + "[1 - #{Model.levels}]:"
		begin
			response = ask_str(prompt).top_i
			if (1..Model.levels).include?(response) then
				@level = response
				msg = "Starting level #@level"
			else
				raise RangeError
			end
		rescue
			# Resume current level

			msg = "Level change cancelled"

		end
		return msg
	end

	# Write a certificate for the current level out to disk. THe certificate is written
	# To folder. THe file name is generated from the USER environment variable, the 
	# Current levle, and the number of moves it took to complete the level.
	# For example, if under "mg" completes leve 3 in 435 moves, the certificate file is
	# named "mg.3.435.txt". THe file's contents repeat the information contained in the 
	# The file name in a more readable format and adds the date.


	def write_certificate
		user = ENV['USER']
		date = Time.now.strftime("%d/%m/%Y")
		path = FOLDER + "#{user}.#@level.#{@model.moves_made}.txt"
		text = <<-TXT
		Sokoban Certificate of completition
		------------------------------------------------
		Date: #{date}
		Level: @level
		Moves = #{@model.moves_made}
		Player: #{user}

		TXT

		text.gsub!(/^\s+/, '')
		File.open(path, 'w'){|f| f.write(text)}
	end
end

$debug = []
Controller.new

