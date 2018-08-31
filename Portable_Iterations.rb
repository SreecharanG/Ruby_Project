mode = nil
if ARGV[0] =~ /-([sv])/
  mode = $1
  ARGV.shift
end

if ARGV.length != 2
  $strderr.puts "Usage: #{$0} [-s|-v] NUM_DICE MIN_FIVES"
  exit 1
end

n_dice = ARGV[0].to_i
min_fives = ARGV[1].to_i
possible_outcomes = 6 ** n_dice
desirable_outcomes = 0
max_digits = ( Math.log(possible_outcomes+1) / Math.log(10) ).ceil

outcome = [1] * n_dice
for i in 0...possible_outcomes
  desirable = outcome.select { |n| n == 5 }.length >= min_fives
  if mode == "v" || mode == "s" && ( i % 50_000 ).zero?
    puts "#{'% * d' % [ max_digits, i+1 ]} [#{outcome.join(',')}]#{desirable ? ' <==' : ''}"
  end

  desirable_outcomes += 1 if desirable

  for die in 0...n_dice
    if outcome[die] == 6
      outcome[die] = 1
    else
      outcome[die] += 1
      break
    end
  end
end


puts
puts "Number of desirable outcomes is #{desirable_outcomes}"
puts "Number of possible outcomes is #{possible_outcomes}"
puts

puts "Probability is #{desirable_outcomes.to_f / possible_outcomes}"
