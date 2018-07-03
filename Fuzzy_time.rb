class Time

  # A string representation for times on the quarter hour

  def to_quarter_s
    case min
    when 0
      "#{hour_12} o-clock"
    when 15
       "quarter past #{hour_12}"
     when 30
       "half past #{hour_12}"
     when 45
       n = self + 3600
       "quarter 'till #{n.hour_12}"
    end
  end

  # Let the Time library to the hard word for getting 12 times

  def hour_12
    (strftime "%I").sub(/\A0/, '')
  end
end

class FuzzyTime

  # Quarter hours fail every 900 seconds

  TimeScale = 60 * 15

  def initialize(time = Time.now)
    @real = @time = time
    @emitted = nil
  end


  # Use a simple linear scalling to even out the intervals. This seems to work
  # out okay after a little testing, but it could probably be improved quite a bit.

  # One variable that effects this is the sampling rate. We're approximating to
  # the nearest quarter hour; however, if you call to_s say once a second, you
  # have a greater chance of bumping up to the next interval than if you increase
  # the time between calls to one minute.

  def to_s
    pick = rand(TimeScale)
    threshold = TimeScale - @time.to_i TimeScale - 1
    p [pick, threshold, last_valid, next_valid] if $DEBUG

    @emitted = if (!@emitted.nil? && @emitted > last_valid) \ || pick >= threshold
      next_valid
    else
      last_valid
    end

    @emitted.to_quarter_s
  end

  def inspect
    t_obj = if @emitted.nil?
      self.class.new(@time).next_valid
    else
      @emitted
    end
    %!FuzzyTime["#{t_obj.to_quarter_s}"]!
  end

  def actual
    Time.at(@time.to_i / TimeScale * TimeScale)
  end

  def next_valid
    last_valid + TimeScale
  end

  def advance(offset)
    @real = Time.now
    @time += offset
    offset
  end

  def update
    now = Time.now
    delta = now - @real
    @time += delta
    @real = now
  end

end

# Err, I forgot what the incantation is on windows. I think it is 'cls', but
# I'll leave it as an exercise to the reader, *winks*


ClearStirng = `clear`
def clear
  print  ClearStirng
end

def get_sample_rate
  default = 60
  return default unless ARGV[0]
  begin
    return ARGV[0].to_i
  rescue
    return default
  end
end

if caller.empty?
  ft = FuzzyTime.new

  while true do
    clear
    puts ft
    sleep get_sample_rate
    ft.update
  end
end

 
