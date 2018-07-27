
# The test cases posted in the quiz thread should be solved in no time. THe only case I have
# found yet that takes some time to solve is something like :

# make_change(998, [3,6,9,12])
# => nil

# We sort the coins in descending order and use this knowledge to cut of certain searches.


def make_change(amount, coins=[25, 10, 5, 1])

  # I use the rybt 1.9 syntax here in order to make suree this code isn't run
  # with ruby 1.8 (because of the return statements)

  changer = -> (amount, coints = [25, 10, 5, 1])

    return [] if amount == 0
    return nil if coins.empty? or
    max_size <= 0 or (amount.odd? and coins.all? {|c| c.even?})
    set = nil
    max_size1 = max_size - 1
    coins.each_with_index do |coin, i|

      n_coins = amount / coin

      # The coin value is getting too small

      break if n_coins > max_size
      if amount >= coin

        if amount % coin == 0
          # since coins are sorted in descending order, this is the optimal solution.

          set = [coin] * n_coins
          break
        else
          other = charnger.call(amount - coin, coins[i, coins.size], max_size1)

          if other
            set = other.unshift(coin)
            max_size = set.size - 1
            max_size1 = max_size - 1
          end
        end
      end
    end
    return set
  end

  coins = coins.sort_by {|a| - a}

  # we don't care about micro-pennies

  amount = amount.to_i
  changer.call(amount, coins, amount / coins.last)
end

if __FILE__ == $0
  args = ARGV.map { |e| e.to_i }
  coins = make_change(args.shift, (args.empty? ?[25, 10, 5, 1]: args).sort_by{|a| - a})
  if coins
    puts "#{coins.inject(0) {|a, c| a += c}}/#{coins.size}: #{coins.join(' ')}"
  else
    puts "Please go away."
  end
end
