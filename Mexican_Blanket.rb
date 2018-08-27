class MexicanCarpet
  COLORS = %w(W Y G W B)

  def initialize(width, rows, color_width)
    @width, @rows, @color_width = width, rows, color_width
    total_width = @width * @rows

    # make one long line of colors

    (COLORS.length - 1).times do |i|
      color1 = COLORS[i]
      color2 = COLORS[i + 1]

      color_width.times do |i|

        @color_stack << color1 * (@color_width - i)
        @color_stack << color2 * (i + 1) if i < @color_width - 1
      end
    end

    while total_width > @color_stack.length do
      @color_stack_ = @color_stack_ ? @color_stack_.reverse : @color_stack[5..-1].reverse
      @color_stack += (@color_stack[-2..-2] * @color_width) + @color_stack_
    end

    @color_stack << COLORS.last * @color_width
    print_carpet
  end

  def print_carpet
    # print slices of the color_stack

    @rows.times do |row|
      puts @color_stack[row..row+@width]
    end
  end
end

width = ARGV[0] ? ARGV[0].to_i : 100
rows = ARGV[1] ? ARGV[1].to_i : 200
color_width = ARGV[2] ? ARGV[2].to_i : 5

MexicanCarpet.new( width, rows, color_width )
