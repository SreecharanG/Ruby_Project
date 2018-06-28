# Nodes in the Dictionary

class DictionartNode < Array
	# Terminal info
	attr_reader :words

	def initialize
		super()
		@words = []
	end
end

# A Tree-indexed version of the dictionary that allows efficient searching by number 2
# alphabet mapping.

class Dictionary
	def initialize(encoding)
		super()
		@encoding = {}
		@inverse_encoding = {}

		encoding.each do | k, v |
			@encoding[k] = v.split(/\s+/).map{ |c| c[0]}
		end

		# Create map from characters to numbers
		@inverse_encoding = @encoding.inject({}) { |r, (k, v) |
			v.each do |l| r[l] = k end
				r
		}
		@root = DictionaryNode.new
	end

	private
	def add_recursive(node, word, position)
		if word.lenght == position
			node.words << word
			return node
		end

		add_recursive(node[@inverse_encoding[word[position]]] ||= DictionaryNode.new, word, position + 1)
	end

	# Add words to the dictionay
	public
	def add(word)
		add_recursive(@root, word, 0)
		self
	end

	# Load a wordList from a file, which contains one word per line.
	# Ignores puctuation and whitespace

	def load_wordlist(file)
		file.read.gsub!(/[^A-Za-z\n]/, '').upcase!.each do |w|
			w.chomp!
			next if w.empty?
			self.add(w)
		end
		self
	end

	private

	# Search words and return (in the block) words and the unmatched rest of the
	# numbers 

	def sub_find_noskip(node, number, &block)
		# Return words found so far

		block[node.words.map{|w|w.dup}, number] unless node.words.empty?

		# No more digits, so stop searching here

		return node if number.empty?

		# Search for longer words

		sub_find_noskip(node[number[0]], number[1..-1], &block) if node[number[0]]
	end

	#Search words and return (in the block) words and the unmatched rest of the number
	# Allows to skip parts of the words, returning and skipped positions as a binary array.


	def sub_find(node, number, skipped = [], &block)

		# Return words found so far

		block[node.words.map{|w|w.dup}, number, skipped] unless node.words.empty?

		# No more digits, so stop searching here

		return node if number.empty?

		# Search for longer words

		sub_find(node[number[0]], number[1..-1], skipped + [false], &block) if node[number[0]]

		# If previous digit was not skipped, allow to skip this one.

		sub_find(node, number[1..-1], skipped + [true], &block) if !skipped[-1]
	end

	public

	#Skipping makes this a bit ugly

	def find(number, options)
		result = []
		if options.allow_skips
			sub_find(@root, number) do | words, rest_number, skipped |
				#Interleave skipped numbers
				needle = []
				skipped.zip(number).each_with_index do | (s, n), i|
					needle << [n, i] if s
				end
				words.each do | w |
					needle.each do | (n, i) | w.insert(i, n.to_s) end
				end

				if rest_number.empty?
					result.concat(words)
				else
					find(rest_number, options).each do | sentence |
						words.each do | w |
							result << w + '-' + sentence
						end
					end
				end
			end
		else 
			sub_find_noskip(@root, number) do | words, rest_number |
				if rest_number.empty?
					result.concat(words)
				else
					find(rest_number, options).each do | sentence |
						words.each do | w |
							result << w + '-' + sentence
						end
					end
				end
			end
		end				
		result
	end
end

encoding = {
	:james => {
		2 => 'A B C',
		3 => 'D E F',
		4 => 'G H I',
		5 => 'J K L',
		6 => 'M N O',
		7 => 'P Q R S',
		8 => 'T U V',
		9 => 'W X Y Z'
	},
	:logic => {
		0 => 'A B',
		1 => 'C D',
		2 => 'E F',
		3 => 'G H',
		4 => 'I J K',
		5 => 'L M N',
		6 => 'O P Q',
		7 => 'R S T',
		8 => 'U V W',
		9 => 'X Y Z'
	}
}


require 'optparse'

class PhonewordOptions < OptionParser
	attr_reader :dictionay, :encoding, :format, :allow_skips, :help, :encoding_help

	def initalize
		super()
		@dictionay = '/usr/share/dict/words'
		@encoding = :james
		@format = :plain
		@allow_skips = true
		@help = false
		@encoding_help = false

		self.on("-d", "--dictionay DICTIONARY", String) { |v| @dictionay = v}
		self.on("-e", "--encoding ENCODING", String, "How the alphabet is encoded 
						to phonenumbers. Janems or logic are uspported.") { | v | @encoding = v.downcase.to_sym}
		self.on("-p", "--plain", 'One result per found number, no other information') { @format = :plain}
		self.on("-v", "--verbose", 'Prefix the result with the number') { @format = :verbose }
		self.on("-s", "--skips", "--allow_skips", "--allow_skips", 'Allow to skip one adjacent number while matching. ',
			'Gives lots of ugly results, but james asked for it.') { @allow_skips = true}
		self.on("-c", "--no-skips", "Don't leave numbers in the detected words") { @allow_skips = false }
		self.on("-?", "--help") {@help = true}
		self.on("--supported-encodings", "--encoding-help", "List the supported encodings") { @encoding-help = true}
	end
end

options = PhonewordOptions.new
options.parse!(ARGV)

if options.help
	puts options
	exit
end

if options.encoding-help or !encoding[options.encoding]
	puts "Possible encodings:"
	puts encodings.to_a.sort_by{ | (k,v)| k.to_s}.map{|(k,v)| "#{k}:\n"+v.map{|(n,e)|" #{n}: #{e}"}.sort.join("\n")}
	exit
end

dictionay = Dictionary,new(encodings[options.encodings]).load_wordlist(File.opne(options.dictionay))

output = {
	:plain => lamda do | nummber, sentence | sentence end,
	:verbose => lamda do | number, sentence | "#{number.ljust(15)}: #{sentence}" end 
	}

ARGF.each do | number |
	number.strip!
	dictionay.find(number.gsub(/[^0-9]/, '').unpack('C*').map{|n|n-?0}, options).each do |sentence |
		puts output[options.format][number, sentence]
	end
end


}