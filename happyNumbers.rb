class Integer
  @@happysteps = Hash.new{ |k,v| k[v] = {} }
  def happy?( base = 10 )
    seen = {}
    num =self
    until num == 1 or seen[ num ]
      seen[ num ] = true
      num = num.to_s(base).split('').map{ |c| c.to_i(base)**2 }.inject{ |s,i| s+i }
    end
    num == 1
  end
end

happy = Hash.new{ |h1, base|
  h1[ base ] = Hash.new{ |h2, n|
    if n == 1
      h2[ 1 ] = true
    else
      h2[ n ] = :not_happy
      sum_of_squares = n.to_s(base).split('').map{ |c| c.to_i(base) ** 2}.inject{ |s,i| s+i }
      if sum_of_squares == 1
        h2[ n ] = true
      else
        subn = h2[ sum_of_squares ]
        if subn == true
          h2[n] = true
        elsif subn == false || subn == :not_happy
          h2[n] = h2[sum_of_squares] = false
        end
      end
    end
  }
}

range = 1..1000
puts "How many Happy numbers between #{range}?"
3.upto(36) { |base|
  puts "Base #{base}: #{range.select{ |i| happy[ base ][ i ]}.length} happy numbers."
  puts "Base #{base}: #{range.select{ |i| i.happy?( base )}.length} happy numbers."
}
