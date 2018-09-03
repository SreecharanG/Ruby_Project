class Integer
  def divisors
    res = []
    i = 1
    while i*i < self
      if self %i == 0
        res << i
      end
      i += 1
    end
    (res.size - 1).downto(1) do |k|
      res << self / res[k]
    end
    res << i if i*i == self
    res
  end
end

def weird(n)
  possible_sums = Hash.new
  possible_sums[0] = true

  divisors = n.divisors
  div_sum = divisors.inject(0) { |s,i| s+i }
  return false if div_sum <= n

  diff = div_sum - n
  return false if divisors.include? diff

  divisors.each do |i|
    possible_sums.keys.sort.each do |s|
      new_sum = s + i
      case new_sum <=> diff
      when  -1
        possible_sums[new_sum] = true
      when 0
        return false
      when 1
        break
      end
    end
  end

  return true
end

n = ARGV.shift or exit
n = n.to_i
m = ARGV.shift
m = m.to_i if m
range = m ? (n..m) : (1..n)
for i in range
  puts i if weird(i)
end
