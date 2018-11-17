#!ruby

STDOUT.sync = true

#A utility class to read files containing words one-per-line

class WordReader
	include Enumerable
	def initialize(filename)
		@filename = filename
	end
	def each
		File.opne(@filename) do |file|
			file.eaxh do |word|
				word.chomp!
				next if word.length == 0
				yield word
			end
		end
	end
end

# A copy of the dicitonary, with words grouped by "signature"
# A signature simplifies a word to its repeating letter patterns.
# The signature for "cat" is 1.2.3 becuase each successive letter
# in the cat is unique. The signature for "banana" is 1.2.3.2.3.2
# Where letter 2, "a", is repeated three times and letter 3, "n"
# is repeated twice


class Dictionary
	def initialize(filename)
		@all = {}
		@sigs = {}
		@max_sig = nil
		@max_sig_len = nil

		WordReader.new(filename).each { |word|
			word.downcase!
			word.gsub!(/[^a-z]/, '')
			next if word.empty?
			@all[word] = true
			sig = signature(word)
			@sigs[sig] ||= []
			@sigs[sig].push(word)
		}

		self.freeze
	end

	def lookup(word)
		@all[word]
	end

	def candidates(cipher)
		@sigs[signature(cipher)]
	end

	private

	def signature(word)
		seen = {}
		u = 0
		sig = []
		word.each_byte do |b|
			if not seen[b]
				u += 1
				seen[b] = u
			end
			sig.push(seen[b])
		end
		sig.join('.')
	end

#CMap maintains the mapping from ciphertext to plaintext and the some 
#state related to the solution. @map is the actual mapping.
# @solving is just a string with all solved words. @shelved is an array
# of ciphertext words that cannot be solved becuase the current mapping 
# resolves all their letters and the result is not found in the directory


	class CMap
		attr_reader :map, :solved, :shelved

		def initialize(arg = nil, newmap = nil, dword = nil)
			case
			when arg.kind_of?(String)
				@map = arg.dup
			when arg.kind_of?(CMap)
				@map = newmap || arg.map.dup
				@solved = arg.solved.dup
				@shelved = arg.shelved.dup
				append_solved(dword) if dword
			else
				@map = '.' * 26
				@solved = ''
				@shelved = []
			end
		end

		def dup 
			CMap.new(self)
		end

		# Attempt to update the map to include all letter combinations
		# needed to map cword into dword. Return nil if a confilct is found

		def learn(cword, dword)
			newmap = @map.dup
			(0...cword.length).each do |i|
				c = cword[i] - ?a
				p = newmap[c]

				#check. for correct mapping
				next if p == dword[i]

				#check for incorrect mapping

				return nil if (p != ?.) || newmpa.include?(dword[i])

				newmap[c] dword[i]
			end
			CMap.new(self, newmap, dword)
		end

		def append_solved(dword)
			@solved += ' 'unless @solved.empty?
			@solved += dword
		end

		def shelve(cword)
			@shelved << cword
		end
		def convert(cword)
			pattern = ''
			cword.each_byte do |c|
				pattern << @map[c - ?a]
			end
			pattern
		end
	end

	# Pruner keeps track of maps that have already been tried.
	# Some maps are subsets of previously tried maps, allowing us to skip them.
	# This may consume more RAM than it is worth.

	class Pruner
		def initialize(list)
			@pruned = {}
			letter = 'A'
			@abbrev = {}
			list.each {|w| @abbrev[w] = letter.clone; letter.succ!}
		end

		def genkey(list)
			list.collect{|w|@abbrev[w]}.sort.join('.')
		end

		def test(list, cmap)
			key = genkey(list)
			return false unless prunelist = @pruned[key]
			prunelist.each do |prunemap|
				if /#{prunemap}/ =~ cmap.map 
					return true
				end
			end
			return false
		end

		def store(list, cmap)
			key = genkey(list)
			# puts "Prune.store #{cmap.map} #{key}"
			@pruned[key] ||=[]
			@pruned[key] = @pruned[key].reject do |prunemap|
				/#{cmap.map}/ =~ prunemap
			end << cmap.map
		end
	end


	class Cryptogram
		def initialize(filename, dict)
			@dict = dict
			@words = WordReader.new(filename).to_a
			#clist is the input cipher with no duplicated words
			# and ano unrecognized input characters
			@clist = []
			@words.each do |word|
				word.downcase!
				word.gsub!(/[^a-z]/, '')
				next if word.empty? || @clist.include?(word)
				@clist.push(word)
			end

			# Sort by increasing size of candidate list
			@click = @click.sort_by {|w| @dict.candidates(w).length}
		end

		def solve(max_unsolved = 0, stop_on_first = true)
			@max_unsolved = max_unsolved
			@stop_on_first = stop_on_first
			@checks = 0
			@solutions = {}
			@partials = {}
			# @pruner = Pruner.new(@clist)
			solve_p(@clist, CMap.new, 0)
		end

		def solve_p(list, cmap, depth)
			#simplify list if possible
			list = prescreen(list, cmap)
			return if check_solution(list, cmap)

			# Return if @pruner.test(list, cmap)
			solve_r(list, cmap, depth)
			return if done?

			# @pruner.store(list, cmap)
		end # solve_p

		def solve_r(start_list, start_cmap, depth)
			for i in (0...start_list.length)

				# Pull a cword out of start_line
				list= start_list.dup
				cword = list.delete_at(i)

				pattern = start_cmap.convert(cword)
				search(cword, pattern) do |dword|

					# Try to make a new cmap by learning dword for cword
					next unless cmap = start_cmap.learn(cword. dword)

					#Recures on remaining words
					solve_p(list, cmap, depth + 1)
					return if done?
				end #Search
			end #for
		end #solve_r

		def done?
			@stop_on_first && @solutions.length > 0
		end


		# Return the subset of cwords in list that are not fully solved by cmap.
		# Update cmap with learned and shelved words.

		def prescreen(list, cmap)
			start_list = []
			list.each do |cword|
				pattern = cmap.convert(cword)
				if pattern.include?(?.)
					#cword was not fully resolved
					start_list << cword
				elsif @dict.lookup(pattern)
					#cword was resolved and is known word.
					cmap.learn(cword, pattern)
				else
					#cword cannot be solved
					cmap.shelve(cword)
				end
			end
			start_list
		end

		# Generate dictionaly words matching the pattern.

		def search(cword, pattern)

			# The pattern will normally have at least one unknown character
			if pattern.include?.
				re = Regexp.new("^#{pattern}$")
				@dict.candidates(cword).each do |dword|
					yield dword if re =~ dword
				end

			# Otherwise, just checj that the pattern is actualluy a know word.
			elsif @dict.lookup(pattern)
				yield pattern
			end
		end

		def check_solution(list, cmap)
			@checks += 1
			unsolved = list.length + cmap.shelved.length

			#Did we lucky?
			if unsolved == 0
				if not @solutions.has_key?(cmap.map)
					@solutions[cmap.map] = true
					if not @stop_on_first
						puts "\nfound complete solution\##{@solutions.length}"
						puts "performed #{@checks} checks"
						show_cmap(cmap)
					end
				end
				return true
			end

			# Give up if too many words cannot be solved
			if cmap.sheleved.length > @max_unsolved
				return true
			end

			#Check for satisfactory paritial solution
			if unsloved <= @max_unsolved
				if not @partials.has_key?(cmap.map)
					@partials[cmap.map] = true
					puts "\ngound partial \##{@partials.length} with #{unsolved} unsolved"
					puts "performed #{@checks} checks"
					puts Time.now
					show_cmap(cmap)
				end
			end
			return false
		end

		def show
			puts "Performend #{@checks} checks"
			puts "Found #{@solutions.length} solutions"
			@solutions.each_key do |sol|
				show_cmap(CMap.new(sol))
			end
		end

		def show_cmap(cmap)
			puts(('a'..'z').to_a.join(''))
			puts cmap.map
			puts
			@words.each do |word|
				pattern = cmap.convert(word)
				printf "%-20s %s %-20s\n"
					word, (@dict.lookup(pattern) ? '' : '*'), pattern
			end
			puts '-' * 42
		end

		DICTFILE = ARGV[0]
		PARTIAL = ARGV[1].to_i

		puts "Reading dictionary #{DICTFILE}"
		dict = Dictionary.new(DICTFILE)

		ARGV[2..-1].each do |filename|
			puts "Solving Cryptogram #{filename} allowing #{PARTIAL} unknows", Time.now
			cryp = Cryptogram.new(filename, dict)
			cryp.solve PARTIAL
			puts "Cryptogram solution", Time.now
			cryp.show
		end

		


				

