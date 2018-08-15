
# The fractal objects are a sequence of steps to draw an image
# In logo the drawing would be extremely easy.

class Fractal
  attr_reader :path

  # +level+ may be 0 or greater, and should be something like an integer.

  # +seq+ is an array with a sequence of steps (:fw, :right, or :left) which
  # will replace each :fw (means: forward) part of the path.


  # A nice default is provided.

  def initialize level =  1, seq = nil

    super()
    @path = [:fw]
    seq = [:fw, :left, :fw, :right, :fw, :right, :fw, :left, :fw]
    level.times do
      @path.map! { |e1| e1 == :fw? seq.dup : el}.flatten!
    end
  end
end

  # AsciiArtCanvas draws a given Fractal.path on an array of strings.

class AsciiArtCanvas

  def initialize path, initial_dir = :e

    @path = path
    @dir = initial_dir
    @canvas = Hash.new { |h,k| h[k] = Hash.new { |h2, k2| h2[k2] = ' '}}

    @x = @y = @min_x = @min_y = @max_x= @max_y= 0
  end

  def paint
    @path.each { |step| step== :fw ? draw : turn(step) }
    (@min_y..@max_y).inject([]) do |arr, y|
      arr << (@min_x..@max_x).inject('') do |row, x|
        row + @canvas[x][y]
      end
    end
  end

  private
  def draw
    case @dir
    when :n; @y -= 1
    when :s; @y += 1
    when :e; @x += 1
    when :w; @x -= 1
    end

    @canvas[@x][@y] = case @canvas[@x][@y]
    when '+'; '+'
    when '-'; [:n, :s].include?( @dir ) ? '+' : '-'
    when '|'; [:w, :e].include?( @dir ) ? '+' : '|'
    else [:n, :s].include?( @dir ) ? '|' : '-'
    end

    case @dir
    when :n; @y -= 1; @min_y = @y if @y < @min_y
    when :s; @y += 1; @max_y = @y if @y > @max_y
    when :e; @x += 1; @max_x = @x if @x > max_x
    when :w; @x -= 1; @min_x = @x if @x < min_x
    end

    end

  TURNS = {
    :n => { :left => :w, :right => :e },
    :w => { :left => :s, :right => :n },
    :s => { :left => :e, :right => :w },
    :e => { :left => :n, :right => :s },
  }

  def turn dir
    @dir = TURNS[@dir][dir]
  end

end

if __FILE__ == $0
  level = ARGV[0] ? ARGV[0].to_i.abs : 3

  t = Fractal.new level
  puts ( *AsciiArtCanvas.new(t.path, :e).paint)
end
