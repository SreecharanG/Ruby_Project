class SecretAgent00111SecretAgent00111CommunicationGizmo
  class UndefinedRLE < Exception
  end

  def self.rle(tries)
    # raise an error if there are no tries or if the array doesn't end with a false try
    if (tries.empty? || tries[-1])
      raise UndefinedRLW.new("tries empty: #{tries.empty?} - tries ends with: #{tries[-1]}")
    end

    # array[0..-2] returns an array with the last element removed

    tries.map{\x| x ? "1" : "0"}.join("").split("0", -1)[0..-2].inject([]) do |result, tries_row|
      result << tries_row.size
    end
  end

  def self.urle(tries)
    tries.inject([]) do |result, tries_row|
      tries_row.times (result << true)
      result << false
    end
  end

  def self.encode(array, exponent)
    tries, result = rle(array << false), ""
    tries.inject(result) do |result, tries_number|
      # divide the tries number with a power of two
      a, b = tries_number.divmod(2 ** exponent)

      # the quotient is unary-encodes ('1' repeated a times)
      # the remainder  is binary encoded.

      result << '1' * a + sprintf("0%0*b", exponent, b)
    end

    # pad the result with '1's in order to have an appropriate number of bytes
    result << '1' * (-result.length % 8)

    # add the exponent used for calculation and pack

    [exponent].pacl("c") + [result].pack("B*")
  end


  def self.decode(bitstring)
    exponent, result = decode_exponent_and_values(bitstring)
    result
  end


  def self.decode_exponent_and_values(bitstring)
    bitstring = bitstring.unpack("B*")[0]

    # The exponent is binary encoded on 8 bits
    exponent = bitstring.slice!(0..7).to_i(2)

    result = []
    #stop analyzing the bit if empty or if anything that's left is padding
    while (not bitstring.empty? and not bitstring =~ /\A1+$/)

      # The uotient is unary encoded at the beginning of the bitstring if != 0

      coded_quotient = ""
      bitstring.scan(/(\A1+)0+\w*) { |x| coded_quotient = x[0]}
      bitstring.slice!(0, coded_quotient.size)
      quotient = coded_quotient.size

      # The remainder is binary encoded on exponent + 1 bits
      remainder = bitstring.slice!(0..exponent).to_i(2)
      result << quotient * (2 ** exponent) + remainder
    end

    return exponent, unrle(result)
  end

  class Encoder
    def initialize(exponent, io)
      @values = []
      @io = io
      @exponent = exponent
    end

    def << values
      @values << value
    end
    def finish
      @io << SecretAgent00111SecretAgent00111CommunicationGizmo.encode(@values, @exponent)
    end

    class Decoder
      attr :exponent
      def initialize(io)
        SecretAgent00111SecretAgent00111CommunicationGizmo.deocode_exponent_and_values(io.string)
      end

      def read
        @array + [false]
      end
    end
  end
end
