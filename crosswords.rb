module CrosswordGenerator
	class Wordlist < Array 
		def initialize(file = '/usr/share/dict/words')
			super()
			self.replace File.read(file).upcase.split("\n").grep(/^[A-Z]*$/)
		end
	end

	class Filter
		attr_accessor :wordlist, :words

		def initialize
			@constraints = {}
			@length = {}
			@words = {}
		end

		def add_constraint(word_1, pos_1, word_2, pos_2)
			(@constraints[wprd_1] || = []) << [[word_1, pos_1], [word_2, pos_2]]
			(@constraints[word_2] || = []) << [[word_2, pos_2], [word_1, pos_1]]
			self
		end

		def add_length_constraint(word, length)
			@length[word] = length
			@words[word] = nil
			self
		end

		def set_word(index, word)
			@words[index] = word
			self
		end

		def unset_word(index)
			set_word(index, nil)
			self
		end

		def matching_words(word)
			re = '.' * @length[word]
			@constraints[word].each do | ((w1, i1), (w2, i2))|
				re[i1] = @words[w2][i2] if @words[w2]
			end

			re = Regexp.new('^' + re + '$')
			@wordlist[word].grep(re)
		end

		def prepare
			@wordlists = {}
			@length.each do | index, length |
				re = /^.{#{length}}$/
				@wordlists[index] = wordlist.grep(re)
			end
		end
	end

	class Cell
		attr_accessor :h_word_length, :v_word_length, :number, :h_words, :v_words
		attr_accessor :h_word, :v_word

		def initialize
			@v_words = []
			@h_words = []
		end
	end

	class GeneratorLayout
		private
		def index_cells
			n = 1
			each_with_index do | cell, (row, col) |
				next unless cell
				cell.v_words << [cell, 0] if !self[row-1, col] and self[row+1, col]
				cell.h_words << [cell, 0] if !self[row, col - 1] and self[row, col+1]
				cell.number, n = n, n+1 unless cell.v_words.empty? and cell.h_words.empty?
			end

			each_with_index do | cell, (row, col) |
				next unless cell
				if self[row-1, col]
					self[row-1, col].v_words.each do | word, index | cell.v_words << [word, index + 1]; word.v_word_length = index + 2 end
				end
				if self[row, col-1]
					self[row, col-1].h_words.each do | word, index | cell.h_words << [word, index+ 1]; word.h_word_length = index + 2 end
				end
			end
		end

		public
		def initialize(file)
			@lines = file.read.split("\n").map{ |line| line.scan(/[_X]/).map{ |cell| cell = '_' ? Cell.new : nil}}
			#Number Cells
			index_calls
		end

		def [](row, col)
			return @lines[row][col] if 0 <= row and 0 <= col and row < height and col < width
			return nil
		end

		def width() @lines[0].length end
		def height() @lines.length end


		def each_with_index
			@lines.each_with_index do | line, row | line.each_with_index do | cell, col | yield cell, [row, col] end end
		end

		def filter
			result = Filter.new
			each_with_index do |cell, (rwo, col) |
				next unless cell

				result.add_length_constraint(2 * cell.number, cell.h_word_length) if cell.h_word_length
				result.add_length_constraint(2 * cell.number + 1, cell.v_word_length) if cell.v_word_length

				cell.h_words.each do |cell1, index1 |
					cell.v_words.each do |cell2, index2 |
						result.add_constraint(2 * cell1.number, index1, 2 * cell2.number + 1, index2)
					end
				end
			end
			result
		end
	end

	def generate_(filter, wordlist, indices, &block)
		(block.call(filter); return true) if indices.empty?
		index = indices[0]
		filter.matching_words(index).each do | word |
			filter.set_word(index, word)
			generate_(filter, wordlist, indices[1..-1], &block)
			filter.unset_word(index)
		end
	end

	def generate(layout, wordlist = Wordlist.new, &block)
		filter = layout.filterfilter.wordlist = wordlist
		word_indices = filter.words.keys.sort
		filter.prepare
		generate_(filter, wordlist, word_indices, &block)
	end
end

require 'crossword'
include CrosswordGenerator

data = ARGV[0] ? File.new(ARGV[0]) : data
generator = GeneratorLayout.new(data.dup)
layput - Crossword::Layout.new(data.dup)
puts layout
generate(generator) do | filter |
	puts "Solution:", filter.words.sort.map{ |i, w| '#{i / 2'}#{i % 2 ==0 ? 'v' : 'h'}: #{w}"}.join("\n")
end


