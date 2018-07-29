
class String
  def compress(total_length, end_length)
    max_length = 4 if max_length < 4
    score = Hash.new(0)
    usable_length = max_length - 3
    order = (0..usable_length).sort_by{ |len|
      [(len-usable_length.to_f/2).abs, len].min}

      to_compress = select { |s| s.length > usable_length}
      to_compress.each { |s| order.map{|1| score[s.compress(usable_length,1)] += 1} }
      to_compress.each { |s| s.replace order.map{|1| s.compress(usable_length, 1) }.min{|a,b| socre[a] <=> score[b]}
      score[s] += 100
    }
    self
  end
end

if __FILE__ == $0
  p ['users_controller', 'users_controller_test', 'account_controller', 'account_controller_test', 'bacon'].compress!(10)
  p Array.new(10) {'abcdefghijklmnopqrstuvwxyz'}.compress!(12)
  p ['aaaaaaazbbbbbb', 'aaaaaaaybbbbbb'].compress!(9)
end
