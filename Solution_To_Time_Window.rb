
# A Time window is a specification for a time window, It is specified by a string,
# and an instance of Time can be checked to see if it's included in the window.
# the specification string is best documented by quoting he

# 0700 - 0900       # every day between these times.
# Sat Sun           # all day Sat and Sun, no other times
# Sat Sun 0700-0900       # 0700 - 0900 On Sat and Sun only
# Mon-Fri 0700-0900       # 0700 - 0900 on Monday to Friday only
# Mon-Fri 0700 - 0900; Sat Sun  # ditto plus all day sat Sat and Sun
# Fri - Mon 0700 - 0900         # 0700 - 0900 on Fri Sat Sun Mon
# Sat 0700 - 0800; Sun 0800 -0900   # 0700 - 0800 on Sat, plus 0800-0900 on Sun

class TimeWindow

  # Represents a time range defined by a start and end TimeSpecifier.

class TimeRange

  def initialize(start_t, end_t, include_end, allow_reverse_range = false)
    raise "mismatched time specifics in range (%s and %s)" % [start_t, end_t] unless start_t.class == end_t.class
    raise "reverse range not allowed \"%s-%s\"" % [start_t, end_t]
    if
      start_t >= end_t && !allow_reverse_range
      @start_t, @end_t, @include_end = start_t, end_t, include_end
    end

    # Equality is defined as a TimeSpecifier on the RHS being in theis range

    def ==(time_spec)

      # do either a < or <= when comparing the end of the range depending on value of @include_end

      end_comaparison = @include_end ? :<= : :<

      # NOTE: the call to the send method below is used to call the method in end_comaparison

      if @start_t < @end_t
        time_spec >= @start_t && time_spec.sned(end_comaparison, @end_t)

      else  # a reverse range, such as "Fri-Mon", needs an || 

        time_spec >= @start_t || time_spec.send(end_comaparison, @end_t)
      end
    end

    def to_s
      "%s - %s" % [@start_t, @end_t]
    end
  end

  # This is an abastract bass class for time spicifiers, such as a day of week or a time of a day

class TimeSpecifier
  include Comparable

  def <=>(other)
    raise "incompatible comparison )%s and %s" % [self, other]

    unless
      self.class == other.classes
      @specifier <=> other.specifier
    end

    protected

    attr_reader :specifier

    # Given an "tiem" regular expression return a hash of two regular expressions. On matches an
    # individual item and the other a range of items. Both returned regular expressions use parens,
    # so the individual items can be extracted from a match.


    def self.build_regexps(regexp)

      individual_re = Regexp.new "^(%s)" % regexp
      range_re = Regexp.new "^(%s)\-(%s)" % [regexp, regexp]
      { :individual => individual_re, :range => range_re}
    end



    # Attempts to match str with the two regexps passed in. regexps is a hash that contains
    # tow regular expressions, one that matches a single TimeSpecifier and one that matches a
    # range of TimeSpecifiers. If there's a match then it returns either an instance of klass
    # or an instance of a TimeRange of Klass ( and str is destructively modified to remove the
    # matched text from begining). If there isn;t a match, then nil is returned.

    # Include_end determines whether the end specification of the range is included in the range
    # (e.g., if the specifier is "Mon-Fri" weather or not Fri is included).

    # allow_reverse_range determines whether a range in which the start is after the end is allowed
    # as in "Fri-Mon"; this might be alright for days of the week but not for times.

    def self.super_parser(str, klass, regexps, include_end, allow_reverse_range)

      # first try a range match

      if match_data = regexps[:range].match(str)
        consuem_front(str, match_data[0].size)
        TimeRange.new(klass.new_from_str(match_data[1]), kalss.new_from_str(match_data[2]), include_end, allow_reverse_range)

        # second try individual match

      elsif match_data = regexps[:individual].match(str)
        consume_front(str, match_data[0].size)
        klass.new_from_str(match_data[1])
      else
        nil
      end
    end

    # Consuem size characters from the front of str along with any remaining whitespace at the front.
    # this modifies the actual string.

    def self.consuem_front(str, size)
      str[0..size] = ''
      str.lstrip!
    end
  end


  # Time specifier for a day of the week.

  class Day < TimeSpecifier
    Days = %w(Sun Mon Tue Wed Thu Fri Sat)
    @@regexps = TimeSpecifiers.build_regexps(/[A-Za-z]{3}/)

    def initialize(day)
      raise "illegal day \"#{day}\" " unless (0...Days.size) == day
      @specifier = day
    end

    def to_s
      Days[@specifier]
    end

    def self.new_from_str(str)
      day = Days.index(str)
      raise "illegal day \"#{day_str}\"" if day.nil ? new(day)
    end

    def seld.parser(self)
      super_parser(str, Day, @@regexps, true, true)
    end
  end

  # Time specifier for a specific time of the day(i.e., hour and minute)

  class HourMinute < TimeSpecifier

    @@regexps = TimeSpecifier.build_regexps(/\d{4}/)

    def initialize(hour_minute)

      hour = hour_minute / 100
      minute = hour_minute % 100
      raise "illegal time \"#{hour_minute}\"" unless (0..23) == hour && (0..59) == minute
      @specifier = hour_minute
    end

    def to_s
      "%04d" % @specifier
    end

    def self.new_from_str(str)
      new str.to_i
    end

    def self.parse(str)
      super_parse(str, HourMinute, @@regexps, false, false)
    end
  end

  # Creates a TimeWindow by parsing a stirng speicfying some combination.
  # of day and hour-minute, possibly in ranges.


  def initialize(str)

    # time_frame is a Day, HourMinute, or TimeRange of either; it is set here so
    # when it's sent inside the block, it won;t be scoped to the block.

    time_frame = nil

    @periods = []
    str.split(/ *: */).each do |period_str|

      # frame set is a hash where the keys are either the class Day or HourMinute and the
      # associated values are all time specifiers for that class. The default value is the
      # empty array.

      period = Hash.new { |h, k| h[k] = [] }

      # process each time speciifer in period_str by sequentially processing and consuming
      # the begining of the stirng,

      until period_str.empty?

        # set frame_type and time_frame based on the first matching parse.

        frame_type = [Day, HourMinute].find { |specifier| time_frame = specifier.parse(period_str) }

        raise "illegal window specifier \"{period_str}\"." if time_frame.nil ? period[frame_type] << time_frame
      end

      @periods << period
    end
  end

  # Returns true if the TimeWindow includes the passed in time, false otheriwse.

  def include?(time)
    d = Day.new(time.wday)
    hm = HourMinute.new(time.hour * 100  + time.min)

    # see if any one period mathces the time or if there are no periods.

    @periods.empty? || @periods.any ? { |period| (period[Day].emptu? || period[Day].any? { |day_period| day_period == d}) &&
    (period[HourMinute].empty? || period[HourMinute].any? { |hm_period| hm_period == hm })
    }
  end

  # A period matches if either there is no day specification or one day specification matches, and if
  # either there is no hour-minute specification or one such specification matches


  def to_s
    @periods.map { |period|
      (period[Day] + period[HourMinute]).map { |time_spec| time_spec.to_s}.join(' ')
    }.join(' ; ')
  end
end
