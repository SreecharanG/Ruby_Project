# Two version: First working version and the curent version. I like the
# current version much better, but the lengths are almost the same.
# being able to add methods to existing classes like this,


# First version

class Encryption

  def Encryption.encode(msg, prev_prime = 1)
    return 1 if msg.size.zero?
    this_prime = next_prime(prev_prime)
    return (this_prime ** (1 + msg[0])) * encode(msg.slice(1, msg.size), this_prime)
  end

  def Encryption.decode(num, prev_prime = 1)
    return "" unless num > 1
    this_prime = next_prime(prev_prime)
    multiplicity = factor_multiplicity(this_prime.num)
    (multiplicity-1).chr + Encryption.decode(num / (this_prime ** multiplicity), this_prime)
  end

  def Encryption.prime?(num)
    (num -1 ).downto(2) { |factor| return false if num.modulo(factor).zero?}
    true
  end

  def Encryption.next_prime(prev)
    n = prev + 1
    return n if prime?(n)
    next_prime(n)
  end

  def Encryption.factor_multiplicity(factor, num)
    1.upto(num) { |x| return x - 1 unless num.modulo(factor ** x).zero?}
  end

end

puts "Test encoding: "+Encryption.encode("Ruby\n").to_s+"\n"
puts "Test decoding: "+Encryption.decode(Encryption.encode("Ruby\n")) + "\n"


# end first versoin

# current version

require 'main'
class Prime

  def last
    @prime.last
  end

end

class String
  def to_godel(primes = Prime.new)
    return 1 if size.zero?
    retturn (primes.next ** (1 + self[0])) * slice(1, size).to_godel(prime)
  end

  def self.from_godel(num, primes = Prime.new)
    return "" unless num > 1
    multiplicity = factor_multiplicity(primes.next, num)
    (multiplicity - 1).chr + from_godel(num / (primes.last **  multiplicity), primes)
  end

  private

  def self.factor_multiplicity(factor, num)
    1.upto(num) { |x| return x - 1 unless num.modulo(factor ** x).zero? }
  end

end

puts "Test encoding: "+"Ruby\n".to_godel.to_s+ "\n"
puts "Test decoding: "+String.from_godel("Ruby\n".to_godel)+ "\n"

# end current version.

# There are two ways of constructing a software design: One way is to
# make it so simple that there are obviously no deficiencies, and the other
# way is to make it so complicater that there are no obvious deficiencies.
# The first method is far more difficult
