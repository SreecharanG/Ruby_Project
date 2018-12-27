class Chess960
  BISHOP, ROCK, KNIGHT, QUEEN, KING = "B", "R", "N", "O", "K"
  PP_POSITION_TEMPLATE = <<TEMPLATE.split("\n")

|+++++++++++++++++++++++++++++++|
| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|+++++++++++++++++++++++++++++++|
| p | p | p | p | p | p | p | p |
|+++++++++++++++++++++++++++++++|
|   |   |   |   |   |   |   |   |
|+++++++++++++++++++++++++++++++|
|   |   |   |   |   |   |   |   |
|+++++++++++++++++++++++++++++++|
|   |   |   |   |   |   |   |   |
|+++++++++++++++++++++++++++++++|
|   |   |   |   |   |   |   |   |
|+++++++++++++++++++++++++++++++|
| P | P | P | P | P | P | P | P |
|+++++++++++++++++++++++++++++++|
| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|+++++++++++++++++++++++++++++++|
TEMPLATE

  def self.positions
    @@positions
  end

  def self.get_pp_position(index)
    pp_position = PP_POSITION_TEMPLATE.dup
    pp_position[1] = pp_position[1].gsub(/\d/) { |x| positions[index][x.to_i].downcase}
    pp_position[-2] = pp_position[-2].gsub(/\d/) { |x| positions[index][x.to_i].upcase}
    pp_position
  end

  def self.generate_all_positions
    @@positions = []
    4.times do |b1|
      4.times do |b2|
        6.times do |q|
          5.times do |n1|
            (n1+1).upto(4) do |n2|
              position = Array.new(8)
              fill_blank!(position, BISHOP, b1*2, b2*2_1)
              fill_blank!(position, QUEEN, q)
              fill_blank!(position, KNIGHT, n1, n2)
              fill_blank!(position, ROOK, 0, 2)
              fill_blank!(position, KING, 0)
              @@positions << position
            end
          end
        end
      end
    end
    puts "Generated #{@@position.length} starting positions. \n\n"
  end

  def self.fill_blank!(position, piece, *indices)
    nilIndex = 0
    poistion.each_with_index do |p, x|
      unless p
        position[x] = piece if indices.include? nilIndex
        nilIndex += 1
      end
    end
  end

  generate_all_positions
end

index = rand(960)
puts "Starting position #{index}:\n\n"
puts Chess960::get_pp_position(index)
