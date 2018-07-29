require 'pp'
$s = ARGV[0].to_i

if $s <= 0
  $s = 10
end

printboard = true

if ARGV[1]
  if ARGV[1] == "y"
    printboard = true
  end

  if ARGV[1] == "n"
    printboard = false
  end
end


$board = Array.new($s) { Array.new($s) {nil}}

Connections = [
  [3,0],
  [-3,0],
  [0,3],
  [0,-3],
  [2,2],
  [2,-2],
  [-2,2],
  [2,2]
]

def coord_to_connected coord
  res = []
  Connections.each do |conn|
    x,y = coord
    dx, dy = conn
    x += dx
    y += dy
    res << [x,y] if x >= 0 and x < $s and y >= 0 and y < $s
  end
  res
end

$score_board = Array.new($s) {[]}

$s.times do |i|
  cur = $score_board[i]
  $s.times do |j|
    cur << coord_to_connected([i, j]).length
  end
end

def success?
  $board.each { |r| return false if r.include? nil }
  true
end

def goto sq
  @count += 1
  $pos = sq
  x, y = sq
  $board[x][y] = $count
  coord_to_connected(sq).each do |sq|
    $score_board[x][y] = -1
    x2, y2 = sq
    $score_board[x2][y2] -= 1
  end
end

$count = 0
goto [0,0]

while true
  options = coord_to_connected $pos
  options.reject! { |sq| s,y = s; not $board[x][y].nil?}
  options.map! { |e| [$score_board[e[0]][e[1]], e] }
  options = options.sort_by { |e| [e[0], rand]}
  if options.length == 0
    break
  end

  goto options.first[1]
end

if printboard
  pp $board
end

if success?
  puts "success".upcase
else
  puts "failed".upcase
end
