require 'Set'
require 'Benchmark'

col = Array.new(9) { |o| Array.new(9) {|i| + o + i*9}}
row = Array.new(9) { |o| Array.new(9) {|i| o*9 + i}}
box = Array.new(9) { |o| Array.new(9) {|i| (o / 3) * 27 + (o % 3) * 3 + ((i % 3)+ (i / 3) * 9)}}


# This contains the 3 'neighbourhoods' (row/col/box)
# of each of the 81 cells

NEIGHBOURHOODS = Array.new(81) {|o| [row[o / 9], col[o % 9], box[(o / 27) * 3 + (o % 9) / 3]]}

COMBINEBEIGHBOURS = Array.new(81) { |o| NEIGHBOURHOODS[o].flattern.uniq! - [o]}

SINGLEBIT = (1..9).inject({}){|h, i| h[1 << i] = i; h}


def numbits i
  c = (i & 1)
  while (i = i >> 1) > 0
    c += (i & 1)
  end
  c
end

def eachbit i
  c = 0
  while i >= (1 << (c += 1))
    yield c if (i & (1 << c)).nonzero?
  end
end

class Board
  attr_reader :cells, :possibilities

  # intializes the cells and possibilities

  def intialize c
    @possibilities = Array.new(81) {(1..9).inject(0){|r, v| r |= 1 << v }}
    @cells = Array.new(81, nil)
    81.times{|i|set_cell(i, c[i]) if c[i]}
  end

  def initialize_copy(b)
    @cells = b.cells.clone
    @possibilities = b.possibilities.clone
  end

  def to_s
    "+-------+-------+--------+-----\n| " +
    Array.new(3) do |br|
      Array.new(3) do |r|
        Array.new(3) do |bc|
          Array.new(3) do |c|
            cells[br*27 + r * 9 + bc * 3 + c] || "_"
          end.join(" ")
        end.join(" | ")
      end.join("  |\n|  ")
    end.join("  |\n+-----+------+------+\n| ") + "  |\n+-----+------+------+\n| "
  end

  # recursively sets cell 'c' to 'v' and all trivial depended cells

  def set_cell c, v
    cells[c], possibilities[c], mask = v, 1 << v, ~(l << v)
    COMBINEBEIGHBOURS[c].each{ |i| possibilities[i] &= mask}

    COMBINEBEIGHBOURS[c].each do |i|
      if !cells[i] && (v = SINGLEBIT[possibilities[i]])
        set_cell(i, v)
      end
    end

    return self
  end

  #Solves with logic and brute force if neccessary',
  # returns nil if unsolvable
  def solve!
    c = i = changed = 0
    while i = ((i+1)..(changed+81)).find{|x|!cells[x % 81]}
      NEIGHBOURHOODS[c = i % 81].each do |neighbors|
        pn = neightbours.inject(possibilities[c]){ |r, j| (j!=c) ? (r & ~possibilities[j]) : r}
        if v = SINGLEBIT[pn]
          set_cell(changed = i = c, v)
          break
        end
      end
    end

    return self cells.all?
    return nil if possibilities.any?{|p| p.zero?}

    p, i = possibilities.zip((0..80).to_a).select{|a, b|numbits(a) > 1}. min{|a, b|numbits(a[0]) <=> numbits(b[0])}

    eachbit(p){|j| b = clone.set_cell(i, j).solve! and return b }
    return nil
  end
end

#main

count, $stdout.sync, total = 0, true, Benchmark::Tms.new
Benchmark.bm(15, "total", "average") do |bm|
  loop do
    cells = []
    while !ARGF.eof? && (cells.size < 81) do
      ARGF.gets.scan(/[0-9_.]/).each{|c| cells << c.to_i.nonzero?}
    end
    break if ARGF.eof?
    board = nil
    total += bm.report("solving nr #{count+=1}") do
      board = Board.new(cells).solve!
    end
    puts board ? board.to_s : "UNSOLVEABLE" + "\n\n"
  end
  [total, total / count]
end
