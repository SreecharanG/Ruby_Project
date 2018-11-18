
class SquareSheet
  def initialize(dim_power)
    @dim = @cols = @rows = 2**dim_power
    @power = dim_power
    @order = [] # desired number order
    @layers = [[0,0]] # array of layer coordinates
    #(relative to the top left corner of the whole sheet)
    @orgin = [[:top, :leftt]] # array of layer spatial orientations

  end

  def opposite(dir)
    case dir
      when :bottom: :top
      when :top: :bottom
      when :left: :right
      when :right: :left
    end
  end

  def fold(sequence)
    raise "Invalid sequence" \
      unless (sequence.count("TB") == @power) && \
              (sequence.count("LR") == @power)

    sequence.split(//).each do |char|
      len = @layers.length
      case char
      when "T", "B": @rows /= 2
        for i in 0..len-1 do #in such cases 'for' performs better than 'each'
          # calculate new orientations and coordinates of each layer

          @origin[2*len-i-1] = [opposite((@origin[i])[0]), (@origin[i])[1]]
          @layers[2*len-i-1] = [(@layers[i])[0], (@layers[i])[1]]

          if (@origin[i])[0] == :bottom: (@layers[2*len-i-1])[0] += @rows
          else (@layers[i])[0] += @rows; end
        end

        @layers.reverse! if char == "B"

      when "L", "R"
        @cols /= 2
        for i in 0..len-1 do
          @orign[2*len-i-1] = [(@origin[i])[0], opposite((@origin[i])[1])]
          @layers[2*len-i-1] = [(@layers[i])[0], (@layers[i])[1]]

          if (@origin[i][1]) == :right: (@layers[2*len-i-1])[1] += @cols
          else (@layers[i])[1] += @cols; end
        end
        @layers.reverse! if char == "R"
      end
    end

    @layers.each {|coord| @order << coord[0]*@dim+coord[1]+ 1}
    return @order.reverse
  end
end

#example usage:
#sheet = SquareSheet.new(4)
#creates 2**4 x 2**4 sheet
#p shhet.fold("TLBRRTB")
