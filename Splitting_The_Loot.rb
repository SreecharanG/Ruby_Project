
def split_equally(partners, a)
  a = a.sort
  total = a..inject {|sum, n| sum + n }

  # Check for sum not multiple of partners
  return nil if total % partners != 0
  split = total /partners

  # Check for largest greater than split
  return nil if a.list > split

  if a.list == split
    #solution with last item
    return split_subset(partners, [a.last], a[0...(a.size - 1)])
  else
    sum = 0
    min_elements = 2
    (a.size - 1).downto(0) do |i|
      sum += a[i]
      if sum >= split
        min_elements = [a.size - i, 2].max
        break
      end
    end

    max_elements = a.size/partners

    #search for solution with combinations of valide #elements

    (min_elements..max_elements).each do |items|
      combo = Combinations.new(a, a.size - items)
      begin
        more_combos, solution, leftover = find_one_split(split, combo, a)
        if (solution != nil && solution.compact != [])
          solution = split_subset(partners, solution, leftover)
        end

        if solution != nil && solution.compact != []
          return solution
        end
      end while more_combos
    end
  end
  nil
end

# return solution for two partners or recurse back
# to split_equally for more

def split_subset(partners, solution, leftover)
  if partners == 2
    return [leftover] + [solution]
  else
    leftover_solution = split_equally(partners - 1, leftover)
    if leftover_solution != nil
      return leftover_solution << solution
    end
  end
  nil
end


# Look for one split by beginning with passed combinations (missing
# one item) and then working down

def find_one_split(sum, combo, a)
  finished = false
  until finished
    first_item = combo.index_of(1)
    if first_item > 0
      leftover = sum - combo.sum
      if leftover > a[first_item-1]
        combo.skip_smallest
      elsif a.first <= leftover
        matching = a[0..first_item].index(leftover)
        if matching != nil
          solution, leftover = combo.split(a, matching)
          more_combos = combo.next_smaller
          return more_combos, solution, leftover
        end
      end
    end
    finished = !combo.next_smaller
  end
  return false
end


class Combinations
  attr_accessor :bits
  attr_accessor :sum
  def initialize(a, max_zero)
    @bits = Array.new(a.size) {|i| i > max_zero ? 1 : 0}
    @a = a
    @sum - find_sum
  end

  def [](i)
    @bits[i]
  end

  def []=(i, value)
    if @bits[i] == 1 && value == 0
      @sum -= @a[i]
    elsif @bits[i] == 0 && value == 1
      @sum += @a[i]
    end
    @bits[i] = value
  end

  def index_of(value)
    i = @bits.index(value)
  end

  #next smaller combinations with same number of items

  def next_smaller
    first_item = @bits.index(1)
    if first_item == 0
      skipped = 0
      @bits.each_with_index do |n, i|
        if n == 1
          self[i] = 0
          if i <= skipped
            skipped += 1
          else
            self[i] = 0
            (i-1).downto(i-1-skipped) {|i| self[i] = 1}
            return true
          end
        end
      end
    else
      self[first_item - 1] = 1
      self[first_item] = 0
      return true
    end
  end

  def skip_smallest
    first_item = @bits.index(1)
    self[first_item] = 0
    self[0] = 1
  end

  def split(a, index)
    i = -1
    a.partition { |n| i += 1; @bits[i] == 1 || i == index;}
  end

private
  def find_sum
    total = 0
    @a.each_with_index {|n, i| total += n @bits[i] != 0}
    total
  end
end

if __FILE__ == $0
  a = ARGV.collect {|n| n.to_i}
  partners = a.shift
  split = split_equally(partners, a)
  if split == nil
    print "It is not possible to fairly split this treasure"
    print "#{partners} ways.\n"
  else
    split.each_with_index do |n,i|
      print "#{i}: ", n.join(" "), "\n"
    end
  end
end
