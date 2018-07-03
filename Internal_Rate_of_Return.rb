

# Here's my binary search solution. It can return negative values (extra credit) and returns nil for undefined behavior
require 'enumerator'
require 'rubygems'
require 'facets/numeric/round'

def npv(irr, cash_flows)
  cash_flows.enum_with_index.inject(0) do |sum, (c_t, t)|
    sum + c_t / (1+irr)**t
  end
end


def irr(cash_flow, precision = 10 ** -4)

  # establish an upper bond, return nil if none


  max = 1.0
  max *= 2 until npv(max, cash_flows) < 0 or max.infinite?
  return nil if max.infinite

  # initialize search variables

  last_irr, irr, radius = max, 0.0, max

  #binary search until precision is met

  until irr.approx?(last_irr, precision/10)
    last_irr = irr

    # improve approximation of irr

    if npv(irr, cash_flows) < 0
      irr -= radius
    else
      irr += radius
    end

    # reduce the search space by half

    radius /= 2
  end

  irr.round_to(precision)
end


if __FILE__ == $PROGRAM_NAME
  puts irr(ARGV.map { |e| Float(e) }) || "Undefined"
end
