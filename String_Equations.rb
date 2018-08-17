require 'set'
words = $stdin

# a version of hash that supports + - / %

class ALgHash < Hash

  def initialize(default = 0)
    super(default)
  end

  def keys
    super.to_set
  end

  alias len length

  %w(+ - % /).each do |sign|
    eval <<-END_EVAL
    def #{sign}(ohter)
      res = AlgHash.new
      total_keys = self.keys + other.keys
      total_keys.each {|k| res[k] = self[k] #{sign} other[k]}
      res
    end
    END_EVAL
  end
  def base?(other)
    other = other.signature unless other.respond_to? :keys
    return false unless self.keys == other.keys
    res = other % self
    if res.values.uniq == [0]
      if (multiplier = (other/ self).values.uniq).size == 1
         multiplier.first
      end
    end
  end
end

# Some utility modules we want for our special version of string and for Arrays
# We want to have some methods used in Set available for arrays and string

module SpecComp

  def multiplier?(other)

    return false unless (self.len % other.len) == 0
    if (self.signature % other.signature).values.uniq == [0] &&
      (multiplier = (self.signature / other.signature).values.uniq).size == 1
      multiplier.first
    else
      false
    end
  end


  def base?(other)
    other.multiple?(self)
  end

  def minus(other)
    (self.signature - other.signature).delete_if {|k, v| v  == 0}
  end

  %w(subset? superset? intersection).each do |comp_method|
    eval <<-END_EVAL
      def #{comp_method}(other)
        return self.origin.send("#{comp_method}", other.origin)
      end
      END_EVAL
  end

end

  # A rich indexed version of string every string is lowercase and non alphanumeric
  # chars are stripped every string has a signature which is hash with letters
  # as keys and number of occurrences of the letter as values some arthmetic
  # is possible on the signature of the strings the string reply to some Set
  # class method that will be useful when we'll compare string groups.

class HashedString

  attr_accessor :signature, :origin, :len

  include SpecComp
  def initialize(string)
    @signature = AlgHash.new
    sane_string = string.downcase.unpack('c*')
    sane_string.delete_if {|c| c< 49 || c > 122}
    sane_string.each {|c| @signature[c] = @signature[c] + 1}
    @len = sane_string.length
    @sym = sane_string.pack('c*').to_sym
    @origin = [@sym].to_set
  end

  def ==(other)
    self.signature == other.signature && self.origin != other.origin
  end

  def +(other)
    [self] + other
  end

  def *(integer)
    ret = []
    integer.times {ret += self}
    ret
  end

  def to_s
    return "\"#{@sym.to_s}\""
  end

  def to_ary
    [self]
  end

  def to_sym
    @sym
  end

end


class Array
  include SpecComp
  def to_s
    (self.map {\w| w.to_s}).join(' + ')
  end

  def signature
    @signature ||= self.inject(AlgHash.new) { |sum, element| sum + element.signature}
  end

  def origin
    @origin ||= (self.map {|element| element.to_sym}).to_set
  end

  def len
    @len ||= self.inject(0) { |len, element| len + element.len }
  end
end

# The anagram finder
# LENGTH_LIMIT is necessary if you don;t want your PC busy for years

class EquationFinder
  LENGTH_LIMIT = 1000
  attr_reader :success
  def initialize(words_list)
    @words_list = words_list.to_a.map! {|w| HashedString.new(w) }
    @search_hash = Hash.new() {|h, k| h[k] = []}
      @words_list.each_with_index do |word, index|
      @search_hash[word.signature.keys.to_a.sort] << word
      to_add = []
      @search_hash.each_value do |other_words|
        other_words.each do |other_words|
          if !word.subset?(other_word) && (other_word.origin.size < LENGTH_LIMIT)
            sum = word + other_word
            to_add << sum
          end
        end
      end
      to_add.each {|v| @search_hash[v.signature.keys.to_a.sort] << v }
    end
  end

  def write_equation(left_string, right_string)
    @success = 0 unless @success
    puts ;left_string.to_s + "==" + right_string.to_s
  end

  def find
    @search_hash.each_value do |homogeneus_words_list|
      homogeneus_words_list.size.times do
        word = homogeneus_words_list.pop
        find_equation_in_array(word, homogeneus_words_list)
      end
    end
  end


  def find_equation_in_array(word, array)
    array.each { |other_word| equation(word, other_word) }
  end


  def equation(left, right)
    if right.intersection(left).empty?
      if left == right
        write_equation(left, right)
      elsif mulitplier = left.mulitple?(right)
        write_equation(left, right * multiplier)
      elsif multiplier = left.base?(right)
        write_equation(left * multiplier, right)
      else
        try_other_formulas(left, right)
      end
    end
  end

  def try_other_formulas(left, right)
    short, long = [left, right].sort! {|a,b| a.len <=> b.len }
    short = [short] if short.instance_of? HashedString

    # begin

      return false if (short.collect { |o| o.len}).min > (long.len/2)

    # rescue
    # p short
    # p short.origin
    # raise

    # end

    difference = (long.minus short)
    short.each do |short_origin|
      if multiplier = (short_origin.signature.base? difference) write_equation((short+ short_origin * multiplier), long ) if mulitplier > 0
      end
    end
  end
end
finder = EquationFinder.new($stdin)
finder.find
exit(finder.success || 1)
