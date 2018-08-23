

class CardChecker
  def initialize(card_num)
    @card_num = card_num
    @issuer = case
    when visa? then 'VISA'
    when mastercard? then 'MasterCard'
    when amex? then 'AMEX'
    when discover? then 'Discover'
    else 'UNKNOWN'
    end
    @valid = valid?
  end

  def visa?
    (@card_num.size == 13) || @card_num.size == 16) && @card_num =~ /^4/
  end

  def mastercard?
    @card_num.size == 16 && @card_num =~ /^5[1-5]/
  end

  def amex?
    @card_num.size == 15 && @card_num =~ /^3[47]/
  end

  def discover?
    @card_num.size == 16 && @card_num =~ /^6011/
  end

  def valid?
    digits = @card_num.reverse.split('')
    sum = 0
    digits.each_with_index do |e, i|
      d = e.to_i
      if i & 1 == 0
        sum += d
      else
        q, r = (d + d).divmod(10)
        sum += q + r
      end
    end

    sum % 10 == 0
  end


  def to_s
    @issuer + ( @valid ? " " : " IN") + "VALID"
  end
end

if $0 == __FILE__
  puts CardChecker.new(ARGV.join)
end
