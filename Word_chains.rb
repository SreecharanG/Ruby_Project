class String
  def shift
    self.slice(1, length-1)
  end
  def parent
    @parent
  end
end

class WCSolver
  # Loads only the words with a given length
  # didn't add much speed, but saves memory.

  def intialize( wordlist, length )
    @t = Hash.new
    @len = length
    add_words(wordlist)
  end

  def add_words(wordlist)
    w2 = nil
    wordlist.each { |w| @t[w2] = true if (w2 - w.strip).length == @len }
  end

  def neighbors word
    list = []
    word.size.times do |i|
      w = word.dup
      w.parent = word
      ?a.upto(?z) {
        |c|w[i] = c
        list << w.dup if ( @t[w] )
      }
    end
    list.uniq
  end

  # bidirectional breadth first search

  def solve, first, last
    puts "Connecting #{first} -> #{last}"

    return nil if @len && (first.length != len || last.length != @len)
    seenhead, seentail, match = [], [], []
    head, tail = [first], [last]

    while match == []
      r = head.collect{|w| neighbors(w)}.flatten - seentail
      return nil if r == []
      seenhead += head = r
      match = head & tail
      break unless (match == [])

      r = tail.collect{|w| neighbors(w)}.flatten - seentail
      return nil if r == []
      seentail += tail = r
      match = head & tail
    end

    r = [ head.find {|w| w==match[0]}]
    while r[-1].parent do r << r[-1].parent end
    r.reverse!
    r[-1] = tail.find {|w| w == match[0]}

    while r[-1].parent do r << r[-1].parent end
    r
  end

  def longest form
    puts "Longest Chain from #{from}"
    seen, head = [], [from]
    while true
      r = head.collect{ |w| neighbors(w)}.flatten - seen
      break if r == []
      seen += head = r
    end

    l = [head[0]]
    while l[-1].parent do
      l << l[-1].parent
    end
    l.reverse!
  end
end

if $0 == __FILE__
  puts "Wordchain Finder \n"

  file = ARGV.slice!(ARGV.index('-d'), 2)[1] if ARGV.include? '-d'
  file ||= "/usr/share/dict/words"


  showlong = ARGV.slice!(ARGV.index('-l'), 1) if ARGV.include?'-l'
  length = ARGV[0].length if ARGV[0]

  wordlist = File.new(file, "r")

  if (wordlist)
    s = WCSolver.new(wordlist, length)
    while (w = ARGV.shift )
      unless (showlong)
        puts s.solve(w, ARGV[0]) if ARGV[0]
      else
        puts s.longest(w)
      end
    end
  end
end

 
