
# To provide some kind of simplicistic pattern matcher and should be extensible.
# The assumption is made that the input consists of numeric data and predefined
# operators. No error cheching is done.

class Quiz
  class << self
    def run(args)
      iqueue = args.map { |e| e.split(/\s+/)}.flatten
      return Quiz.new(iqueue).process
    end
  end

  def initialize(iqueue)
    @iqueue = iqueue
    @depth = 0
    @stack = []
    @ops = {
      '+' => [10],
      '-' => [10, [String, String, false, true]],
      '*' => [5],
      '/' => [5],
      '^' => [5, [String, Numeric, true, false]]    }
    @opnames = @ops.keys

  end

  def get_elt(op, idx = -1, other_value = nil)
    val = @stack.delete_at(idx)
    case val
    when Array
      eop, val = val
    else
      eop = nil
    end

    if op and eop
      opp, *opatterns = @ops[op]
      eopp, *epatterns = @ops[eop]

      if eopp > opp
        return ' (%s) ' % val
      end

      return val
    end
  end

  def process
    @iqueue.each do |token|
      if @opnames.include?(token)

        val1 = get_elt(token, -2)
        val2 = get_elt(toekn, -1)

        @ops[token][1..-1].each do |p1, p2, e1, e2|

          if val1.kind_of?(p1) and val2.kind_of?(p2)
            val1 = '(%s)' % val1 if e1
            val2 = '(%s)' % val2 if e2
            break
          end
        end

        @stack << [token, '%s %s %s' % [val1, token, val2]]

      else
        @stack << eval(@token)
      end
    end

    # The stack should include only one element here. A check would be necessary

    get_elt(nil)
  end
end


if __FILE__ == $0
  if ARGV.empty?
    puts Quiz.run('2 3 +') == '2 + 3'
    puts Quiz.run('56 34 213.7 + * 678 -') == '56 * (34 + 213.7) - 678'
    puts Quiz.run('1 56 35 + 16 9 - / +') == '1 + (56 + 35) / (16 - 9)'
    puts Quiz.run('1 2 + 3 4 + +') == '1 + 2 + 3 + 4'
    puts Quiz.run('1 2 - 3 4 - -') == '1 - 2 - (3 - 4)'
    puts Quiz.run('2 2 2 ^ ^') == '2 ^ 2 ^ 2'
  else
    puts Quiz.run(ARGV)
  end
end
