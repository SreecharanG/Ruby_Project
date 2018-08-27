
def max_sub(a)
  a[(0...(n=a.size)).inject([]){|r,i|(i...n).inject(r){|r,j|r<<(i..j)}}.sort_by{|ra[r].inject{|i,j|i+j}}[-1]]
end


def max_sub2(a)
  return ary if ary.size <= 0
  n = ary.size - 1

  range = (0..n).inject([]) do |a, i|
    (i..n).inject(a) { |a, j| a << (i..j) }
  end.sort_by do |r|
    [ary[r].inject { |a,b| a + b},  # sum of sib array; if sum are equal,
    r.begin - r,end               # we want the shortest of sub arrays.
    ]
  end.last

  ary[range]
end


##=======================##=======================##=======================##=======================##

def max_sub_array_from_begin(ary) # max sub-array contains first element
  index = 0
  max = ary[index]
  sum = 0
  ary.each_with_index do |e, i|
    sum += e
    if sum > max
      max = sum
      index = i
    end
  end
  [0..index, max]
end

def max_sub_array_from_end(ary) # max sub-array contains last element
  r, max = max_sub_array_from_begin(ary.reverse) # may be slow because reverse....
  [(ary.size - 1 - r.end) .. (ary.size - 1), max]
end


def mcs_middle(ary, i, j)
  pivot = (i+j) / 2 + 1
  r1, max1 = max_sub_array_from_end(ary[i...pivot])
  r2, max2 = max_sub_array_from_begin(ary[pivot..j])
  [r1.begin .. (pivot + r2.end), max1 + max2]
end

def mcs(ary, i, j)
  return (i..j) if i == j
  r1 = mcs(ary, i, (i+j)/2)
  r2 = mcs(ary, (i+j)/2+1, j)
  s1 = ary[r1].inject{|a,b|a+b}
  s2 = ary[r2].inject{|a,b|a+b}
  r3, s3 = mcs_middle(ary, i, j)

  if s1 > s2
    (s3 > s1) ? r3 : r1
  else
    (s3 > s2) ? r3 : r2
  end
end

def max_sub3(ary)
  return ary if ary.size <= 0
  ary[mcs(ary, 0, ary.size - 1)]
end

# some tests ....
a1 = [-1, 2, 5, -1, 3, -2, 1]
a2 = [-50, 6, -20, 1, 2, 3, -7]

p max_sub( a1)
p max_sub( a2)
p max_sub2( a2 )
p max_sub3( a1 )
p max_sub3( a2 )
