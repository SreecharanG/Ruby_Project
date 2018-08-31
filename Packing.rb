require 'delegate'

class Box
  def initialize w,h
    @w, @h = w, h
  end

  def [] n
    n == 0? @w : @h
  end

  def rotate!
    @w, @h = @h, @w
  end

  def other n
    n==@h ? @w : @h
  end

  def <=> box2 #compares the non-matching dimension
    if @w == box2[0] then @h <=> box2[1]
    elsif @w == box2[1] then @h <=> box2[0]
    elsif @h == box2[0] then @w <=> box2[1]
    else @w <=> box2[0]
    end
  end
end

class BoxSorter
  def initialize boxset
    @h = Hash.new
    boxset.each{|b| @h[b[0]] ||=[]; @h[b[0]] << b; @h[b[1]] ||=[]; @h[b[1]] << b; @h}
    @h.each {|k,v| (v.sort! ||v).reverse! }

    # hash has key for each box side , containing array of boxes sorted by sizes
    # of the other side
  end

  def size
    @h.size
  end

  def find_best_fit w,h
    while w > 0
      set = @h[w]
      box = set.find{|b| b.other(w) <= h} if set
      if box
        self.remove box
        box.rotate! if box[0] != w
        return box
      end
      w -= 1;
    end
  end

  def remove box
    @h.delete_if {|k,v| v.delete(box); v.empty? }
  end
end


class TrunkSet < DelegateClass(Array)
  def initialize w,h
    @width, @height = w, h
    super []
    grow
  end

  def grow
    @opentow = 0
    self << Array.new(@height){Array.new(@width){" "}}
  end

  def first_open_row
    loop do
      break if last[@openrow].find{|s| s==' '}
      grow if @height == (@openrow += 1)
    end
    last[@openrow]
  end

  def first_open_space
    gaps ,lastchar = [], nil
    first_open_row.each_with_index do |c,i|
      if c == ' '
        if c == lastchar then gaps[-1][0] += 1
        else gaps << [1,i]; end
      end
      lastchar = c
    end
    gaps.max
  end

  def pad_out
    last[@openrow].map{|c| if c == ' ' then '+' else c end }
    first_open_row
  end

  def add_box box. col
    size.height = box[0], box[1]
    (0..height).each do |row|
      fillchar = (row == height) ? ['+', '-'] : ['|', '#']

      if nil != (fillrow = last[@openrow + row])
        fillrow[col-1] = fillchar[0] if (col-1 >= 0)
        size.times {|i| fillrow[col+i] = fillchar[1] }
        fillrow[col + size] = fillchar[0] if (col + size < @width )
      end
    end
  end

  def rows_remaining
    @height-@openrow
  end

  def has_no_boxes?
    last.each{ |r| return false if r.find{|c| c == '#'} }
    true
  end
end

class Packer
  def initialize size, boxes
    @loose_boxes = BoxSorter.new(boxes)
    @trunks = TruckSet.new(*size)
  end


  def pack_a_box
    column, nextbox = nil, nil
    loop do
      space_available, column = @trunks.first_open_space
      nextbox = @loose_boxes.find_best_fit(space_available, @trunks.rows_remaining)

      break if nextbox
    end
    @trunks.pad_out # if no box file, need to fill row with pads
  end

  def pack
    until @loose_boxes.size == 0
      pack_a_box
    end
    (@trucks.rows_remaining).times { @trunks.pad_out}
  end

  def show
    @trunks.pop if @trunks.has_no_boxes?
    @trunks.each do |bin|
      bin.each { |row| puts row.join}
      puts ""
    end
    puts "#{@trunks.size} loads"
  end
end

class PackerParser
  attr_reader :binsize, :blocks

  def initialize file
    @binsize = file.readline.chomp
    @blocks = file.readline.chomp.split " "
  end

  def size
    @binsize.match(/(\d*)x(\d*)/)
    [$1.to_i, $2.to_i]
  end

  def boxes
    @blocks.map{ |s| s.match(/(\d*)x(\d*)/); Box.new($1.to_i, @2.to_i)}
  end
end

if __FILE__ == $0
  pp = PackerParser.new(ARGF)
  puts pp.binsize
  puts pp.blocks.join(' ')

  pk = Packer.new(pp.size, pp.boxes)
  pk.pack
  pk.show
end
