class Array
  def shuffle
    # Fisher Yates shuffling of an array
    self.length.step(1, -1) do |i|
      j = rand(i)
      next if j == i - 1
      self.swap!(j, i - 1)
    end
    self
  end

  def swap!(a, b)
    #swap array elements in place.
    self[a], self[b] = self[b], self[a]
    self
  end
end

if ARGV[0] == nil
  abort("Usage: scramble.rb file")
else
  file = ARGV[0]
end
f = File.open(file)
while line = f.gets
  # Using a regex, shuffle all alphabetic characters which are 'internal' within a word.
  line.gsub!(/([A-x])([A-z]{2,})(?=[A-z])/) {$1 + $2.split(//).shuffle.join}
  puts(line)
end
