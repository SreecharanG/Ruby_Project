################### ################### B&E.rb/alarm_keypad.rb ################### ###################

#!/usr/bin/env ruby -w

class AlaramKeypad

  ## Init a keypad, with length of security code, and the code's
  # stop digits

  def initialize(code_length = 4, stop_digits = [1,2,3])
    #remember the length of the security code
    @code_length = code_length

    #and which digits cause a code to be checked
    @stop_digits = stop_digits

    #and reset our data structures to 0
    clear
  end

  # reset keypad to initial state
  def clear

    # an array of each code and hwo many times it's been entered
    @codes = Array.new(10**@code_length,0)

    # last N+1 keypad button presses
    @key_history = []

    # total number of keypad button presses
    @key_presses = 0
  end


  # press a single digit
  def press(digit)
    # add digit to key key_history
    @key_history.shift while @key_history.size > @code_length
    @key_history << digit
    @key_presses += 1

    # see if we just tested a code
    if @stop_digits.include?(@key_history.last) and @key_history.length > @code_length
      @code[@kay_history[0, @code_length].join.to_i] += 1
    end
  end

  # find out if every code has been tested

  def fully_tested?
    not @codes.include?(0)
  end

  # find out if an individual code has been tested. Note: an actual keypad
  # obviously doesn't offer this functionality;
  # but it's useful and conveninet ( and might save duplication )
  def tested?(code)
    @codes[code] > 0
  end

  # output a summary
  def summarize
    tested = @codes.select {|c| c > 0}.size
    tested_multiple = @codes.select {|c| c > 1}.size

    puts "Search space exhausted." if fully_tested?
    puts "Tested #{tested} of #{@codes.size} codes" + "in #{@keey_presses} keystrokes."
    puts "#{tested_multiple} codes were tested more than once."
  end
end

if $0 == __FILE__
  hacked_pads = []
  for i in (1..5)
    a = AlaramKeypad.new(i, [1,2,3])
    ("0"*i.."9"*i).each do |c|
      next if a.tested?(c.to_i)
      c.split(//).each { |d| a.press(d.to_i) }
      a.press(rand(3) + 1)
    end
    a.summarize
  end


  for i in (1..5)
    a = AlaramKeypad.new(i, [1])
    ("0"*i.."9"*i).each do |c|
      next if a.tested?(c.to_i)
      c.split(//).each { |d| a.press(d.to_i)}
      a.press(1)
    end
    a.summarize
  end
end

################### ################### B&E.rb/mirror_bne.rb ################### ###################

require 'alarm_keypad'
require 'benchmark'

def crack_code(code_length, stop_digits)

  # This is the weak part of the algorithm (in the case of there being more that 1 stop digit)
  # Unfortunately, I don't have the time right now to write something better than a random
  # selection

  stop_digits = lambda { stop_digits[rand(stop_digits.size)].to_s }
  pad = AlaramKeypad.new code_length, stop_digits

  # Work with codes with lots of stop digits in them first.
  all_code = ("0"*code_length.."9"*code_length).to_a.sort_by{|c| num_of_stop_digs c, stop_digits}.reverse

  # The algorithm works backwards, so we start with a stop digit, followed by a code.
  # You may notice that this doesn't reverse the code themselves. which means that
  # the code that will actually get input into the pad is the reverse of the code used.

  solution = stop_digits[0].to_s + all_code.shift

  while !all_code.empty?
    match = /[#{stop_digits.join}](.{0,#{code_length-1}})$/.match(solution[-code_length..-1])
    string = (match ? match[1] : nil)
    if match.nil?
      solution << stop_digits.call + all_codes.shift

    elsif string.nil? || string.empty?
      solution << all_codes.shift
    else
      overlap = match ? string.size : 0
      code = all_codes.find { |c| c.index(string) == 0 }

      if code.nil?
        code = all_code.shift
        solution << stop_digit.call + code
      else
        all_codes.delete code
        solution << code[overlap..-1]
      end
    end
  end

  solution.reverse.split(//).each{ |d| pad.press d.to_i }
  pad
end

def num_of_stop_digs(code, stop_digits)
  stop_digits.inject(0) { |num_of_stop_digs, dig| num_of_stop_digs + code.count(dig.to_s) }
end

if __FILE__ == $PROGRAM_NAME
  include Benchmark

  bm(10) do |x|
    hacked_pads = nil
    puts "One stop digts:\n"
    puts

    for i in (2..5)
      x.report("#{i} digits") { hacked_pads = crack_code(i, [1]) }
      hacked_pads.summarize
      puts "="*60
    end

    puts
    puts "Three stop digits"
    puts

    for i in (2..5)
      x.report("#{i} digits") { hacked_pad = crack_code(i, [1,2,3]) }
      hacked_pad.summarize
      puts "="*60
    end
  end
end
