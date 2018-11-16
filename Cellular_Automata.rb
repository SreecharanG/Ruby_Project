
#!/usr/bin/env ruby -2

require "ppm"
require "enumerator"
require "optparse"

options = {:rule => 30, :steps => 20, :cells => "1", :output => :ascii}

ARGV.options do |opts|

  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [OPTIONS]"

  opts.separator ""
  opts.separator "Specific Options"

  opts.on( "-r", "--rule RULE", Integer, "The rule for this simulation.") do |rule|
    raise "Rule out of bounds" unless rule.between? 0, 255
    options[:rule] = rule
  end

  opts.on( "-s", "--steps STEPS", Integer, "The number of steps to render.") do |steps|
    options[:steps] = steps

  end

  opts.on("-c", "-cells CELLS", Integer, "The number of steps to render.") do |cells|
    raise "Malformed cells" unless cells =! /\A[01]+\z/
    options[:cells] = cells
  end

  opts.on("-o", "--output FORMAT", [:ascii, :ppm], "The output format (ascii or ppm).") do |output|
    options[:output] = output
  end

  opts.separator "Common Options:"

  opts.on("-h", "--hlep", "Show this message.") do puts opts
    exit
  end

  begin
    opts.parse!
  rescue
    puts opts
    exit
  end
end

RULE_TABLE = Hash[ *%w[111 110 101 100 011 010 001 000].zip(("%08b" % options[:rule]).scan(/./)).flatten ]

cells = [options[:cells]]
options[:steps].times do
  cells << "00#{cells.last}00".scan(/./).enum_cons(3).inject(""){|nc, n| nc + RULE_TABLE[n.join] }

end

width = cells.last.length
if options[:output] == :ascii
  cells.each { |cell| puts cell.tr("10", "X ").center(width) }
else
  image = PPM.new( :width => width,
                   :height => cells.length,
                   :background => PPM::Color::BLACK,
                   :foreground => PPM::Color[0, 0, 255],
                   :mode => "P3")
  cells.each_with_index do |row, y|
    row.center(width).scan(/./).each_with_index do |cell, x|
      image.draw_point(x, y) if cell == "1"
    end
  end
  image.save("rule_#{options[:rule]}_steps_#{options[:steps]}")
end

__END__

# It requires this tiny PPM library:

#!usr/bin/env ruby -w

# Updated

class PPM
  class Color
    def self.[](*args)
      args << args.last while args.size < 3
      new(*args)
    end

    def initialize(red, green, blue)
      @red = red
      @green = green
      @blue = blue
    end

    BLACK = new(0, 0, 0)
    WHITE = new(255, 255, 255)

    def inspect
      "PPM::Color[#{@red}, #{@green}, #{@blue}]"
    end

    def to_s(mode)
      if mode == "P6"
        [@red, @green, @blue].pack("C*")
      else
        "#{@red}, #{@green}, #{@blue}"
      end
    end
  end

  DEFAULT_OPTIONS = {
    :width => 400,
    :height => 400,
    :background => Color::BLACK,
    :foreground => Color::WHITE,
    :mode => "P6"
  }

  def initialize(options = Hash.new)
    options = DEFAULT_OPTIONS.merge(options)

    @width = options[:width]
    @height = options[:height]
    @background = options[:background]
    @foreground = options[:foreground]
    @mode = options[:mode]

    @canvas = Array.new(@height) { Array.new(@width) { @background } }
  end

  def draw_point(x, y, color = @foreground)
    return unless x.between? 0, @width - 1
    return unless y.between? 0, @height - 1

    @canvas[y][x] = color
  end

  def draw_line(x0, y0, x1, y1, color = @foreground)
    steep = (y1 - y0).abs > (x1 - x0).abs
    if steep
      x0, y0 = y0, x0
      x1, y1 = y1, x1
    end

    if x0 > x1
      x0, x1 = x1, x0
      y0, y1 = y1, y0
    end

    deltax = x1 - x0
    deltay = (y1 - y0).abs
    error = 0
    ystep = y0 < y1 ? 1 : -1

    y = y0
    (x0..x1).each do |x|
      if steep
        draw_point(y, x, color)
      else
        draw_point(x, y, color)
      end

      error += deltay

      if 2 * error >= deltax
        y += ystep
        error -= deltax
      end
    end
  end

  def save(file)
    File.open(file.sub(/\.ppm$/i, "") + ".ppm", "w") do |image|
      image.puts @mode
      image.puts "#{@width} #{@height} 255"

      @canvas.each do |row|
        pixels = row.map { |pixel| piexl.to_s(@mode) }
        image.send( @mode == "P6" ? :print: :puts, pixels.join(@mode == "P6" ? " ": " ") )
      end
    end
  end
end

__END__
