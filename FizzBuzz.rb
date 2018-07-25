# This task itself is quite boring, so I decided to imagine how

# different programmers may try to pass the interview
# I hope we'll see what the recruiter may think.

# Java Programmer

def sol1 maxn = 100
  for i in 1..maxn
    if i%3 == 0 && i%5 == 0
      puts "FizzBuzz"
    elsif i%3 == 0
      puts "Fizz"
    elsif i%5 == 0
      puts "Buzz"
    else
      puts i
    end
  end
end


# Same as above but code is more manageable

def solla maxn = 100
  for i in 1..maxn
    if i % 3 == 0 && i%5 == 0
      s = "FizzBuzz"
    elsif i%3 == 0
      s = "Fizz"
    elsif i%5 == 0
      s = "Buzz"
    else
      s = i.to_s
    end
    puts s
  end
end

puts '##TCLa'

# Lisp Programmer

def sol2 maxn = 100
  puts( (1..maxn).map{ |i|
    i2s = lambda{ |n,s|
      if (i%n).zero : s else '' end
    }

    lambda{ |s|
      if s.empty? : i else s end
    }.call i2s[3, 'Fizz'] + i2s[5, 'Buzz']

    } )
end
puts '###TCLa'

# 1 year Ruby experience

def sol3 maxn = 100
  1.upto(maxn){ |n|
    s = "Fizz" if (n%3).zero?
    (s ||= '') << "Buzz" if (n%5).zero?
    puts s||n
  }
end

puts '###TC3'

# Trying to get extra points for reusability...

class Fixnum
  def toFizzBuzz
    s = 'Fizz' if modulo(3).zero?
    s = "#{s}Buzz" if modulo(5).zero?
    s || to_s
  end
end

def sol4 maxn
  1.upto(maxn){ |n| puts n.toFizzBuzz }
end

puts '###TC4'

## Extra points for expandability
# .. Who knows what else recruiters are looking for?

__END__
