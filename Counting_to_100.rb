
# It would be really intersting to write a non-recursive permute function
# that could map a number n to each permutation of digits, and map n + 1
# to the next permutation. Then we could just count from 1 to 6561 for 9 digits,
# 1 to 19683 for 10 digits etc, Something like this:

permutation(1, 1...9) => [1,2,3,4,5,6,7,8,9]
permutation(6549, 1..9) => [123456, 78, 9]
permutation(6560, 1..9) => [123456, 789]

# This is easy when we're permuting a single number (it's just converting to another
# base), but it might not be possible in this problem. I guess the recursive
# method reallly only goes 9 or 10 level deep anyway.

#!/usr/bin/env ruby

# return all combinations of numbers using @digits

def permute digits, progress=[], results=[]

  # last used digit
  last = progress.last ? digits.index(progress.last % 10) : -1

  # this permutation is all done

  return results << progress if last + 1 == digits.size

  remaining = digits[last + 1..-1]
  remaining.size.times do |b|

    # if the  last digit used was 1, we'll try these as the next number;

    # 2, 23, 234, 2345, ..., 23456789

    num = remaining[0..b].join.to_i
    permute digits, progress+[num], results
  end

  results
end


# all permutations of n operations, ops

def operations ops, n, progress=[], results=[]

  # done when we've got n operation is progress array

  return results << progress if progress.size == n

  ops.each{ |o| operations ops, n, progress+[o], results }
  results # modified by method call
end

# return expr string and value, give set of numbers and corresponding ops

def compute numbers, ops
  e = numbers.zip(ops).flatten.map{ |n| n.to_s }.join ' ' # make a string to evaluate it
  v = eval(e)
  ["#{e} = #{v}", v]
end


def target value, digits = (1..9).to_a, ops = [:+, :-]

  # Note: only digits 0-9 work, because of % 10 math in permute method

  stars = '*'*76 + "\n"
  count = 0
  cache = {}
  permutations = permute digits

  permutations.each do |nums|
    # cache permutations of nums.size - 1 operations
    opers = cache[nums.size - 1] || (cache[nums.size - 1] = operations(ops, nums.size - 1 ))

    opers.each do |o|
      count += 1
      expr, val = compute(nums, o)

      if val != value
        puts expr
      else
        puts stars + expr << "\n" << stars
      end

    end
  end

  puts "#{count} possible equations tested"
end

if $0 == __FILE__
  target 100, (1..9).to_a, [:+, :-]
end
