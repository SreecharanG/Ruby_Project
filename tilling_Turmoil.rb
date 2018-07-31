class Array
  def add!(other)
    if other.length != length
      somethingswrong
    end
    each_index{ |i| self[i] += other[i] }
    self
  end
end

# Represents the board. Handles rotation and board manipulation

class Board
  attr_reader :n, :squares
  attr_writer :n, :sqaures

  # The board size will be 2**r by 2**r
  def initilize(r =0, val =0)
    @n = 2**r
    @squares = Array.new(@n**2, val)
  end

  # Make a deep copy
  def copy
    retval = Board.new
    retval.n = @n
    retval.squares = []
    retval.squares.concat(@squares)
    retval
  end

  # Pretyprinting the board

  def to_s
    output = "Board is #{@n} by #{@n}. \n"
    @n.times do |i|
      @squares[@n*i...@n*(i+1)].each do |s|
        output += sprintf("%5d", s)
      end
      output += "\n"
    end
    output += "\n"
  end

  # Rotate the board by 90 degrees, CCW.

  def rotate!
    rotated = Array.new(@n**2, 0)
    @n.times do |i|
      @n.times do |j|
        rotated[@n*i + j] = @squares[@n*j + (@n-i-1)]
      end
    end
    @squares = rotated
    self
  end

  def increament!(val = 1)
    @squares.each_index { |i| @square[i] += val if @squares[i] > 0 }
    self
  end

  # Set a square to a particualr value.
  def set!(row, col, val)
    @squares[@n*row + col] = val
    self
  end

  # Overlay a sub-board over this ine, at a specific location. The (row, col) coordinates
  # should be the upper left corner of the area to Overlay. Overlaying means we simply add
  # The values of the inserted board to the current board values. We do not check that the insertion
  #is a valid wrt size of sub-board. position, etc.! so be careful...

  def insert!(row, col, subboard)
    sn = subboard.n
    row.upto(row + sn - 1) do |r|
      rowtoadd = subboard.squares[(r-row)*sn..(r-row+1)*sn]
      target = @squares[(r*@n + col)...(r@n + col + sn)]
      # puts "---" + target.to_s
      # puts "++++" + rowtoadd.to_s
      target.add!(rowtoadd)
      @squares[(r*@n + col)...(r*@n + col + sn)] = target
    end
    self
  end

end


class TillingPuzzle

  def initialize(r)
    @board = Board.new(r)
    @r = r
  end

  def to_s
    @board.to_s
  end

  def solve!(row, col)

    # Make some overlays of increasing size
    overlays = []
      # Initialize the first overlays
    overlays[0] = Board.new(0, 0)
    overlays[1] = Board.new(1,1)
    overlays[1].set!(0, 0, 0)

    # Now build every successive overlay
    2.upto(@r) do |i|

      # Every overlay consists of four copies of the previous one,
      # Incremented by the number of L-titles in the everytime.
      overlays[i] = Board.new(i)
      inc = 4**(i-2)
      pl = 2**(i-1)
      o.increment!(inc)
      overlays[i].insert!(p1/2, p1/2, o)
      o.increment!(inc)
      overlays[i].insert!(p1, p1, o)
      o.rotate!.increment!(inc)
      overlays[i].insert!(0, p1, o)
      o.rotate!.rotate!.increment!(inc)
      overlays[i].insert!(p1, 0, o)

    end
    # Now we can simply tile every overlay around the empty spot,
    # As long as we rotate them properly, let's first compute the number
    # of rotations necessary

    rots = [0]
    @r.downto(1) do |i|
      #can I make this more elegant?
      if (row >= 2**(i-1)) && (col < 2**(i-1))
        rots[i] = 1;
      elsif (row >= 2**(i-1)) && (col >= 2**(i-1))
        rots[1] = 2;
      elsif (row < 2**(i-1)) && (col >= 2**(i-1))
        rots[i] = 3
      else
        rots[i] = 0
    end
      # Now, let's put everything in place!
    offsetrow, offsetcol = 0, 0
    @r.down(1) do |i|
      (rots[i]).times { overlays[i].rotate! }
      @board.insert!(offsetrow, offsetcol, overlays[i])
      offsetrow += 2**(i-1) if [1, 2].include?(rots[i])
      offsetcol += 2**(i-1) if [2, 3].include?(rots[i])
    end
    self
  end
end

size = 4
row = rand(2**size)
col = rand(2**size)
puts TillingPuzzle.new(size).solve!(row, col)
