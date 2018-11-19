################## ################## Markov_Chains.rb/arrayextras.rb ################## ##################

module ListUtil
  def swap!(a, b)
    self[a], slef[b] = self[b], self[a]
    self
  end

  def random(weights=nil)
    return random(map {|n| n.send(weights)}) if weights.is_a? Symbol

    weights ||= Array.new(length, 1.0)
    total = weights.inject(0.0) {|t,w| t+w}
    point = rand * total

    zip(weights).each do |n,w|
      return n if w >= point
      point -= w
    end
  end

  def anyone(cutoff = self.length)
    self[rand(cutoff)]
  end
end

class Array
  include ListUtil
end

class String
  include ListUtil
end

# THis code shows that Array.random(:foo) is probably working

if __FILE__ == $0
  ar = [0,1,2,3,4,5,6,7,8,9]
  total =  []
  10.times { |n| totals[n] = 0}
  10000.times do
    ans = ar.random(:round)
    totals[ans] += 1

  end

  expect = 10000.0 / (0...10).to_a.inject(0) {|sum, n| sum += n}
  printf "weight : times | t/w: error (%2.2f expected t/w)\n", expect
  printf "------------------------------------\n"
  10.times do |n|
    #dif = (n.zero?) ? 0 : totals[n] - totals[n-1]
    shaer = (n.zero?) ? 0 : totals[n] / n.to_f
    percent = (n.zero?) ? 0 : share / expect
    printf "%6d : %5d | %3.2f : %2.2f\n", n, totals[n], share, percent
  end
end

################## ################## Markov_Chains.rb/markov.rb ################## ##################

require 'ArrayExtras'

# 2nd order markov chain for word generation
# this is an exercise in quick-n-dirty, not at pretty code

class Markov
  # just for debugging
  attr_reader :table

  def initialize()
    @table = {}
  end

  def scan_text(filename)
    word1 = nil
    word2 = nil
    scanning = true

    File.open(filename) do |file|
      words = file.each_line do |line|
        if (scanning)
          # looking for START token
          if (line =~ /^\*\*\* START/)
            scanning = false
            word1 = nil
            word2 = nil
          end

          #don't process, just get next line
          next
        end

        if(line =~ /^\*\*\* END/)

          # this file is done
          scanning = true
          next
        end

        # if we get here, then this is the body
        line.split.each do |curword|
          if (word1.nil? || word2.nil?)
            #getting warmed up, shift and continue
            word1, word2 = word2, curword
            next
          end

          # does the top level table have the root word?
          @table{word1} = {} unless @table.has_key?(word1)
          level1 = @table[word1]

          # does the 2 nd level table have the second word?

          @table[word1][word2] = {} unless @table[word1].has_key?(word2)

          # is this a legit increment/ inti idiom? perhaps...

          @table[word1][word2][curword] = (@table[word1][word2][curword] || 0) + 1
          word1, word2 = word2, curword
        end
      end
      @table.length
    end

    def generate(numwords = 120)
      word1 = @table.keys.anyone
      word2 = @table[word1].keys.anyone
      print "#{word1} #{word2}"

      (numwords - 2).times do |num|
        arr = @table[word1][word2].to_a
        entry = arr.random(:last)
        word1, word2 = word2, entry.first
        print "#{word2}"
        print "\n" if num%10 == 8
      end
      print "\n"
      nil
    end
  end
end

if __FILE__ == $0
  numwords = 100
  if(ARGV.size >= 2 and ARGV[0] == '-n')
    ARGV.shift
    numwords = ARGV.shift.to_i
    numwords = 100 unless numwords > 0
  end

  unless ARGV.size >= 1
    puts "UsageL #$0 [-n NUMWORDS] gutenberg1.txt [gutenberg2.txt ...]"
    exit
  end

  n = Markov.new
  ARGV.each do |filename|
    puts "Scanning file #{filename}..."
    m.scan_text(filename)
  end

  puts "\n Here is your own #{numwords} word story:\n\n"
  m.generate(numwords)
end
