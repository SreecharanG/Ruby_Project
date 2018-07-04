#!/usr/local/bin/ruby -w

#Parse arguments

unless ARGV.size == 2 and ARGV.all? { |n| n =~ /\A[1-9]\d*\Z/ }
  puts "Usage: #File.basename($0)} START_NUMBER FINISH_NUMBER"
  puts " Both number arguments must be positive integers."
  exit
end

start, finish = ARGV.map { |n| Integer(n) }

# Simple helper methods for determining if divide-by-two operation is allowed.

class Integer
  def even?
    self % 2 == 0
  end
end

# A breadth-first search with a single optimization: All numbers are marked as
# "seen" when they are calculated, then all future calculations resulting in an
# already seen number cause the entire path to be abandoned. (We've seen it
# before in equal or less steps, so there's no need to use the alternate/longer path)

def solve(start, finish)
  return [start] if start == finish
  seen = {start => true}
  paths = [[start]]

  until paths.first.last == finish
    path = paths.shift

    new_paths = [path.dup << path.last * 2, path.dup << path.last + 2]
    new_paths << (path.dup << path.last / 2) if path.last.even?

    new_paths.each do |new_path|
      unless seen[new_path.last]
        paths << new_path
        seen[new_path.last] = true
      end
    end
  end

  paths.shift
end

# Run program
puts solve(start, finish).join(", ")
