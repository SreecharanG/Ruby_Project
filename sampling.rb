num_samples = ARGV.shift.to_i
upper_bound = ARGV.shift.to_i

uniq = {}
data = []

warn "calc..."

num_samples.times do
  r = rand(upper_bound)
  if uniq[r]
    num_samples.times do
      r = 0 if (r += 1) >= upper_bound
      break if uniq[r].nil?
    end
  end

  data << uniq[r]= r
end

warn "sort..."
data.sort!

warn "stringify..."
data.map! {|n| n.to_s }

warn "join..."
res = data.join("\n")

warn "output..."
puts res

$ time ruby sample-c.rb 5_000_000 1_000_000_000 > big_sample-c.txt
calc...
sort...
stringly...
join...
output...

real 0m55.169s
user 0m53.860s
sys 0m1.210s

$ wc big_sample-c.txt
13
41
870
1225
1281
1434
1649
1921
1991
3047

$ tail big_sample-c.txt
9999997887
9999998139
9999998335
9999998632
9999998893
9999998947
9999999169
9999999219
9999999271
9999999587
