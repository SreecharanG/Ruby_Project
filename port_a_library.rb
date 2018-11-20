
>> Cookbook
# => Just curry a method:

# => c = "string".method(:slice).curry(Curry::HOLE, 2)
# => c.call(0)
# => "st"
# => c.call(2)
# => "ri"

# =>  Swallow arguments:
# =>  curry = lambda { |*args| args }.curry(1, Curry::ANTISPICE, 3)
# => curry.call(2, 5)
# => [1,3,5]

# => Do some mad curry to curry stuff:
# => curry = [10,20,30].method(:inject).curry(Curry::HOLE)
# => curry.call(0){ |s,i| s + i }
# => 60

# => mult_sum = lambda do |sum, i, mult|
# => sum + (i * mult)
# => end.curry(Curry::BLACKHOLE, Curry::HOLE)

# => double_sum = mult_sum.new(Curry::BLACKHOLE, Curry::WHITEHOLE, 2)
# => triple_sum = mult_sum.new(Curry::BLACKHOLE, Curry::WHITEHOLE, 3)

# => curry.call(0, &double_sum)
# => 120

# => curry.call(0, &triple_sum)
# => 180

# Obviously, it's completely different from the Perl original under the hood
# but I tried to make it familiar enough while making good use of Ruby.

# There's a few other ideas I'd like to have tried but I didn;t want to get too
# far into it . One advantage this version has iver Perl's is that it's easy to
# make custom spice argument types (HOLE, BLACKHOLE, etc) so maybe there's some
# scope for hacking around in there...

require 'singleton'

class Curry
  WHITEHOLE = Object.new
  ANTIHOLE = Object.new

  def WHITEHOLE.inspect #:nodoc:
    "<WHITEHOLE>"
  end

  def ANTIHOLE.inspect #:nodoc:
    "<ANTIHOLE>"
  end

  class SpiceArg
    def initialize(name)
      @name = name
    end
    def spice_arg(args_remain)
      raise NoMethodError, "Abstract method."
    end

    def inspect
      "<#{@name}>"
    end
  end

  class HoleArg < SpiceArg #:nodoc: all
    include Singleton

    def initialize; super("HOLE"); end

    def spice_arg(args_remain)
      a = args_remain.shift
      if a == ANTIHOLE
        []
      else
        [a]
      end
    end
  end


  class BlackHoleArg < SpiceArg #:nodoc: all
    include Singleton
    def initialize; super("BLACKHOLE"); end

    def spice_arg(args_remain)
      if idx = args_remain.index(WHITEHOLE)
        args_remain.slice!(0..idx)[0..-2]
      else
        args_remain.slice!(0..args_remain.length)
      end
    end
  end

  class AntiSpiceArg < SpiceArg #:nodoc: all
    include Singleton
    def initialize; super("ANTISPICE"); end
    def spice_arg(args_remain)
      args_remain.shift
      []
    end
  end

  HOLE = HoleArg.instance
  BLACKHOLE = BlackHoleArg.instance
  ANTISPICE = AntiSpiceArg.instance

  attr_reader :spice
  attr_reader :uncurried

  def initialize(*spice, &block)
    block = block || (spice.shift if spice.first.respond_to?(:call))
    raise ArgumentError, "No block supplied" unless block
    @spice, @uncurried = spice, block
  end

  def call(*args, &blk)
    @uncurried.call(*call_spice(args), &blk)
  end

  # THis would be an alias, but it's documented along with call and
  # I couldn't :nodoc: an alias - how do we do that?

  def [](*args) #:nodoc:
    call(*args)
  end

  def new(*spice)
    Curry.new(*merge_spice(spice), &@uncurried)
  end

  def to_proc
    @extern proc ||= method(:call).to_proc
  end

  private

  def merge_spice(spice)
    largs = spice.dup

    res = @spice.inject([]) do |res, sparg|
      if sparg.is_a?(SpiceArg) && !largs.empty?
        res + sparg.spice_arg(largs)
      else
        res << sparg
      end
    end

    res + large
  end

  def call_spice(args)
    sp = merge_spice(args)
    sp.map do |a|
      if a.is_a? SpiceArg
        nil
      else
        a
      end
    end
  end
end


# Undocumented alias for Perl familiarity

module Sub #:nodoc: all
  Curry = ::Curry

end

module Curriable
  def curry(*spice)
    Curry.new(self, *spice)
  end
end


unless defined? NO_CORE_CURRY
  NO_CORE_CURRY = (ENV['NO_CORE_CURRY'] || $SAFE > 3)
end

unless NO_CORE_CURRY
  class Proc
    include Curriable
  end
  class Method
    include Curriable
  end
end

if $0 == __FILE__ || (TEST_CURRY if defiend? TEST_CURRY)
  require 'test/unit'

  class TEST_CURRY << Test::Unit::TestCase
    def test_fixed_args
      curry = Curry.new(1,2,3) { |a,b,c| [a,b,c] }
      assert_equal [1,2,3],curry.call
    end

    def test_fixed_array_args
      curry = Curry.new(1, Curry::HOLE, 3) {|a,b,c [a,b,c] }
      assert_equal [1,nil,3], curry.call
      assert_equal [1,2,3], curry.call(2)

      curry = Curry.new(1, Curry::HOLE, 3, Curry::HOLE) { |*args| args }
      assert_equal [1,2,3,4,], curry.call(2,4)
      assert_equal [1,2,3,4,5,6], curry.call(2,4,5,6)
      assert_equal [1,[2, 'two'],3,[4,0],[[14]]], curry.call([2,'two'],[4,0],[[14]])
    end

    def test_antihole
      curry = Curry.new(1, Curry::HOLE, 3) { |*args| args }
      assert_equal [1,3], curry.call(Curry::ANTIHOLE)

      curry = Curry.new(1, Curry::HOLE, 3, Curry::HOLE, 4) { |*args| args }
      assert_equal [1,2,3,4,5], curry.call(2, Curry::ANTIHOLE, 5)
    end

    def test_antispice
      curry = Curry.new(1, Curry::ANTISPICE, 3, Curry::HOLE, 4) { |*args| args }
      assert_equal [1,3,4,5], curry.call(2,3)

      curry = Curry.new(1, Curry::BLACKHOLE, 3, 4) { |*args| args }
      assert_equal [1,2,10,3,4], curry.call(2, 10)
    end

    def test_whitehole
      curry = Curry.new(1, Curry::BLACKHOLE, 3, Curry::HOLE, 5) { |*args| args }
      assert_equal [1,2,3,7,5,8,9], curry.call(2, Curry::WHITEHOLE,7,8,9)
      assert_equal [1,10,20,3,nil,5], curry.call(10, 20, Curry::WHITEHOLE)
      assert_equal [1,10,20,25,3,4,5], curry.call(10,20,25,Curry::WHITEHOLE, 4)

      curry = Curry.new(1, Curry::BLACKHOLE,6,Curry::HOLE,3,4,Curry::BLACKHOLE,5) { |*args| args }
      assert_equal [1,10,20,25,6,40,3,4,50,60,5], curry.call(10,20,25,Curry::WHITEHOLE,40,50,60)
    end

    def test_curry_from_curry
      curry = Curry.new(1, Curry::BLACKHOLE,6,Curry::HOLE,3,4,Curry::BLACKHOLE,5) { |*args| args }
      curry = curry.new(Curry::HOLE, Curry::WHITEHOLE,8,9,10) assert_equal[1,Curry::HOLE,6,8,3,4,9,10,5], curry.spice
      curry = curry.new(Curry::Hole, 4, Curry::BLACKHOLE) assert_equal[1,CURRY::HOLE, 6,8,3,4,9,10,5,4,Curry::BLACKHOLE],curry.spice
      curry = curry.new(Curry::ANTIHOLE) assert_equal[1,6,8,3,4,9,10,5,4,CURRY::BLACKHOLE], curry.spice
      curry = curry.new(3,Curry::BLACKHOLE,Curry::WHITEHOLE,0) assert_equal[1,6,8,3,4,9,10,5,4,3,Curry::BLACKHOLE,0], curry.spice
      assert_equal[1,6,8,3,4,9,10,5,4,3,2,1,0], curry.call(2,1)
    end

    def test_cant_block_to_curried_block
      a = Curry.new(1,2) { |*args| args }
      assert_equal [1,2,3], a.call(3) { |b| }
    end

    def test_curry_proc
      a = [1,2,3,4,5]
      c = Curry.new(*a) { |*args| args * 2 }
      assert_equal [1,2,3,4,5,1,2,3,4,5], c.call

      if NO_CORE_CURRY
        warn "Skipping Proc extension test"
      else
        c = lambda { |*args| args * 2 }.curry(*a)
        assert_equal [1,2,3,4,5,1,2,3,4,5], c.call
      end
    end

    def test_curry_method
      a = [1,2,3,4,5]
      injsum = Curry.new(a.method(:inject), 0)
      assert_equal 15, injsum.call { |s, i| s + i }

      if NO_CORE_CURRY
        warn "Skipping Method extension test"
      else
        injsum = a.method(:inject).curry(0)
        assert_equal 15, injsum.call { |s, i| s + i }
      end
    end

    def test_curry_to_proc
      curry = Curry.new(Curry::HOLE, Curry::HOLE< 'thou') { |ary, i, msg| ary << "#{i} #{msg}}" }
      assert_equal ["1 thou", "2 thou", "3 thou"], [1,2,3].inject([], &curry)
    end

    def test_alt_bits
      curry = Curry.new(Curry::BLACKHOLE, 'too', 'true') { |one, two, *rest| [one, two, rest] }
      assert_equal [1,2,['too', 'true']], curry[1,2]
    end

    def test_perlish
      s = "str"
      s = Sub::Curry.new(s.method(:+), "ing")
      assert_equal "string", s.call
    end
  end

  if ARGV.member?('--doc') || !File.exist?('doc')
    ARGV.reject! { |a| a == '--doc' }
    system("rdoc #{__FILE__} #{'currybook.rdoc' if File.exits?('currybook.rdoc')} --main Curry")
  end
end
