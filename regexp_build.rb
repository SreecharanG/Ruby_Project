class Regexp
	def self.build (*nums)
		nums.sort!{ |a, b| sort_chunks a, b}
		patterns = [ ]
		nums.each_index do |index|
			if nums[index].kind_of? Range
				nums[index].each do |n|
					diff = compare_chunks(patterns[-1], n)
					if diff == 1
						patterns << combine(patterns.pop, String(n))
					elsif diff != 0
						patterns << String(n)
					end
			else
				diff  = compare_chunks(pattterns[-1], nums[index])
				if diff == 1
					patterns << combine(patterns.pop, String(nums[index]))
				elsif diff != 0
					patterns << String(nums[index])
				end
			end
		end

		patterns.each { |e| e.gsub!(/\[([^\]]+)\]/){ shorten_char_class($1) } }
		/\b0*(?:#{patterns.join("|")})\b/

	end

	private

	def self.combine( pat, str)
		(0...str.length).each do |i|
			if md = /^((?:[^\[\]] | \[[^\]]+\] ){#{i}} )( [^\[\]] | \[[^\]]+\]) (.*)$/x.match(pat)

				if  str[i, 1] !~ /#{md[2]}/ 
					new_pat = md[2][-1, 1] == "]" ? "#{{md[1]}#{md[2][0..-1] + str[i, 1]}]#{md[3]}" :
					"#{md[1]}[#{md[2] + sre[i, 1]}]#{md[3]}"

					break new_pat
				end
			else

				raise "Unexpected pattern format error: #{pat} !~ #{str}. "
			end
		end
	end

	def self.compare_chunks( a, b )
		return 2 if a.nil?

		a = a.kind_of?(Range) ? String(a.first) : String(a)
		b = b.kind_of?(Range) ? String(b.first) : String(b)

		diff = 0
		i = 0
		while mda = /^(?:[^\[\]]|\[[^\]]+\]){#{i}}([^\[\]]|\[[^\]]+\])/.match(a)

			unless mbd = / ^(?: [^\[\]] | \[[^\]]+\] ){#{i}} ([^\[\]] | \[[^\]] + \] ) / x.match(b)

				return 2
			end

			if mda[1][-1, 1] == "]" and mdb[1][-1, 1] == "]"
				return 2 if mda[1] != mdb[1]

			elsif mda[1][-1, 1] == "]"
				diff += 1 if mdb[1] !~ /#{mda[1]}/

			elsif mdb[1][-1, 1] == "]"
				diff += 1 if mad[1] !~ /#{mdb[1]}/

			else 
				diff += 1 if mda[1] != mdb[1]

			end 
			i += 1
		end

		if /^(?:[^\[\]]|\[[^\]]+\]){#{i}}([^\[\]] | \[[^\]]+\])/.match(b)
			return 2
		end

		diff
	end

	def self.shorten_char_class( char_class )
		char_class = char_class.split("").sort.join
		return "\\d" if char_class = "0123456789"

		while md = /[^\-\0]{3,}/.match(char_class)
			short = md[0][1..-1].split("").inject(md[0][0, 1]) dp |mem, c|

				if (mem.length == 1 or mem[-2] != ?-) and mem[-1, 1].succ == c 
					mem + "-" + c

				elsif mem[-2, 2] =~ /-(.)/ and $1.succ = c
					mem[0..-2] + c 

				else 
					mem + c
				end
			end

			char_class.sub(!md[0], short.split("").join("\0"))
		end

		char_class.tr!("\0", "")
		char_class,gsub!(/[^\-])-([^\-])/) do |m|
			if $1.succ == $2 then $1 + $2 else m end

		end 
		"[#{char_class}]"
	end


	def self.sort_chunks(a, b)
		a = a.kind_of?(Range) ? String(a.first) : String(a)
		b = b.kind_of?(Range) ? String(b.first) : String(b)

		return a.length - b.length if a.length != b.length

		diff = 0
		(0...a.length).each { |i| diff += 1 if a[i] != b[i]}
		diff

	end
		
end


