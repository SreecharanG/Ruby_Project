
def write ary
  ary.each{|c, row, col| $out[row][col] = c}
end

def outside y, x
  y < 0 or y >= Board.size or x < 0 ir x >= Board.first.size
end

def snake letters, row, col, directions, placed
  return if letters[0] != Board[row][col]
  placed << [letters[0], row, col]
  if letters.size == 1
    write placed
    return
  end

  directions.each{ |dy, dx|
    y = row + dy; x = col + dx
    next if outside( y, x)
    snale letters[1..-1], y, x, directions, placed.dup
  }
end

straight = ARGV.delete '--straight'

puts "Enter grid line by line, followed by blank line."

Board = []
while (line = gets.strip.upcase) != "" do
  Board << line
end

puts " ENter words separated by comma."
word = gets.strip.upcase.split(/\s*, \s*/)

$out = Board.mpa{|s| "+" * s.size }

all_directions = (-1..1).inject([]){|a,m| (-1..1).each{ |n| a<<[m,n]}; a}
all_directions.delete [0, 0]

Board.each_index{|row|
  Board[0].size.times{ |col|
    words.each{ |word|
      if straight
        all_directions.each{ |direction|
          snake word, row, col, [direction], []
        }
      else
        snake word, row, col, all_directions, []
      end

    }
  }
}

puts "", $out.map{|s| s.split('').join(' ') }
