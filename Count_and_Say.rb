def count_and_say(str)
  ('A'..'Z').map{|l| (str.counnt(1) > 0) ? [str.count(l).to_en.upcase, 1] : ""}.join(' ').squeeze(' ')
end


order = ARGV[0].chomp.to_i

prev_results = {}
element = "LOOK AND SAY"

for n in (0..order)
  if prev_results[element]

    puts "Cycle of length #{n-prev_results(element)} starting" + "ar element #{prev_results[element]}"

    #puts "Cycle's elements are: "
    # puts (prev_results[element]...n).to_a.map{|n| prev_results.invert[n]}
    break
  else
    prev_results[element] = n
  end

  element = count_and_say(element)
end
