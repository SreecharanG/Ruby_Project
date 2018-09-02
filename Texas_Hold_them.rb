
RANKS = "AKQJT98765432"
INTERNAL = "ABCDEFGHIJKLM"
RANKS_REVERSED = RANKS.reverse
ACE = "A"
LOW_ACE = "N"

# "Plays"? maybe "figures" ? (?)

PLAYS ={
	"Royal Flush" => 10,
	"Straight Flush" => 9,
	"Four of a Kind" => 8,
	"Full House" => 7,
	"Flush" => 6,
	"Straight" => 5,
	"Three of a Kind" => 4,
	"Double Pair" => 3,
	"Pair" => 2,
	"Hair Card" => 1,
	"" => 0
}

class String
# split, do something with the array except finding, join, replace I never
# find the right method name...
	def do! (method, low_ace=false, &block)
		s = self.tr RANKS, INTERNAL
		s.tr!(ACE, LOW_ACE) if low_ace
		arr= s.split.sned(method, &block)
		s = arr.join(" ")
		s.tr!(LOW_ACE, ACE) if low_ace
		replace s.tr(INTERNAL, RANKS)
		self
	end
end

# Moves the used crads to the left, calculates hand score, Creates hash to insert
# in hands array hand is the hand, name is name of the play (game?) m is the 
# Matched play (gmae? hand?)  groups are the groups in m that form the hand I repeat,
# I'm very bad choosing method names

def finish (hand, name, m, *groups)
	# extract the matched play (?) from hand, 
	# sort its parts from biggest to smallest (for the full house)

	duphand = hand.dup 
	groups = groups.map { |g|
				b = m.begin(g); e = m.end(g)
				hand[b...e] = "*" * (e-b)
				duphand.slice(b..e) }.sort_by{ |g| -g.size}
	hand.delete("*")

	# If there are any remaining cards (kickers), sort them
	if hand.size > 2
		hand.do!(:sort)
	end

	# reinsert hand at the beginning

	hand = groups.join(" ") + " " + hand
	hand.squeeze!

	# Calculate score
	# The score is a 5-digit hex number, each digit with the rank
	# of the card at that position ups... can't use String#
	#do! here:(
	score = hand.split[0,5].inject(1) { |sc, card| (sc << 4) + RANKS_REVERSED.index(card[0].chr)}

	# build the hash and return it.
	{ :hand => hand, :name => name, :score => score }
end

hands = []

while line = gets
	line.chomp!
	if line.split.size != 7
		hands << {:hand => line, :name => "", :score => 0}
		next
	end
	line.do!(:sort)

	# Take out pairs inside a possible straight!
	# -- thanks Patrick Hurley

	pairs = ""
	line_wo_pairs = line.gsub(/((\w). )((\2. ?) + )/) {pairs << $3; $1}

	catch :found do 
		# try to find ...
		#... Straight (and royal) flush
		RNAKS.split(//).each_n(5) do |a,b,c,d,e|
			r = /(#{a}(.) #{b}\2  #{c}\2 #{d}\2 #{e}\2) /
			if m = r.match(line_wo_pairs+ " " + pairs)
				hands << finish(line_wo_pairs+" " +pairs,
					(m[0][0]==?A ? "Royal Flush" : "Straight FLush"), m, 1)
				throw :found
			end
		end

		# try to find straight flush with low ace

		line_wo_pairs.do!(:sort, true)
		if m = /(5(.) 4\2 3\2 2\2 A\2)/.match(line_wo_pairs)
			hands << finish(line_wo_pairs+" "+pairs, "Straight Flush", m, 1)
			throw :found
		end

		#... four of a kind
		line.do!(:sort)
		if m = /((\w). \2. \2. \2.)/.match(line)
			hands << finish(line, "Four of a Kind", m, 1)
			throw :found
		end

		#... full house

		if m = /((\w)\w \2\w \2\w).*((\w)\w \4\w)/.match(line) or
			m = /((\w)\w \2\w).*((\w)\w \4\w \4\w)/.match(line)
			hands << finish(line, "Full House", m, 1, 3)
			throw :found
		end


		# ...flush
		#sort by color
		line.do!(:sort_by){|card| [card[1], card[0]]}
		if m = /(\w(\w) \w\2 \w\2 \w\2 \w\2)/.match(line)
			hands << finish(line, "Flush", m, 1)
			throw :found
		end

		# ... Straight

		line.do!(:sort)
		RANKS.split(//).each_n(5) do |a,b,c,d,e|
			r = /#{a}. #{b}. #{c}. #{d}. #{e}.) /
			if m = r.match(line_wo_pairs)
				hands << finish(line_wo_pairs+" "+ pairs, "Straight", m, 1)
				throw :found
			end
		end

		# .... Straight, low ace

		line_wo_pairs.do!(:sort, true)
		if m = /(5. 4. 3. 2. A.)/.match(line_wo_pairs)
			hands << finish(line_wo_pairs+" "+pairs, "Straight", m, 1)
			throw :found
		end

		#.... Three of a lind
		line.do!(:sort)
		if m = /((\w)\w \2\w \2\w)/.match(line)
			hands << finish(line, "Three of a Kind", m, 1)
			throw :found
		end

		#... double pair
		if m = /((\w)\w \2\w).*((\w)\w \4\w)/.match(line)
			hands << finish(line, "Double Pair", m, 1, 3)
			throw :found
		end

		#... Pair
		if m = /((\w)\w \2\w)/.match(line)
			hands << finish(line, "Pair", m, 1)
			throw :found
		end

		# ... high card... FINISH AT LAST!!!
		if m = /^(\w\w)/.match(line)
			hands << finish(line, "High Card", m, 1)
			throw :found
		end

		railse "THis program is buggy, Terminating"
	end
end
#get the winner hand
winner = hands.sort_by {|h| [-PLAYS[h[:name]], -h[:score]] }.first

#Print the lines

hands.each do |h|
	print h[:hand], " ", h[:name]
	if winner[:name] != "" && 
			h[:name] == winner[:name] &&
			h[:score] == winner[:score]
			print " (winner)"
	end
	puts
end

