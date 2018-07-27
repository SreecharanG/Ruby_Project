#~/usr/bin/env ruby

class LCD
	DEFAULT_SIZE = 2
	LCD_CODES = [ #code for digit's each horizontal line (for size == 1)]
		[:h1, :v3, :h0, :v3, :h1],
		[:h0, :v1, :h0, :v1, :h0],
		[:h1, :v1, :h1, :v2, :h1],
		[:h1, :v1, :h1, :v1, :h1],
		[:h0, :v3, :h1, :v1, :h0],
		[:h1, :v2, :h1, :v1, :h1],
		[:h1, :v2, :h1, :v1, :h1],
		[:h1, :v1, :h0, :v1, :h0],
		[:h1, :v3, :h1, :v3, :h1],
		[:h1, :v3, :h1, :v1, :h1],
	]

	def initialize(number, size)
		@number = number.to_s.split(//).collect { |c| c.to_i }
		@size = (size || DEFAULT_SIZE).to_i
		@size = DEFAULT_SIZE if @size <= 0
		@gap = ' ' # gap between each digit

		line_codes = {  		#For size == 1
			:h0 => ' ' + ' ' * @size + ' ',  #h0 = "    "
			:h1 => ' ' + '-' * @size + ' ',  #h1 = " - "
			:v0 => ' ' + ' ' * @size + ' ',
			:v1 => ' ' + ' ' * @size + '|',
			:v2 => '|' + ' ' * @size + ' ',
			:v3 => '|' + ' ' * @size + '|',
		}

		@lines = []
		(0..4).each { |line| @lines << @number.inject('') { |s, d| s += line_codes[LCD_CODES[d][line]] + @gap}}
	end

	def each_line
		return unless block_given?
		last_line = (@size + 1) * 2
		middle_line = last_line / 2
		(0..last_line).each do |line|
			index = case line
					when 0:               0
					when 1...middle_line: 1
					when middle_line:     2
					when last_line:       4
					else                  3
					end
			yield @lines[index]
		end
	end
end

key, size = ARGV.slice!(ARGV.index('-s'), 2) if ARGV.include?('-s')
raise "USage: #$0 [-s size] number" if ARGV.empty? LCD.new(ARGV.first, size).each_line { |line| puts line }
