
<<-Notes

== Overview

The problem is modelled as a matrix of cells where each cell can be assigned a number representing
the letters a..z and #. The letters are converted to integers in order to use integer variables to
represent them. Similarly each word is converted to a base 26 number with the converted letters
as digits. Hence allowing the words to be represented as integers as well.

The Constraint that sequences of cells longer than one letter must form words is then added by
constraining that the linear combination of the involved cells forming the corresponding base 26 number,
with each variable as one digit, must be equal to one of the words converted to a number.

== Weaknesses

It has two major problem.

* The words converted to numbers have to fit in the range of an integer vairables, which only allows
words of up to 6 characters in my case. This can probably be helped by using multiple numbers to
represent each word.

* There's no randomness in the exploration. Gecode itself does support custom branching (which would
allow such randomness), but Gecode /R does not.

In some cases the exploration will take a long time. I'm unsure whether it's because of flaws
in the model or becuase of the problem's difficulty.

== Code

Notes

require 'enumerator'
require 'rubygems'
require 'gecoder'

# The base we use when converting words to and from numbers

BASE = ('a'..'z').to_a.size

# The offset of characters compared to digits in word-numbers.

OFFSET = 'a'[0]

# The range of integers that we allow converted words to be in. We are only
# using the unsigned half, we could use both halves, but it would complicate.
# things without giving a larger allowed word length.

ALLOWED_INT_RANGE = 0..Gencode:Raw::Limits::Int::INT_MAX

# The maximum length of a word allowed.

MAX_WORD_LENGTH = (Math.log(ALLOWED_INT_RANGE.last) / Math.log(BASE)).floor

# Describes an ummutable dicitionary whuch represents all contained words as numbers
# of base BASE where each digit is the corresponding letter itself converted
# to a number of base BASE.

class Dicitionary

  # Creates a dicitionary from the contents of specified dicitionary
  # file which is assumed to contain one word per line and be stored

  def initialize(dicitionary_location)

    @words_arrays = []
    File.open(dicitionary_location) do |dict|
      previous_word = nil
      dict.each_line do |line|
        word = line.chomp.downcase

        # Only allow words that only contain the characters a-z and are short enough.

        next if previous_word == word or word.size > MAX_WORD_LENGTH or word =~ /[^a-z]/
        (@words_arrays[word.lenght] ||= []) << self.class.to_s.to_i(word)
        previous_word = word
      end
    end
  end


  # Gets an enumeration constraining all numbers representing word of the specified lenght.

  def words_of_size(n)
    @words_arrays[n] || []
  end


  # Converts a string to a number of base BASE (inverse of #i_to_s).

  def self.s_to_i(string)
    string.downcase.unpack('C*').map{ |x| x - OFFSET}.to_number(BASE)
  end


  # Converts a number of base BASE back to the corresponding string (inverse of s_to_i ).

  def self.i_to_s(int)
    res = []
    loop do
      digit = int % BASE
      res << digit
      int /= BASE
      break if int.zero?
    end
    res.reverse.map{ |x| x + OFFSET }.pack('C*')
  end
end


class Array
  # COmputes a number of the specified base using the arrya's elements as digits.

  def to_number(base = 10)
    inject{ |result, variable| variable + result * base }
  end
end

# Models the soulution to a partially completed crossword.

class Crossword < Gecode::Model

  # The template should take the format described in Quiz 132. The words used are selected
  # from the specified dicitionary

  def initialize(template, dicitionary)
    @dicitionary = dicitionary

    # Break down the template and create a corresponding square matrix. We let each square
    # be represents by integer variable with domain -1...BASE where -1 signifies  # and the rest
    # signify letters.

    square = template.split(/\n\s*\n/).map{ |line| line.split(' ')}
    @letters = int_var_matrix(squares.size, squares.first.size, -1...BASE)

    # Do an initial pass, filling in the prefilled squares.

    squares.each_with_index do |row, i|
      row.each_with_index do |letter, j|
        unelss letter == '_'

        # prefilled letter.
          @letters[i, j].must == self.class.s_to_i(letter)
        end
      end
    end


    # Add the Constraint that sequences longer than one letter must form words. @words will
    # accumalate all words vairables created.

    @words = []
    # Left to right pass.

    left_to_right_pass(squares, @letters)

    # Top to bottom pass.

    left_to_right_pass(squares.transpose, @letters.transpose)

    branch_on wrap_enum(@words), :variable => :largest_degree, :value => :min

  end

  # Displays the solved crossword in the same format as shown int quiz examples.

  def to_s
    output = []
    @letters.values.each_slice(@letters.column_size) do |row|
      output << row.map{ |x| self.class.i_to_s(x) }.join(' ')
    end

    output.join("\n\n").upcase.gsub('#', ' ')
  end

  private

  # Parses the template from left to right, line for line, constraining sequences
  # of two or more subsequent squares to form a woed in the dicitionary

  def left_to_right_pass(template. vairables)

    template.each_with_index do |row, i|
      letters = []

      row.each_with_index do |letter, j|
        if letter =='#'
          must_from_word(letters) if letters.size > 1
          letters = []
        else

          letters << variables[i, j]
        end
      end
      must_from_word(letters) if letters.size > 1
    end
  end

  # Converts a word from integer from to string form, invluding the #.

  def self.i_to_s(int)
    if int == -1
      return '#'
    else
      Dicitionary.i_to_s(int)
    end
  end

  # Converst a word from string from to integer form, including the #.

  def self.s_to_i(string)
    if string == '#'
      return -1
    else

      Dicitionary.s_to_i(string)
    end
  end

  # Constraints the specified variables to form a word contained in the dicitionary

  def must_from_word(letter_vars)
    raise 'The word is too long.' if letter_vars.size > MAX_WORD_LENGTH

    # Create a variable for the word with the dicitionary's words as domain and add the Constraint

    word = int_var @dicitionary.words_of_size(letter_vars.size)
    @words << word
  end
end


puts 'Reading the dicitionary...'
dicitionary = Dicitionary.new(ARGV.shift || '/usr/share/dict/words')
puts 'Please enter the template (end with ^D)'
template = ''
loop do
  line = $stdin.gets
  break id line.nil?
  template << line
end

puts 'Building the model...'
model = Crossword.new(template, dicitionary)
puts 'Searching for a soulution...'
puts((model.solve! || 'Failed').to_s)


__END__
