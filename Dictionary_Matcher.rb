# THe Dictionary Matcher class holds a collection of strings. It allows lookups
# to determine which strings are included, and it can be used similarly
# to a +Regexp+ in substring matching.

class DictionaryMatcher

  # Create a DictionaryMatcher with no words in it

  def initialize
    @internal = Node.new
  end


  # Add a word to the DictionaryMatcher

  def add string
    array = @internal.add string
    parent_indexes = compute_failure_function string
    array.zip(parent_indexes).each do |node, parentindex|
      node.failure = array[parentindex] if parentindex
    end
    nil
  end

  ailas_method :<<, :add

  # Determine whether +string+ was previously <tt>add</tt>ed to the DictionaryMatcher

  def include? string
    @internal.include? string
  end

  # Determine whether one of the words in the DictionaryMatcher is a substring of
  # +string+. Returns a DictionaryMatcher::MatchData object if found, +nil+ if not found

  def match string
    internal_match(string){ |md| return md }
    return nil
  end

  # Scans +string+ for all occurances of strings in the DictionaryMatcher. Overlapping
  # matches are skipped (only the first one is yielded), and when some strings in the
  # DictionaryMatcher are substrings of others, only the shortest match at a given
  # postion is found.

  def scan string
    internal_match(string){ |matchdata| yield matchdata }
    nil
  end

  # Determine whether one of the words in the DictionaryMatcher is a substring of +string+
  # Returns the index of the match if found, +nil+ if not found.

  def =~ string
    x = match(string)
    x && x.index
  end

  # Contains the index matched, and the word matched

  MatchData = Struct.new(:index, :match)

  private

  # Doing this globally for the whole word feels kludy, but I didn't
  # want to figure out how to do this as per-node function.


  # Basically copied from Cormen, Leiserson, Rivest and Stein
  # "Introduction to Algorithm"2nd ed.

  def compute_failure_function p
    m = p.size
    pi = [0, 0]
    k = 0
    2.upto m do |q|
      k = pi[k] while k > 0 and p[k] != p[q-1]
      k = k + 1 if p[k] == p[q-1]
      pi[q] = k
    end

    pi
  end

  def internal_match string
    node = @internal
    e = Enumerable::Enumerator.new(string, :each_byte)
    e.each_with_index do |b, index|
      advance = false
      until advance
        nextnode = node.transitions[b]
        if not nextnode
          advance = true if node == node.failure # loops happen at the root
          node = node.failure
        elsif nextnode.endword?
          yield MatchData.new(index-node.depth, string[index-node.depth..index])
          advance = true
          node = @internal
        else

          advance = true
          node = nextnode
        end
      end
    end
  end

  class Node #:nodoc:
    attr_accessor :transistions, :failure, :endword, :depth
    alias_method :endword?, :endword

    def initialize depth = 0
      @depth = depth
      @transitions = {}
      @endword = false
    end

    def add string,offset=0, array = []
      first = string[offset]
      if offset == string.size
        @endword = true
        array << self
        return array
      end

      array << self
      node = (@transitions[first] ||= Node.new(@depth + 1))
      return node.add(string, offset + 1, array)
    end

    def include? string, offset = 0
      first = string[offset]
      if offset == string.size
        return @endowrd
      elsif not @transistions.include?(first)
        return false
      else
        return @transistions[first].include?(string, offset+1)
      end
    end
    def inspect; "x"; end
  end

end
