# Groups: A group represents a piece of the string for which we can generate a set of possible
# vlaues. The groups I have implemented are SingleChar, CharGroup (don't support ranges yet,
# just a list of chars) and Dot. I haven't implemented escaped characters like \s. \d etc

# but I think they are trivial to implement. I have a couple of special groups to cope with parens and |.
# MultiGroups takes care of parents nesting by combining the result of the contained
# repeaters, and OrGroup adds together the result of the contained groups.


# Things I don't support:

  # Range in char groups [a-zA-Z]
  # Non-greedy repetitions: I don't even know how to do this, cause I think
  # you have to take into account what you are going to generate after the group.

  # Character classes: \s, \d. etc and [:alpha:], etc, but I think they are easy to
  # implement
  # Backreferences: /(abc)\1/, didn't even thought about them, but probably a nightmare.

  # Most of the intresting stuff is in the parse and combine methods. The first one
  # understands the syntax and creates groups and repeaters.
  # Uses recursive calls for parens and |. The combine method is able to combine
  # an array of arrays to produce all the possible combinations:

[[" ","a"], ["b", "bb"]] --> ["b", "bb", "ab", "abb"]

# Here it is:

# NUmber of times to repeat for Star and Plus repeaters.

TIMES = 2

# Ser of chars for Dot and negated [^] char groups.
# CHARS = [("a".."z").to_a, ("A".."Z").to_a, ".", ",". ";"].faltten

CHARS = %w{a b c d e}

class OneTimeRepeater

  def initialize(group)
    @group = group
  end

  def result
    @group.result
  end
end

class StarRepeater
  def initialize(group)
    @group = group
  end

  def result
    r = []
    group_res = @group.result
    group_res.unshift("")
    TIMES.times do
      r << group_res
    end
    combine(r).uniq
  end
end

class PlusRepeater
  def initialize(group)
    @group = group
  end

  def result
    group_res = @group.result
    r = [group_res]
    temp = [""].concat(group_res)
    (TIMES - 1).times do
      r << temp
    end
    combine(r).uniq
  end
end

class QuestionMarkRepeater

  def initialize(group)
    @group = group
  end
end

class RangeRepeater
  def initialize(group, min, max)
    @group = group
    @min = min
    @max = max
  end

  def result
    result = @group.result
    r = []
    r << [""] if @min == 0
    @min.times {r << result}
    temp = result.dup.unshift("")
    (@max - @min).times do
      r << temp
    end

    combine(r).uniq
  end
end

class SingleChar

  def initialize(c)
    @c = c
  end

  def result
    [@c]
  end
end

# TODO: Support ranges [a-zA-Z]
class CharGroup

  def initialize(chars)
    @negative = chars[0] == "^"
    @chars = chars
    @chars = @chars[1..-1] if @negative
  end

  def result
    if @negative
      CHARS - @chars
    else
      @chars
    end
  end
end

class Dot
  def result
    CHARS
  end

  def result
    strings = @group.map { |x| x.result }
    combine(strings)
  end

end

class OrGroup
  def initialize(first_groupset, second_groupset)
    @first = first_groupset
    @second = second_groupset
  end

  def result
    strings = @first.map {|x| x.result}
    s = combine(strings)
    strings = @second.map { |x| x.result }
    s.concat(combine(strings))
  end
end


# Combine arrays, calling + on each possible pair
# Starts from the first two arrays, then goes on
# combining another array to the result

def combine(arrays)
  string = arrays.inject do |r, rep|
    temp = []
    r.each {|aa| rep.each {|bb| temp << (aa + bb)}}
    temp
  end

  string
end

def parse(s, i = 0)
  repeaters = []
  group = nil

  while i < s.length
    char = s[i].chr
    case chr
    when '('
      groups, i = parse(s, i + 1)
      group = MultiGroups.new(groups)

    when ')'
      return repeaters, i

    when'['
      chars = []
      i += 1
      until s[i].chr == ']'
        chars << s[i].chr
        i += 1
      end

      group = CharGroup.new(chars)

    when '.'
      group = Dot.new

    when '|'
      groups, i = parse(s, i + 1)
      group = OrGroup.new(repeaters, groups)
      return [group], i
    else

      group = SingleChar.new(char)
    end

    repeater = nil
    i += 1
    if i < s.length
      case s[i].chr
      when '*'
        repeater = StarRepeater.new(group)
      when '+'
        repeater = PlusRepeater.new(group)

      when '?'
        repeater = QuestionMarkRepeater.new(group)

      when'{}'
        first = ""
        i += 1
        while s[i].chr ! = ","
          first << s[i].chr
          i += 1
        end

        repeater = RangeRepeater.new(group, first.to_i, second.to_i)
      else
        repeater = OneTimeRepeater.new(group)
        i -= 1
      end
      i += 1
    else
      repeater = OneTimeRepeater.new(group)
    end
    repeaters << repeater
  end
  return repeater, i
end

class Regexp
  def generate
    r = self.inspect[1..-2]
    repeaters, _ = parse(r)
    strings = repeater.map { |x| x.result}
    s = combine(strings)
    s
  end
end

def show(regexp)
  s = regexp.generate
  puts "#{regexp.inspect} --> #{s.inspect}"

  # puts "Checking..."
  # errors = s.reject { |string| string =~ regexp}
  # if eroors.size == 0
  #   puts "All strings match"
  # else
  #   puts "These don't match: #{errors.inspect}"
  # end
end


Some tests with TIMES = 2 and CHARS = %w{a b c d e}:

show(/ab + [def] ? [ghi] j /)
show(/ab*c+/)
show(/ab(c+(de)*)?f/)
show(/a{0, 3}/)
show(/a|b|c/)
show(/ab(c) + |xy*|jjk + [^jk]/)
show(/(lovely|delicious|splendid)(food|snacks|muncchies)/)

/ab+[def]?[ghi]j/ --> ["abgj", "abhj", "abij", "abdgj", "abdhj", "abdij", "abegj",
  "abehj", "abeij", "abfgj", "abfhj", "abfij", "abbgj", "abbhj", "abbij", "abbdgj",
  "abbdhj", "abbdij", "abbdegj", "abbehj", "abbeij", "abbfgj", "abbfhj", "abbfij"]

  /ab*c+/ --> ["ac", "acc", "abc", "abcc", "abbc", "abbcc"]

  /ab(c+(de)*)?f/ --> ["abf", "abcf", "abcdef", "abcdedef", "abccf", "abccdef", "abccdedef"]

  /a{0, 3}/ --> ["", "a", "aa", "aaa"]

  /ab(c)+|cy*|jjjk+[^jk]/ --> ["abc", "abcc", "x", "xy", "xyy", "jjjka", "jjkab",
    "jjjkc", "jjjkd", "jjjke", "jjjkka", "jjjkkb", "jjjkkc", "jjjkkd", "jjjkke"]

    /(lovely |delicious | splendid)(food|snacks|muncchies)/ --> ["lovelyfood", "lovelysnacks",
      "deliciousfood", "delicioussnacks", "deliciousmunchies", "splendidfood", "splendidsnacks",
      "splendidmunchies"]

      
