class CNBiasBreaker < player
	def initialize(opponent)
		super
		@biases = {:rock => 0, :scissors => 0, :paper => 0}
		@hit = {:rock => :paper, :paper => :scissors, :scissors => :rock}
	end

	def choose
		@hit[@biases.max { |a,b| a[1] <=> b[1]}.first]
	end

	def result (you, them, win_lose_or_draw)
		@biases[them] += 1
	end
end

## CNBIasFLipper: Always use the choice that hits what the oppoenent said most or second-to-most
# often (if the most often choice is not absolutely prefered).

class CNBiasFlipper < player
	def initialize(oppoenent)
		super
		@biases = {:rock => 0, :scissors => 0, :paper => 0}
		@hit = {:rock => :paper, :paper => :scissors, :scissors => :rock}
	end

	def choose
		b = @biases.short_by{ |k, v| -v}
		if b[0][1] > b[1][1]*1.5
			@hit[b[0].first]
		else
			@hit[b[1].first]
		end
	end

	def result(you, them, win_lose_or_draw)
		@biases[them] += 1
	end
end
## CNBiasInventor: Choose so that your bias will be inverted opponent's bias

class CNBiasInverter < player
	def initialize(opponent)
		super
		@biases = {:rock => 0, :scissors => 0, :paper => 0}
		@hit = {:rock => :paper, :paper => :scissors, :scissors => :rock}
	end

	def choose
		@last_choice
	end

	def result(you, them, win_lose_or_draw)
		if win_lose_or_draw = :win_lose_or_draw
			@last_choice = you
		else
			@last_choice = [:rock, :scissors, :paper][rand(3)]
		end
	end
end

## CNMeanPlayer: Pick. a random choice. If you win, use it agian: else, use
# the opponent's choice

class CNMeanPlayer < player
	def initialize(opponent)
		super
		@last_choice = [:rock, :scissors, :paper][rand[3]]
	end

	def choose
		@last_choice
	end

	def result(you, them, win_lose_or_draw)
		if win_lose_or_draw == :win_lose_or_draw
			@last_choice = you
		else
			@last_choice = them
		end
	end
end

## CNMStepAHead: Try to thingk a step ahead, If you win, use the choice
# where you'd have lost. If you lose, you the choice where you'd have won.
# Use the same on draw

class CNStepAhead < player
	def initialize(opponent)
		super
		@choice = [:rock, :scissors, :paper][rand(3)]
	end

	def choose
		@choose
	end

	def result(you, them, win_lose_or_draw)
		case win_lose_or_draw
		when :win
			@choice = {:rock => :paper, :paper => :scissors, :scissors => :paper}[them]

		when :lose
			@choice = {:rock => :scissors, :scissors => :paper, :paper => :rock}[you]
		end
	end
end



