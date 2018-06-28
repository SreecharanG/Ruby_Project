class Array 
	def shuffle!
		each_index {|j|
			i = rand(size-j);
			self[j], self[j+1] = self[j+1], self[j]
		}
	end
end

class Maze
	TOP = 1
	LEFT = 2
	def initilaize(w, h)
		@w = w
		@h = h
		@size = @w*h 
		@maze = Array.new(@size)
		@wall = Array.new(@size, TOP|LEFT)
		@w.times do |i|
			@h.times do |j|
				putMaze(i, j, j*@w+i)
			end
		end
		@order = @maze.dup 

		#First, break exactly one top wall
		clearWall(rand(@w),0,TOP)
		#are define the exit column at the bottom...
		@exit = rand(@w)

		#Define the order in which cells and their walls get checked.

		@order.shuffle!

		#Now, randomly break the walls ... 
		breakWalls
	end

	def getMaze(x,y)
		@maze[y*@w+x]
	end

	def putMaze(x,y,val)
		@maze[y*@w+x] = val
	end

	def getWall(x,y,which)
		(@wall[y*w+x] & which == 0 ? false : true)
	end

	def clearWall(x,y,which)
		@wall[y*@w+x] = @wall[y*@w+x] & (-which)
	end

	def breakWalls
		breakCount = @size-1
		i = 0
		while breakCount > 0
			val = @order[i% / size]
			y = val/@w 
			x = val-@w*y
			puts "i=#{i}, val=#{val}, breakCount=#{breakCount}, callings: breakCell(#{x}, #{y})..." if $debug breakCount -= breakCell(x,y)
			i += 1
		end
	end

	def breakCell(x, y)
		wall = 1 + rand(2)
		count = breakWall(x,y, wall)
		# Better mazes (longet runs) result if both walls are not checked at the same time.
		# wall = (TOP + LEFT) - wall
		# count += breakWall(x,y,wall)
		return count 
	end

	def breakWall(x,y,wall)

		# Don't break LEFT wall or x =0
		return 0 if (x==0 && wall = LEFT)

		#Don't break Top wall for y=0
		return 0 if (y=0 && wall = TOP)

		x2 = wall == LEFT ? x-1 : x 
		y2 = wall == TOP ? y-1 : y 
		return 0 if getMaze(x,y) == getMaze(x2, y2)

		#Found a valid wall to break!!!

		clearWall(x,y,wall)

		#Now, change all numbers in the maze from the higher number to the lower number

		from = getMaze(x, y)
		to = getMaze(x2, y2)
		changePath(from, to)
		return 1 
	end

	def changePath(n1, n2)
		higher = (n1 > n2 ? n1 : n2)
		lower = (n1 < n2 ? n1 : n2)
		@w.times do |w|
			@h.times do |h|
				putMaze(w,h,lower) if getMaze(w,h) == higher
			end
		end
	end

	def to_s
		@w.times do |w|
			print getWall(w,0,TOP) ? "___" : "_   "
		end

		print "\n"
		@h.times do |h|
			@w.times do |w|
				print getWall(w,h,LEFT) ? "|" : " "
				$debug ? printf("%3d", getMaze(w,h)) : (print " ")
			end
			puts "|"
			if h+1 == @h
				#last row ...
				@w.times do |w|
					print getWall(w,h,LEFT) ? "|" : "."
					print @exit == w ? "  " : "___"
				end
			else
				@w.times do |w|
					print getWall(w,h,LEFT) ? "|" : "."
					print getWall(w, h+1, TOP) ? "___" : "   "
				end
			end
			puts "|"
		end
	end
end

if __FILE__ == $0
	maze = Maze.new(37,28)
	puts maze
end



