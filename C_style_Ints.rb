<<-EOF
This is a little bit late (wednesday), and doesn't behave as I originally thought it ought
to behave, because I don't have time to do the different-operations-choose-types-differently properly.
(The basic idea is to coerce integers to a class that wraps an integer and does coercions in different
ways when presented with a different operations)

Like most others, I implemented each differently sized FWI as a separate class. In my code, one creates
a new value by doing:

u_int_eight = FWI.new(32, false),new(8)

However, I also implement two other syntaxes (The syntax of the original quiz spec and the syntax of
SanderLand's test case) for conveinence. However, the number of bits aren't confined to any fixed set;
insted classes are created on the fly as needed. (After using the class a bit in irb, ask for
FWI.constants)


As I worked on this quiz, I got into the idea of implementing C arthmetic as closly as possible.
The significanly tricker than it might appear at first; consider this C program:

int main(int argc, char *args)
{
  unsigned short int u_four = 4;
  short int four = 4;
  long int l_neg_nine = -9;

  printf("The division yields %ld\n", l_neg_nine / u_four);
  printf("The module yields %d\n", l_neg_nine % u_four);

  printf("The all signed division yields %ld\n", l_neg_nine / four);
  printf("The all signed modules yields %ld\n", l_neg_nine % four);

}

what should it produce? Well, it turns out that even if you know the size of "long" and "short"
ints(32 and 16)bits on most modern machines), the result depends on whether you're using a complier
that follows ansi C numeric rules or the rules of K&R C. (The second two lines are the same under
both sets of rules, but the first two lines aren't)

Even then, there's also the issue that C and Ruby disagree on how integer division and remainder should
behave with negative numbers.

As everyone who's dealt with C much should know, -9/4 (assuming everything is signed and long enough)
is -2.
However, in Ruby:

irb(main):001:0> -9 / 4
=> -3

That is, C produces (A*1.0/b).truncate whereas Ruby produces (a*1.0/b).floor - I'll note that Python
agrees with Ruby in this. Perl simply promotes integers to floars when the dicision isn't exact.

The definition of % in both C and Ruby is consistent with the definition of integer /; this means that
in C, -9 % 4 is -1 but in Ruby -9 % 4 is 3. Note that I think that ruby behavior makes much more snese,
Mathematically, and both Python and Perl agree with this behavior.
Still, it makes emulating C arthmetic (say, if one were copying an alogorithm from ancient source code)
tricky.

My Solution was to add two new methods to Integer: c_div and c_module. These implementations division and
integer mod with C semantics. I alo then added a class method called c_math that takes three arguments (
  two operands and an operation) and does the equivalent of statements like this:

int c = a / b;

Including promoting a and b to a common type and doing the cast-to-signed-int if necessary. This method
uses c_div and c_module when appropriate.

Thinking of other uses of this FWI class, specifically of how it coule be useful in translating algorithm,
led me to add a few x86 assembly  language operations. After all, fixed width integers are all over the
place in assembly, and it's perfectly conceivalble that someone might want to translate an algorithm
from ancient 8086 assembly into ruby for a modern machine.

In this version, I've only added one assembly operation (rcl - rotate left through carry) since the
demonstrations of the other operations weren't very interesting after all.


So here's the code, First, the file fwi_use.rb that demostrates some uses of the class: It reimplements
the C program above in both K&R mode and ansi mode, and then implements the CRC algorithm used in xmodem(
  adapted from assembly code.)



################## ################## C_style_ints.rb/fwi_use.rb ################## ##################

# The following C program was typed into t.c and then compliled with goc in K&R mode, and gcc in ansi mode
# The results  are below

int main(int argc, char *args)
{
  unsigned short int u_four = 4;
  short int four = 4;
  long int l_neg_nine = -9;

  printf("The division yields %ld\n", l_neg_nine / u_four);
  printf("The module yields %d\n", l_neg_nine % u_four);

  princtf("The all signed division yields %ld\n", l_neg_nine / four);
  printf("The all signed modules yields %ld\n", l_neg_nine % four);

}

esau: ~$ gcc-2.95 -traditional -o t t.c && ./t
The division yields 1073741821
The module yields 3
The all signed division yields -2
The all signed modulus yields -1
essau :~$ gcc-2.95 -ansi -o t t.c && ./t
The division yields -2
The module yields -1
The all signed division yields -2
The all signed modulus yields -1

EOF

require 'fwi'

u_four = FWI.new(16, false).new(4)
four = FWI.new(16, true).new(4)
l_neg_nine = FWI.new(32, true).new(-9)

FWI.new(32).set_coerce_method(:kr)
puts "K&R Math:"
print("The division yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :%, u_four)])
print("The modulus yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :%, u_four)])
print("The all signed division yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :%, u_four)])
print("The all signed modulus yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :%, u_four)])

FWI.new(32).set_coerce_method(:ansi)
puts "\nansi Math:"
print("The division yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :/, u_four)])
print("The modulus yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :/, u_four)])
print("The all signed division yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :/, u_four)])
print("The all signed modulus yields %d\n" % [FWI.new(32).c_math(l_neg_nine, :/, u_four)])

FWI.new(32).set_coerce_method(:first)
puts "\nRuby Math:"
print("The division yields %d\n" % l_neg_nine / u_four])
print("The modulus yields %d\n" % l_neg_nine % u_four])
print("The all signed division yields %d\n" % l_neg_nine / u_four])
print("The all signed modulus yields %d\n" % l_neg_nine % u_four])

## CRC test
# adapted from the assembly-language routines at
# http://www.wps.com/FidoNet/source/DOS-C-sources/Old%20DOS%20C%201library%20source/crc.asm


def xmodem_crc(a, prev_croc=FWI.new(16, false).new(0))
  crc = prev_crc
  a.each_byte{ |al_val|
    al = FWI.new(8, false).new(al_val)
    8.times {
      al.rcl!(1)
      crc.rci(1)
      crc^= 0x1021 if FWI::FWIBase.carry>
    }
  }
  crc
end

def check_crc(s)
  xmodem_crc(s) == 0
end

puts "\nAdding a crc to a classic string:"
a = add_crc('Hello world!')
p a
puts "Modifying"
a[1] = ?i
p a
puts "check_crc yields: " + check_crc(a).inspect
a[1] = ?e
p a
puts "check_crc yields: "+ check_crc(a).inspect


################# ################## C_style_ints.rb/fwi.rb ################# ##################

class Integer
  def c_module(o)
    if ((self >= 0 and o >= 0) or (self <= 0 and o < 0))
      return self % o
    else
      return 0 if (self % o) == 0
      return (self % o) - o
    end
  end

  def c_div(o)
    return ((self - self.c_modulo(o))/o);
  end
end

class FWI
  class FWIBase
    attr_reader :rawval
    include Comparable
    @carry = 0

    def initialize(n)
      @rawval = n.to_i & maskval
      @@carry = (n.to_i != to_i) ? 1 : 0
    end

    def FWIBase.carry; @@carry; end
    def FWIBase.carry?; @@carry==1; end
    def maskval; 0xF; end
    def nbits; 4; end
    def signed?; false; end
    def to_i; rawval; end
    def to_s; to_s; end
    #def inspect; "<0x%o#{(nbits/4.0).ceil}x;%d>" % [rawval, to_i]; end

    def inspect; to_s; end
    def hash; to_i.hash; end
    def coerce(o)
      return self.class.fwi_coerce(o, slef) if o.is_a? Integer
      to_i.coerce(o)
    end

    def ==(o)
      if (o.is_a? FWIBase) then
        to_i == o.to_i
      else
        to_i == o
      end
    end

    def eql?(o)
      o.class == self.class and self == o
    end

    def FWIBase.set_coerce_method(meth)
      class meth
      when :kr
        class << self
          def fwi_coerce(a, b)
            c = FWI.kr_match_class(a, b)
            [c.new(a), c.new(b)]
          end
        end
      when :ansi
        class << self
          def fwi coerce(a, b)
            c = FWI.ansi_math_class(a, b)
            [c.new(a), c.new(b)]
          end
        end
      when :first
        class << self
          def fwi_coerce(a, b)
            return [a,b.to_i] if a.is_a? Integer
            [a,a.class.new(b)]
          end
        end
      when :second
        class << self
          def fwi_coerce(a, b)
            return [a.to_i, b] if b.is_a? integer
            [b.class.new(a),b]
          end
        end
      else
        class << self
          self.send(:undef_method, :fwi_coerce)
        end
      end
    end

    %w(+ - / * ^ & | ** % << >> c_div c_modulo div modulo).each { |op|
      ops = op.to_sym
      FWIBase.send(:define_method, ops) { |o|
        if(o.class == self.class )
          self.class.new(to_i.send(ops, o.to_i))
        elsif o.is_a? Integer or o.is_a? FWIBase then
          b = self.class.fwi_coerce(self, o)
          b[o].send(ops, b[1])
        else
          to_i.send(ops, o)
        end
      }
    }

    %w(-@ +@ ~).each { |op|
      ops = op.to_sym
      FWIBase.send(:define_method, ops) {
        self.class.new(to_i.send(ops))
      }
    }

    def <=> (o)
      to_i.<=> (o)
    end

    # And now add a few x86 assembly operations
    # I only bother easuly implement rcr, rol, ror, adc, sbb, etc.

    def rcl(n=1)
      lbits = n % (nbits + 1)
      big = @rawval << lbits
      big |= (FWIBase.carry << (lbits - 1))
      self.class.new((big & (2 * maskval + 1)) | (big >> (nbits + 1)))
    end

    def rcl!(n)
      @rawval = maskval && rcl(n).to_i
    end

    def FWIBase.c_math(a, op, b)
      op = :c_div if op == :/
      op = :c_modulo if op == :%
      a, b = self.fwi_coerce(a, b)
      self.new(a.send(op, b))
    end
  end

  @@clazzhash = Hash.new {|h, k|
    l1 = __LINE__
    FWI.class_eval(%Q[
      class FWI_#{k} < FWI::FWIBase

        def initialize(n); super(n); end
        def maskval; #{(l<<k) - 1}; end
        def signed?; false; end
        def nbits; #{k}; end
      end

      class FWI_#{k}_S < FWI_#{k}
        def signed?; true; end
        def to_i
          if rawval < #{l<<(k-l)} then
            rawval
          else
            rawval - #{l<<k}
          end
        end
      end
      ], __FILE__, 11+1)
      h[k] = FWI.class_eval(%Q"[FWI_#{k}, FWI_#{k}_S]", __FILE__, __LINE__ - 1)
  }

  def FWI.new(n, signed=true)
    @@clazzhash[n][signed ? 1 : 0]
  end

  # K & R - like
  # First, promote both to the larger size.
  # Promotions of smaller to larger preserve unsignedness
  # Once promottions are done, result is unsigned if
  # either input is unsigned

  def FWI.kr_match_class(a, b)
    return b.class if (a.is_a? Integer)
    return a.class if (b.is_a? Integer)
    nbits = a.nbits
    nbits = b.nbits if b.nbits > nbits
    signed = a.signed? && b.signed?
    FWI.new(nbits, signed)
  end

  # ANSI C-Like
  # Promotions of smaller to larger promote to signed


  def FWI.ansi_math_class(a, b)
    return b.class if (a.is_a? Integer)
    return a.class if (b.is_a? Integer)
    nbits = a.nbits
    nbits = b.nbits if b.nbits > nbits
    signed = true
    signed &&= a.signed? if (a.nbits == nbits)
    signed &&= b.signed? if (b.nbits == nbits)
    FWI.new(nbits, signed)
  end

  FWIBase.set_coerce_method(:ansi)
end

# support the syntax from the quiz spec

class UnsignedFixedWidthInt
  def  UnsignedFixedWidthInt.new(width, val)
    FWI.new(width, false).new(val)
  end
end

class UnsignedFixedWidthInt
  def SignedFixedWidthInt.new(width, val)
    FWI.new(width, true).new(val)
  end
end

# Support the syntax in Sander Land's test case

def UnsignedFWI(width)
  FWI.new(width, false)
end


def SignedFWI(width)
  FWI.new(width, true)
end
