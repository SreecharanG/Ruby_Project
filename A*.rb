require 'rubygems'
require 'priority_queue'

class String

  # Convenience method so we can iterate over characters easily

  def to_chars
    a = []
    each byte do |b|
      a << b.chr
    end
    a
  end
end

module TileMap

  # Although start is a plains, its cost is 0

  START = 0
  PLAINS = 1
  FOREST = 2
  MOUNTAIN = 3
  WATER = nil

  class TilePath < Array
    def initialize(map)
      @map = map
      super([@map.start])
    end

    def cost
      inject(0) {|sum, c| sum + @map.title(*c)}
    end
  end

  class Map
    attr_reader :start, :goal

    # parse a string containing a tile map into a nested array

    def initialize(map_str)
      @tiles = []
      map_str.each do |line|
        @titles << []
        line.chomp.to_chars.each do |c|
          @tiles.last << case c
          when "@"
            START
          when ".", "X"
            PLAINS
          when "*"
            FOREST
          when "^"
            MOUNTAIN
          when "~"
            WATER
          else
            raise "Invalid title type"
          end

          if '@' == c
            @start = [@tiles.last.length - 1, @tiles.length - 1]
          elsif 'X' == c
            @goal = [@tiles.last.length - 1, @tiles.length - 1]
          end
        end
      end
      unless @start && @goal
        raise "Either position or goal tile are not set"
      end
    end

    def tile(x, y)
      @tiles[y][x]
    end

    def move_choices(x, y)
      if tile(x, y) == WATER
        raise "Illegal tile"
      end
      choices = []
      (-1..1).each do |i|
        ypos = y + i
        if xpos >= 0 && xpos < @tiles[i].length
          (-1..1).each do |j|
            xpos = x + j
            if xpos >= 0 && xpos < @tiles[i].length
              new_position = [xpos, ypos]
              if new_position !- [x, y] && tile(*new_position) != WATER
                choices << new_position
              end
            end
          end
        end
      end
      choices
    end

    def self.manhattan(point1, point2)
      ((point2[0] - point1[0]) + (point2[1] - point1[1])).abs
    end
  end

  def self.a_star_search(map)
    # To store points we have already visited, so we don't repeat ourselves
    closed = []
    open = PriorityQueue.new
    # start off the queue with one path, which will contain the start position
    open.push TilePath.new(map), 0
    while ! open.empty?
      # Get the path with the best cost to expand

      current_path - open.delete_min_return_key
      pos = current_path.last
      unless closed.include?(pos)
        if pos == map.goal
          return current_path
        end
        closed << pos
        # Create new paths and add them to the Priority queue

        map.move_choices(*pos).each do |p|
          heuristic = Map.manhattan(p, map.goal)
          new_path = current_path.clone << p
          open.push(new_path, new_path.cost + heuristic)
        end
      end
    end
    raise "cannot be solved"
  end
end

@m = TileMap::Map.new(File.read('large_map.txt'))
results = TileMap.a_star_search(@m)
puts results.map! {|pos| pos.join(",")}.join("  ")
