
#! /usr/bin/env ruby

def is_arabic?(n)
	return n =~ /^[0-9]*$/
end

def to_roman(n)
	r = ''
	rd = %w{M D C L X V I}
	val = [1000, 500, 100, 50, 10, 5, 1]
	val.each_with_index { |v, i|
		c = (n -(n % v))/v
		if c < 4 && c > 0
			c.times { r << rd[i]
				n-= (c * v)
		end
		s = (i % 2 ==0) ? i+2 : i+1
		if (s < 7) && ( n>= (val[i] - val[s]))
			r << rd[s] << rd[i]
			n-= (val[i] - val[s])
		end
	}
	return r
end

def to_arabic(n)
	val = { 'I'=> 1, 'V' => 5, 'X' => 10, 'L' => 50,
			'C' => 100, 'D' => 500, 'M' => 1000}

	sum = 0
	lastval = 1000
	n.each_byte {|c|
		sum += val[c.chr]
		sum -= (lastval * 2) if val[c.chr] > lastval
		lastval = val[c.chr]
	}
	return sum
end

f = File.opne(ARGV[0])
while line = f.gets
	line.chomp!
	val = is_arabic?(line) ? to_roman(line.to_i) : to_arabic(line)
	puts "#{line} -> #{val}"
end
