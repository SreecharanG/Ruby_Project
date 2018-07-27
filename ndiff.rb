require 'optparse'
require 'ostruct'

class DataFile

  @@options = OpenStruct.new({:digits => 0, :tol => 0.0, :quiet => false, :stats => false})

  def self.options
    return @@options
  end

  @@opt_parser = OptionParser.new (|opts|
    opts.banner = "Usage: ndiff [options] file1 file2"
    opts.separator ""
    opts.separator "Numerically compare files line by line, numerical field by numerical filed.")
    opts.separator ""
    opts.on("-d", "--digits INT", Integer, "Maximum number of significant digits that
          should match. (default: o)") {|d| DataFile.options.digits = d }

    opts.on("-h", "--help", "Output this help."){
        puts opts
        exit
    }

    opts.on("-q", "--quiet", "No output, just exit code."){
      DataFile.options.quiet = true
    }

    opts.on("-s", "--statistics", "Provide comparision statistics only.") {
        DataFile.options.stats = true
    }

    opts.on("-t", "--tolerance DBL", Float, "Tolearate <= DBL distance between numbers, (default: 0.0)") {|dbl|
        DataFile.options.tol = dbl
    }
  }

  def self.parse_options(args)
    @@opt_parser.parser!(args)
  end

  def self.help
    puts @@opt_parser
  end

  attr_reader :filename, :lines, :data
  def initialize(filename)
    @filename = filename
    @line = Array.new
    @data = Array.new

    parse_file(filename)
  end

  def parse_file(file)
    raise "'#{filename}' does not exist" unless FileTest.exists?(filename)
    raise "'#{filename}' isn't readable" unless FileTest.readable?(filename)

    File.read(filename).each_line{|l|
      l.chomp!
      @lines << l
      @data << parse_line(l.strip)
    }
  end

  def parse_line(line)
    if line =~ /^-?\d+$/

      # This is a line with a single Integer on it ex. 3
      return line.to_i

    elsif line =~ /^-?\d+[eE][-+]?\d+$/
      # This is a line with a single integer on it with exponent
      # ex. 3e+01
      num, exp = line.split(/[eE]/)
      return (num.to_i)*(10**exp.to_i)

    elsif line =~ /^-?\d+\.\d+$/
      # This is a line with a single float on it, 3x. 0.00323
      return line.to_f

    elsif line =~ /^-?\d+\.\d+[eE][-+]?\d+$/
      # This  is a line with a single float on it with exponent
      num, exp = line.split(/[eE]/)
      return (num.to_f)*(10**exp.to_i)

    else
      # This must have several number of it # ex. Cy=0.11278889E-01 Cx=-1.343e+02

      numbers = line.split(/s+/).collect {|entry|
        name, number = entry.split(/=/)
        [name, parse_line(number)]
      }
    end
  end

  class CompareResults
    attr_reader :diffs
    def initialize()
      @diffs = Array.new
      @count = 0
      @ranges = Array.new
    end

    def diff(line, x1, x2)
      @diffs << [line, x1, x2]
    end

    def stats
      max_range = @ranges.max
      avg_dist = @ranges.inject(0) {|i, s| s + i} / @ranges.size
      mean_dist = @ranges.sort[(@ranges.size/2).to_i - 1]

      buf = ''
      buf << "Numbers compared: #{@count}\n"
      buf << "Distance range: 0.0..#{max_range}\n"
      buf << "Average distance: #{avg_dist} [guess] \n"
      buf << "Mean distance: #{mean_dist} [guess]"
      return buf
    end

    def to_s
      buf = ''
      start_line = nil
      last_line = nil
      buf1 = ''
      buf2 = ''
      @diffs.each{|line, x1, x2|
        if start_line && (last_line + 1 != line )
          if start_line != last_line
            buf << "#{start_line}, #{last_line}c#{start_line}, #{last_line}"
          else
            buf << "#{start_line}c#{start_line}"
          end
          buf << "\n" << buf1 << "---\n" << buf2
          start_line = nil
        end
        start_line = line unless start_line
        last_line = line

        buf1 << "< " << x1 << "\n"
        buf2 << "> " << x2 << "\n"
      }
      if start_line
        if start_line != last_line
          buf << "#{start_line}, #{last_line}c#{start_line}, #{last_line}"
        else
          buf << "#{start_line}c#{start_line}"
        end
        buf << "\n" << buf1 << "---\n" << buf2
        start_line = nil
      end

      return buf
    end

    def compare(line1, line2)

      # Check if line1 or line 2 is an array and both are the same size

      if Array == line1 && Array == line2 && line1.size == line2.size

        # each portion of the array must match

        line1.each_with_index{ |n, i|
          ret = compare(n, line2[i])
          return ret if ret
        }
        return false

      elsif Array == line1 || Array == line2
        # automatic differences; compound line vs non-compound line orcompound line
        # size mismatch TBI show should this be counted in the stats?
        return true

      else
        @count += 1

        # no differece if they match exactly
        return false if line1 == line2

        # check against digits and tol

        digit_check = false
        if Datafile.options.digits > 0
          sd1 = significant_digits(line1, DataFile.options.digits)
          sd2 = significant_digits(line2, DataFile.options.digits)
          digit_check = (sd1 == sd2)
        end

        return false if digit_check

        tol_check = false

        if DataFile.options.tol > 0
          tol_check = (((line1 / DataFile.options.tol).to_i - (line2
            / DataFile.options.tol).to_i).abs <= 1)
        end

        return false if tol_check
      end
    end

    def significant_digits(n, x = 0)
      raise "cannot generate unlimited significant digits: x must be > 0" unless x > 0

      while n.abs >= 1
        n = n / 10.0
      end

      while n.abs < 0.1
        n = n * 10.0
      end

      # now n is < 1 && >= 0.1

      i = 0
      while x > 0
        n = n*10
        j = n.to_i
        n = n%j
        i = (i==0 ? j:i*10+j)
        x = x-1
      end

      # rounding is implemented because it would be required for
      # 2.0 to match 1.99 with digits == 1
      # (as given in the description of how this should work)

      i = i+1 if (n*10).to_i >= 5

      return i
    end
  end

  def compare(other)
    results = CompareResults.new
    @data.each_with_index{|line, index|
      ret = results.compare(line, other.data[index])
      results.diff(index+1, @lines[index], other.lines[index]) if ret
    }
    return results
  end
end


DataFile.parse_option(ARGV)
unless ARGV.size == 2
  DataFile.help
  exit -1
end

results = DataFile.new(ARGV[0]).compare(dataFile.new(ARGV[1]))

if DataFile.options.stats
  puts results.stats
elsif !DataFile.options.quiet
  puts results.to_s unless results.diffs.empty?
end

exit (results.diffs.empty? ? 0:1 )
