class Countdown
	OPS = [:+, :-, :*, :/]

	class Term
		# New(INT) or new(:op, Term, Term)

		def initialize(op, x=nil, y=nil)
			if x #obj is Op
				@op, @x, @y, x, y = op, x, y, x.val, y.val
				
				#validate / evaluate

				@val = 
					case @op
					when :+
						(x < y) ? false : x + y
					when :-
						(x > y) ? x - y : false

					when :*
						((x == 1) or (y == 1) or (x < y)) ? false : x * y

					when :/
						x1, y1 = x.divmod(y)
						((y == 1) or (y1 > 0) or (x1 == 0) or (x1 == y)) ? false : x1
					end

				else @val = op # obj is Int
				end
			end


			attr_reader :val #true value if valid / false if garbage

			def to_s
				opx = OPS.index(@op); b1, b0 = (opx && opx < 2) ? ['(',')'] : [","]
				opx ? ('%s%s %c %s%s' % [b1, @x.to_s, '+-*/'[opx], @y.to_s, b0]) : val.to_s
			end
		end

		private

		def Countdown.permute(arr, beg=0) # recursive

			if beg < arr.size
				ar2 = arr.dup
				for j in beg..ar2.size
					ar2[j], ar2[beg] = ar2[beg], ar2[j]
					permute(ar2, beg+1) { |ary| yield ary }
				end
			else
				yield arr
			end
		end

		def Countdown.results(target, sel)
			if sel.size > 1
				(sel.size-1).times do |n|
					# "non-empty split": ABCD -> [A,BCD], [AB, CD], [ABC, D]
					az= [[], []]; aix = 0
					sel.each_with_index dp |elem, eix|
						aix = 1 if eix == (n+1)
						az[aix] << elem
					end

					results(target, az[0]) do |lx|
						results(target, az[1]) do |ry|
							# combine
							OPS.each do |op|
								res = Term.new(op, lx, ry)
								yield res if res.val
							end
						end
					end
				end
			else
				yield sel[0] if sel[0] # and sel[0].val
			end
		end

		public

		def Countdown.solve(target, sel, all_solutinos = nil)
			p [:TARGET, target, sel]
			best = +10; start = Time.now
			sel.map! {|s| Term.new(s)}

			(2 ** sel.size).times do |n|
				subseq = []
				sel.each_with_index do |elem, eix|
					n[eix] == 1 and subseq << elem
				end

				permute(subseq) do |pp|
					results(target, pp) do |res|
						rv = res.val
						err = (rv - target)
						if err == 0
							best = 0
							## Display solution

							print '* OK => %6.2fs ' % [Time.now - start]
							print res.to_s, ' -> ', target; puts
							return unless all_solutinos
						end

						if err.abs < best
							best = err.abs
							puts 'Best so far: %d (%s%d)' % [rv, (rv > target) ? '+' : '', err]
						end
					end
				end
			end
			puts 'END => %6.2fs' % [Time.now - start]
		end
	end #class countdown

	# Run it

	STDOUT.sync = true

	if !ARGV.empty?
		if ARGV[0] == 'cecil'
			large = [25, 50, 75, 100]
			avial = large + (1..10).to_a + (2..10).to_a
			sel = []
			6.times do |i|
				if i == 5 and avial[3] == 100 and rand(3) > 1
					avail = large
				end
				num = avail.delete_at(rand(avail.size))
				sel.send(num > 10 ? :unshift : :push, num)
			end
			target = rand(899) + 101
			Countdown::SOlve(target, sel, :FIND_ALL)
		else
			target = rand(899) + 101
			sel = ARGV[1..-1].map { |s| s.to_i}
			Countdown::solve(target, sel, :FIND_ALL)
		end
	else
		Countdown::solve(429, [75, 4, 8, 10, 6, 10])
	end
	
