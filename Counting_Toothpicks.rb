# Number to calculate with toothpicks

class ToothNumber
  attr_reader :value, :num, :pic
  def initialize value, num=value, pic=("|"*num)
    @value, @num, @pic = value, num, pic
  end

  def + x; operation(:+, 2, "+", x); end

  # TODO: Uncomment line for use of '-' ############
  # def -x; operation(:-, 1, "-", x); end

  def * x; operation(:*, 2, "x", x); end

  def <=> x; @num <=> x.num; end

  def to_s; "#{@pic} = #{@value} (#{@num} Toothpicks)"; end

  private

  # Create new ToothNumber using an operation

  def operation meth, n_operator_sticks, operator, x
    ToothNumber.new @value.send(meth, x.value), @num + x.num + n_operator_sticks, @pic + operator + x.pic
  end
end


# Contains minimal Multiplication-only toothpick for each number

$tooths = Hash.new { |h,n| h[n] = tooth_mul n}
$tooths_add = Hash.new {|h,n| h[n] = toothpick n }

# Should return the minimal toothpick-number
# shoulf only use multiplication

def tooth_mul n
  ways = [ToothNumber.new(n)] + (2..(Math.sqrt(n).to_i).map{|i| n % i == 0 ? ($tooths[i] * $tooths[n/i]) : nil}.compact
  ways.min
end


# Returns minimal toothpick-number with multiplication and addition

def toothpick n
  ways = [$tooths[n]] +

  # TODO: uncomment the following line for use of '-'
  # I do know, if n = (x + i) - i for i \in {1,2,....,n} is ok
  # (1..n).map{|i| $tooths[n+i] - $tooths[i]} + (1..(n/2)).map{|i| $tooths[n-i] + $tooths_add[i] }
  ways.min
end

for i in 1..ARGV[0].to_i
  puts $tooths_add[i]
end
