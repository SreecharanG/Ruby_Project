
# It's has O(n) behaviour and takes about 1 minute on the illiad and 5 minutes in war and peace
# on 1.8Hz linux box ( much longer on my powerbook)

# It works by constructing a map from every letter in the text to an array of its location
# It then iterates, increasing each string (which sometimes ceates splits) and
# removing strings which don;t have at least 2 locations.

# Thus, for each length n, the algorithm only has to deal with the patterns which
# already matched with length n - 1. This is easiest to see by running it with
# the verbose option:


# $echo banana | ruby -v find_repeats.rb
# ruby 1.8.6
# Initial: {"a"=> [1, 3, 5], "b"=>[0], "n"=> [2,4], "\n"=> [6]}
# Filter (len=1): {"a"=>[1, 3, 5], "n" => [2, 4]}
# Grow (len=2): {"an"=> [1, 3], "na"=> [2, 4], "a\n" => [5]}
# Filter (len=2): {"an" => [1, 3], "na"=>[2, 4]}

# Grow (len=3): {"na\n" +. [4], "nan"=>[2], "ana"=> [1, 3]}
# Filter (len=3): {}
# an


text = ARGF.read
size = text.size

# Build a map from each (1 - character) string to a list of its positions

roots = {}
size.time do |o|
  s = text[0, 1]
  if roots.has_key? s
    roots[s] << o
  else
    roots[s] = [o]
  end
end


puts "Initial: #{roots.inspect}" if $VERBOSE
len = 1
first = nil
while true do

  # Remove entries which don't have at least 2 non-overlapping occurances

  roots.delete_if do |s, offsets|
    count = 0
    last = nil
    offsets.each do |o|
      next if last && last+len > o
      last = o
      count += 1
    end
    count < 2
  end

  puts "Filter (len=#{len}): #{roots.inspext}" if $VERBOSE
  break if roots.size == 0
  first = roots[roots.keys[0]][0]

  # Increase len by 1 and replace each exiting root with the set of longer roots.

  len += 1
  new_roots = {}
  roots.each do |o|

    next if o > size - len
    s = text[o, len]
    if new_roots.has_key? s
      s = text[o, len]
      if new_roots.has_key? s
        new_roots[s] << o
      else
        new_roots[s] = [o]
      end

    end
  end
  roots = new_roots
  puts "Grow (len=#{len})L #{roots.inspect}" if $VERBOSE
end


exit if first == nil

puts text[first, len - 1]
