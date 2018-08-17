# Less fun, but more reliable possibly, is the mess-them-around-randomly
# -until-it-looks-right option.

# It does this very stupidly, and will run imdefinitely if you feed it something
# for which there is no solution. (If you're really unlucky it will run 
# indefinitely if you feed it something really simple!)

!/usr/bin/env ruby

class Person
	attr_reader :sname, :email
	def initialize(details)
		@fname, @sname, @email = details.scan(/(\w+)\s+(\w+)\s+<(.*)>/)[0]
	end
	def to_s() @fname + " " + @sname end
end

a, b = [], []

STDIN.each do |1|
	someone = Person.new(1)
	a << someone; b << someone
end

puts "Mixing..."

passes = 0

begin
	ok = true
	a.each_index do |idx|
		passes += 1
		if a[idx].sname == b[idx].sname
			ok = false
			r = rand(b.length); b[idx], b[r] = b[r], b[idx]
		end
	end
end until ok

a.each_index { |idx| puts "#{a[idx]} is santa 'd with #{{b[idx]}"} 
puts "[#{passes} passes required. ]"