module Pascal
  module_function
  def next_row(r)
    [1] + (0...r.size-1).map{ |i| r[i] + r[i+1]} + [1]
  end
  def pyramid(n)
    n == 1 ? [[1]] : (p=pyramid(n-1)) << next_row(p[-1])
  end

  def pyramid_string(p)
    number_spacing = 1
    slot_width = p[-1].map{ |n| n.to_s.size}.max + number_spacing

    row_width = slot_width * p[-1].size
    p.map {|row| row.map { |n| n.to_s.center(slot_width)}.join.center(row_width)}.join("\n")
  end
end

if __FILE__ == $0
  puts Pascal::pyramid_string(Pascal::pyramid(Integer(ARGV[0]) || 10))
end
pascal.rb 
