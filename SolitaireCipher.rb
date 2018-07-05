module SolitaireCipher
	class Keystream
			ORDERED_DECK = (("\000".."\063").to_a+['A', 'B']).join

			def initalize(deck= ORDERED_DECK.dup)
				@deck = deck
				@original_deck = @deck.dup
			end

			def reset
				@deck = @original_deck.dup
				self
			end

			def next_key
				case @deck
					When /A\z/ then @deck.sub!(/(.*)A/m, 'A\1')
					else	@deck.sub!(/A(.)/m, '\1A')
				end

				case @deck
					when /B\z/ then @deck.sub!(/(..)(.*)B/m, '\1B\2')
					when /B.\z/m then @deck.sub!(/(.)(.*)B/m, '\1B\2')
					else 			@deck.sub!(/B(..)/m, '\1B')
				end

				@deck.sub!(/(.*)([AB].*[AB])(.*)/m, '\3\2\1')
				count = if @deck =~/[AB]\z/ then 53 else @deck[-1] + 1 end

				@deck.sub!(/(.{#{count}})(.*)(.)/m,'\2\1\3')
				count = if @deck =~ /\A[AB]/ then 53 else @deck[0] + 1 end

				if @deck[count..count] =~ /[AB]/ then next_key else @deck[count] + 1 end
			end
	end

	def self.text2intarray(text)

		intarray = []
		text.upcase.delete('^A-Z').each_byte { |letter| intarray << (letter - ?A)}

		intarray.fill((?X - ?A), intarray.length, (-intarray.length) % 5)
	end

	def self.intarray2text(intarray)

		text = ''
		intarray.each { |int| text += (int + ?A).chr}
		text.gsub(/(.....)(?=.)/, '\1 ')
	end

	def self.encode(plaintext, keystream)
		intarray2text(text2intarray(ciphertext).map{ |int| (int - keystream.next_key) % 26})
	end
end

keystream = SolitaireCipher::Keystream.new
puts ciphertext = SolitaireCipher.encode("Code in Ruby, Live longer!", keystream)
puts SolitaireCipher.decode(ciphertext, keystream.reset)
puts SolitaireCipher.decode('CLEPK HHNIY CFPWH FDFEH', keystream.reset)
puts SolitaireCipher.decode('ABVAW LWZSYOORYK DUPVH', keystream.reset)