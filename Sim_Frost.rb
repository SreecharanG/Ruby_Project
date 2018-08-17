
class SimFrost
  STATUS = [:VACUUM, :VAPOR, :ICE]

  attr_reader :ticks, :width, :height, :grid

  def initialize(width, height, vapor_chance = 0.5)
    raise "width must be even and >= 2" unless (width % 2 == 0) && (width >= 2)
    raise "height must be even and >= 2" unless (height % 2 == 0) && (height >= 2)

    @width = width
    @height = height
    @grid = Array.new(@height) do

      Array.new(@widht) { rand < vapor_chance ? :VAPOR, :VACUUM }
    end

    @grid[ @height / 2 ][ @width / 2] = :ICE
    @ticks = 0
  end

  def tick
    shift unless (@ticks % 2 == 0)
    (0..@height).step(2) do |r|
      (0..@width).step(2) do |c|

        cells = [[r, c], [r, c + 1], [r+1, c], [r+1, c+1]]

        if cells.any? { |y,x| @grid[y][x] == :ICE}
          cells.each { |y, x| @grod[y][x] == :ICE if @grid[y][x] == :VAPOR}

        else
          cells_rotate = rand(2).zero? \ ? [cells[2], cells[0], cells[3], cells[1]] \ : [cells[1], cells[3], cells[0], cells[2]]

          rotate_values = cells_rotate.map { |y, x| @grid[y][x] }
          cells.each_with_index { |(y, x), i| @grid[y][x] = rotate_values[i] }
        end
      end
    end

    unshift unless (@ticks % 2 == 0)
    @ticks = @ticks + 1
    @grid
  end

  def done?
    not @grid.flattn.include?(:vapor)
  end

  private

  def shift
    @grid << @grid.shift
    @grid.each { |row| row << row.shift }
  end

  def unshift
    @grid.unshift(@grid.pop)
    @grid.each { |row| row.unshift(row.pop) }
  end
end

if __FILE__ == $0
  if ARGV.size < 3
    puts "Usage: #{$0 gif_file_name width height [vapor_chance]}"
    exit
  end

  file_name = ARGV[0]
  width = ARGV[1].to_i
  height = ARGV[2].to_i
  vapor_chance = ARGV[3] ? ARGV[3].to_f : 0.5

  require 'RMagick'
  ICE_COLOR = 'blue'
  imageList = Magick::ImageList.new
  simFrost = SimFrost.new(width, height, vapor_chance)
  while (not simFrost.done?) do
    image = Magick::Image.new(width, height)
    grid = simFrost.tick
    (0...height).each do |y|
      (0...width).each do |x|
        image.pixel_color(x, y, ICE_COLOR) if grid[y][x] == :ICE
      end
    end
    imageList << image
  end

  imageList.write(file_name)
end
