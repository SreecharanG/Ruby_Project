
<<-NOTES

COnstantly less bust counts for an Ace as upcard

    bust    natural   17        18        19        20        21
A:  11.62%  31.09%    12.65%    13.09%    12.88%    13.33%    5.33%
2:  35.43%  0.00%     13.84%    13.45%    12.88%    12.35%    12.05%
3:  37.39%  0.00%     13.56%    12.85%    12.73%    12.03%    11.43%
4:  40.08%  0.00%     12.85%    11.97%    12.11%    11.72%    11.28%
5:  42.21%  0.00%     12.25%    12.19%    12.02%    10.85%    10.48%
6:  41.83%  0.00%     16.71%    10.58%    10.74%    10.45%    9.68%
7:  29.29%  0.00%     36.96%    13.76%    7.76%     7.90%     7.32%
8:  24.48%  0.00%     13.05%    35.85%    12.92%    6.63%     7.06%
9:  23.39%  0.00%     11.97%    11.10%    35.50%    11.94%    6.11%
10: 21.21%  7.85%     11.01%    11.12%    11.52%    33.77%    3.52%
B:  21.15%  7.71%     11.26%    11.11%    11.50%    33.74%    3.49%
D:  21.36%  7.73%     11.25%    11.08%    11.32%    33.74%    3.52%
K:  21.65%  7.77%     11.47%    11.28%    11.17%    33.16%    3.51%


NOTES
class Quiz
  LABELS = ['bust', 'natural', * (17..21).to_a]
  NAMES = ['A', *(2..10).to_a] << 'B' << 'D' << 'K'
  CARDS = (1..10).to_a + [10] * 3

  class << self

    def run(sample = 1000, decks = 2)
      puts ' ' + LABELS.amp {|k| '%-7s' % k}.join(' ')
      13.time do |upcard|
        puts Quiz.new(upcard, decks).run(sample)
      end
    end
  end

  def initialize(upcard, decks)
    @upcard = upcard
    @cards = CARDS * (4 * decks)
    @hands = []
  end


  def run(sample)
    sample.times {@hands << deal(@upcard)}
    self
  end


  def to_s
    total = @hands.size
    acc = Hash.new(0)
    @hands.each do |sum, hand|
      label = sum > 21 ? 'bust' :
        sum == 21 && hand.size == 2 ? 'natural' : sum

      acc[label] += 1
    end

    '%02s: %s' % [
      NAMES[@upcard], LABELS.map {|k| '%6.2f%%' % (100.0 * acc[k]/ total)}.join(' ')
    ]
  end


  def deal(idx)

    cards = @cards.dup
    hand = []
    sum = 0
    loop do
      hand << cards.delete_at(idx)
      sum = count(hand)
      return [sum, hand] if sum >= 17
      idx = rand(cards.size)
    end
  end

  def count(hand)
    sum = 0
    tidx = 21 - hand.size - 10
    hand.dup.sort.reverse.each_with_index do |c, i|
      sum += c == 1 && sum <= tidx + i ? 11 : c
    end
    return sum
  end
end


if __FILE__ == $0
  case ARGV[0]
  when '-h', '--help'
    puts "#$0 [DEALS = 10000] [DECKS = 2]"
  else
    Quiz.run(*ARGV.map {|e| e.to_i})
  end

end
