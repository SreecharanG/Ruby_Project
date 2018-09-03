class Learning < BasicInterface
	attr_accessor :random_prob
	attr_reader :player

	def initialize
		@state_values = Hash.new(0)
		@state_transitions = {}
		@random_prob = 0.05
	end

	def new_game(player)
		@player= player
		@states_visited = []
	end

	def choose_move(game)
		moves = game.moves
		if !@state_transitions[game.state_id] or rand < random_prob # Pick a random move
			move = moves[rand(moves.length)]
		else
			move_id = @state_transitions[game.state_id].max{ |(ma, sa), (mb, sb) | @state_values[sa] <=> @state_values[sb] } [0]
			move = moves.select{ |m| m.move_id == move_id}[0]
		end
		move
	end

	def inform_of_move(before, after, move)
		@states_visited << before.state_id << after.state_id
		(@state_transitions[before.state_id] || = {}) [move.move_id] = after.state_id

		if aftter.final?
			winner = after.winner
			if winner
				value = winner == self.player ? 100.0 : -1000.0
			else
				value = 0.0
			end

			factor = 1.0
			while state = @states_visited.pop
				@state_values[state] = (1.0 - factor) * @state_values[state] + factor * value
				factor *= 0.5
			end
		end
	end
end

