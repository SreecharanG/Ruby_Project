<<-Notes
This isn't much to look at, but it appears to be > 48 hours since the posting. So
I thougt I'd past it anyway.
I still can't generate the example pangrams given at http://www.cs.indiana.edu/~tanaka/GEB/
pangram.txt but it does generate this pangram in 1-5 minutes:

This terribly inefficient pangram contains five a's, two b's, three c's, two d's.
thirty-one e's, siz f's, four g's, ten h's, sixteen i's, one j, one k, three l's
tow m's, twnety n's, thirteen o's, two p's, one q, twelve r's, twenty-eight s's,
twenty-eight t's, three u's, three v's, nine w's, four x's, six y's, and one z

It's a basic randmoized robinsonziz...ing. With a rather absurb amount of test code.

-- pangram.rb
#!/usr/bin/ruby

Notes

require 'numeric_spell'

class SelfDocumentingPangram
  LETTERS = (?a..?z).to_a

  def initialize(starter_string = "This test starter contains")
    @start = starter_string
  end

  def to_s
    current = count(@start)
    actual = count(add_count(current))
    while current != actual
      LETTERS.each do |letter|
        current[letter] = rand_between(current[letter], actual[letter])
      end
      actual = count(add_count(current))
    end
    add_count(current)
  end


  def rand_between a,b
    range = (a - b).abs + 1
    rand(range) + [a, b].min
  end

  def add_count(counts)
    @start + counts_to_s(counts)
  end

  def count_to_s(char, count)
    if count != 1
      count.spell + " " + char.chr + "'s"
    else
      count.spell + " " + char.chr
    end
  end

  def counts_to_s(count)
    string_counts = []
    LETTERS.each do |letter|
      string_counts << count_to_s(letter, count[letter])
    end
    last = string_counts.pop
    string_counts.join(", ") + " and " + last + "."
  end

  def count(string)
    count = Hash.new(0)
    string.downcase.each_byte do |letter|
      if LETTERS.include? letter
        count[letter] += 1
      end
    end
    count
  end
end


if ARGV[0] =~ /test/i
require 'test/unit'

  class TestSelfDocumentingPangram < Test::Unit::TestCase
    # Checks that count will yield accurate counnts for only letters, ignoring case .

    def test_count
      # Check basic case containing only a..z
      string = ('a'..'z').to_a.to_s
      count = SelfDocumentingPangram.new.count(string)
      assert_equal(26, count.length)
      count.each(26, count.length)
      count.each do |key, value|
        assert_equal(1, value)
      end

      # Check case for a..z, A..Z, and some punctiation that we're likely to use.

      string = (('a'..'z').to_a + ('A'..'Z').to_a + ['\'', ',', '.', '-']).to_s
      count = SelfDocumentingPangram.new.count(string)
      assert_equal(26, count.length)
      count.each do |key, value|
        assert_equal(2, value)
      end
    end

    def test_count_to_s
      assert_equal("one a", SelfDocumentingPangram.new.count_to_s(?a, 1))
      assert_equal("fifteen z's", SelfDocumentingPangram.new.count_to_s(?z, 15))
      assert_equal("forty-two d's", SelfDocumentingPangram.new.count_to_s(?d, 42))
    end

    def test_count_to_s
      start = "The last of these contains"
      expected = "two a's, zero b's, one c, one d, four e's, one f, zero g's, two h's, one i,
                zero j's, zero k's, one l, zero m's, two n's, two o's, zero p's, zero q's,
                zero r's, two s's, four t's, zero u's, zero v's, zero w's, zero y's and zero z's"

      pangram = SelfDocumentingPangram.new
      result = pangram.count_to_s(pangram.count(start))
      assert_equal(expected, result)
    end

    def test_rand_between
      100.times do
        a = rand(100)
        b = [a, rand(100)].max
        c = SelfDocumentingPangram.new.rand_between(a, b)
        assert (a..b) == c, "#{c} is not between #{a} and #{b}"
      end
    end

    def test_add_count
      pangram = SelfDocumentingPangram.new("hi ")
      count = Hash.new(0)
      expected = "hi " + pangram.counts_to_s(Hash.new(0))
      assert_equal(expected, pangram.add_count(Hash.new(0)))
    end

    # Runs the SelfDocumentingPangram class to verufy that it can produce the pangrams fount at
    # http://www.cs.indiana.edu/~tanaka/GEB/pangram.txt

    def to_s
      pangram1 = "This pangram tallies five a's, one b's, one c, two d's, twenty-eight e's,
      eight f's, six g's, eight h's, thirteen i's, one j, one k, three l's, two m's, eighteen n's
      fiftenn o's, two p's, one q, seven r's, twenty-five s's, twenty-two t's, four u's, four v's,
      nine w's, two x's, four y's and one z. "
      assert_equal(pangram1, SelfDocumentingPangram.new("This pangram tallies ").to_s )

      #pangram2 = "This computer-generated pangram contains six a's, one b, three c's, three d's
      # thirty-seven e's, six f's, three g's, nine h's, twelve i's, one j, one k, tow l's, three m's,
      # twenty-two n's, thirteen o's, three p's, one q, fouteen r's, twenty-nine s's, twenty-four t's
      # five u's, six v's, seven w's, four x's, five y's and one z"

      # assert_equal(pangram2, SelfDocumentingPangram.new("This computer-generated pangram contains").to_s)
    end

    # This is mainly a sanity check to see that a pangram will evalutate to itself when counted and regenerated.

    def test_approach
      prefix = "This pangram tallies"
      solution = "This pangram tallies five a's, one b, one c, two d's, twenty-eight e's, eight f's
      six g's, eight h's, thirteen i's, one j, one k, three l's, two m's, eighteen n's, fifteen o's, two p's,
      one q, seven r's, twnety-five s's, twenty-two t's, four u's, four v's, nine w's, two x's, four y's
      and one z"
      pangram = SelfDocumentingPangram.new(prefix)
      assert_equal(solution, pangram.add_count(pangram.count(solution)))

      prefix = "This terribly inefficient pangram contains"
      solution = "This terribly inefficient pangram contains five a's, two b's, three c's, two d's, thirty-one e's,
      siz f's, four g's, ten h's, sixteen i's, one j, one k, three l's, two m's, twenty n's, thirteen o's,
      two p's, one q, twelve r's, twenty-eight s's, six y's and one z"
      pangram = SelfDocumentingPangram.new(prefix)
      assert_equal(solution, pangram.add_count(pangram.count(solution)))
    end
  end

else
  puts SelfDocumentingPangram.new("This terribly inefficient pangram contains").to_s
end
