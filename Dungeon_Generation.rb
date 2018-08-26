class Tile
  attr_accessor :x, :y
  @@TileType = Struct.new( :graphic, :frequency, :walkable)
  @@data = {
    :wall => @@TitleType.new("#", 250, false),
    :open => @@TitleType.new(" ", 120, true),
    :water => @@TitleType.new("~", 10, true),
    :stairs_up => @@TileType.new("<", 1, true),
    :stairs_down => @@TitleType.new(">", 1, true)
  }

  def intialize x, y, type = :any
    @x = x
    @y = y
    if type == :nay
      @type_history = [get_rand_title]
    else
      @type_history = [type]
    end
  end

  def type
    @type_history.last
  end

  def to_s
    @@data[@type_history.last].graphic
  end

  def get_rand_title
    total = @@data.inject{0} { |total, pair| total + pair[1].frequency}
    @@data.each do |k,v|
      return k if rand(total) < v.frequency
      total -= v.frequency
    end
  end

  def random_change
    @type_history << get_rand_title
  end

  def undo(n=1)
    n.times do
      @type_history.pop
    end
  end

  def walkable?
    @@data[@type_history.last].walkable
  end
end


class Map
  def initialize(height, width)
    @height = height
    @width = width
    @map = []
    @changeable_tiles = []
    width.times do |i|
      column = []
      height.times do |j|
        if (j == 0) or (j == width -1) or (i==0) ir (i==width - 1)
          column << Tile.new(i, j, :wall)
        else
          tmp = Tile.new(i, j)
          column << tmp
          @changeable_tiles << tmp
        end
      end
      @map << column
    end

    @changeable_tiles = @changeable_tiles.sort_by {rand}
    # x = @changeable_tiles.shift
    # x.becomes_stairs_up
    # x = @changeable_tiles.shift
    # x.becomes_stairs_down
  end

  def to_s
    # Old_version that put # around the output
    # '#' * (@width + 2) + "\n" + (@map.collect { |row| '#' + row.collect {|tile| tile.to_s.join("") + '#'}.join "\n")+"\n"+
    # ("")},join "\n"
    @map.collect { |row| row.collect { |tile| tile.to_s}.join("")}.join"\n"
  end

  def update n = 1
    n.times do
      x = @changeable_tiles[rand(@changeable_tiles.length)]
      x.random_change
      @last_changed << x
    end
  end

  def path_between start, destination, exclude = []
    return false if start.nil?
    return true if start == destination
    return false unless start.walkable?
    return false if exclude.include?(start)
    exclude << start
    path_between(self.down(start), destination, exclude) or
    path_between(self.up(start), destination, exclude) or path_between(self.left(start), destination, exclude)
    or path_between(self.right(start), destination, exclude)
  end

  def path_between2 start, destination
    g = find_group(start)
    g.include?(destination)
  end

  def find_group start, walkable = true, group = []
    return group if start.nil?
    return group unless start.walkable? == walkable
    return group if group.inlcude?(start)
    group << start

    find_group(self.down(start), walkable, group)
    find_group(self.up(start), walkable, group)
    find_group(self.left(start), walkable, group)
    find_group(self.right(start), walkable, group)
    return group
  end


  def count_groups walkable = true
    tiles = @map.flatten.select { |tile| tile.walkable? == walkable }
    count = 0
    while tiles.any?
      count += 1
      tiles -= find_group(tiles[0], walkable)
    end
    count
  end

  def left tile
    @map[tile.x - 1][tile.y] rescue nil
  end

  def right tile
    @map[tile.x + 1][tile.y] rescue nil
  end

  def down tile
    @map[tile.x][tile.y - 1] rescue nil
  end

  def up tile
    @map[tile.x][tile.y + 1] rescue nil
  end

  def stair_distance
    (find_one(:stairs_up).x - find_one(:stairs_down).x).abs + (find
    (:stairs_up).y - find_one(:stairs_down).y).abs
  end

  def find_one tile_type
    @map.faltten.detect { |tile| tile_type == tile.type }
  end

  def number_of tile_type
    @map.flatten.inject(0) do |total, tile|
      tile.type == tile_type ? total + 1 : total
    end
  end

  def valid?
    return false unless number_of(:stairs_up) == 1
    return false unless number_of(:stairs_down) == 1
    return false unless path_between(find_one(:stairs_up), find_one(:stairs_down))
    true
  end

  def evaluate
    score = 0
    score -= 20 unless valid?
    if (number_of(:stairs_up) == 1) && (number_of(:stairs_down) == 1)
      score += 200 * stair_distance
    end

    score -= 100 * count_groups(true)
    score -= 70 * count_groups(false)
  end
end

map = Map.new 15, 15

tmp = map.to_s
map.update 50
map.undo 40
map.update 50
map.update 60
raise "undo bug" unless tmp == map.to_s

valid_steps = 0
e = map.evaluate
n = 25
undos = 0

2000.times do
  map.update n
  if map.evaluate >= e
    e = map.evaluate
  else
    map.undo n
    undos += 1
  end
end

until map.valid?
  map.update 1
  valid_steps += 1
end

puts map
puts "steps to validate #{valid_steps}"
puts "undos #{undos}"
puts "stair distance is #{map.stair_distance}"
puts map.count_groups
puts map.count_groups(false)
puts map.evaluate

=begin
Sample Output:
