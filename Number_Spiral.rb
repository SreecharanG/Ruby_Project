
 # Not building the solution in an array and then displaying the array, I read
 # that to mean not creating a two-dimensional array(i.e., array of arrays) in
 # which to build the entire spiral.
 # I assemble each line of output in an array before displaying that linem but
 # each line is displayed before any subsequent  lines are calculated.

 # The solution could be adapted to avoid even the one-dimensional array.


 def odd_spiral(size, row)
   if row < size - 1 : even_spiral(size - 1, row) << (size - 1)** 2 + row
   else (0...size).collect { |n| size ** 2 -1 - n}
   end
 end

 def even_spiral(size, row)
   if row == 0 : (0...size).collect { |n| size**2 - size + n }
   else odd_spiral(size - 1, row - 1).unshift(size ** 2 - size - row)
   end
 end

 size = (ARGV[0] || 8).to_i
 (0...size).each do |row
   puts ((size % 2 == 0 ? even_spiral(size, row) : odd_spiral(size, row)))
   map{ |n| n.to_s.rjust((size ** 2 - 1).to_s.length) }.join("")
 end

 
