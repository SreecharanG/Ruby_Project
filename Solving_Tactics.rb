#!/usr/bin/ruby -w

NEW_GAME = 0b0000_0000
END_GAME = 0b1111_1111

POSSIBLE_MOVES= [1, 2, 3, 4, 5, 6, 7, 8, 12, 14, 15, 16, 17, 32, 34, 
				48, 64, 68,  96, 112, 128, 136, 192, 224, 240]

# Wins_of_first and wins_of_second

$f = $s = 0

# last_move_by - True for second player
# false for first palyer

def play( state, last_move_by, possible_moves)
	possible_moves.delete_if { |m| state & m != 0 }
	if state != END_GAME
		possible_moves.each do |m|
			play( state | m, ! last_move_by, possible_moves.clone)
		end
	elsif last_move_by # last move was by second player
		$f += 1
	else
		$s += 1
	end
end

paly( NEW_GAME, true, POSSIBLE_MOVES)

puts "Wins of first == #{$f}\nWins of second == #{$s}", "#{$f < $s ? 'First' : 'Second'} player is bounded to win"
