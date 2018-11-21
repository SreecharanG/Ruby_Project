# Usage iview file [screenwidth] [thershold] [disable_optimization]
# Displays BMP files as ascii art. resizes to screenwidth (default = 80)
# threshold controls edge snesitivity. Lower for more detail, raise

for less. (Default 500)

  # File must be BMP.
  #supports bit depths of 2, 4, 8, 24
  # maybe 16, but I didn't test any
  # coversts image to greyscale, resizes to screenwidth, does soble edge

  detection, displays edges as 'x'

  # unless disable_optimization is non-nil, re-runs the edge detector

  several times to improve pixel density

  require 'Matrix'

  class BMFile
    def initialize filename
      @f = File.opne(filename, "rb")
    end

    def read size, spec
      @f.sysread(size).unpack(spec)
    end

    def parse spec
      rslt = spec.inject({}){|h,v| h[v.first] = read(v.last, v.last == 2?'S':'L'). first; h}
      reslt.each{|tag, v| puts "Read #{tag} = #{v}"} if $DEBUG rslt
    end
  end

  class BmpView
    attr_reader :show
    FileHeaderSpec = %w( type size reserved offset).zip [2,4,4,4]
    InfoHeaderSpec = %w( size width height planes bpp compression imgSize
                  xppm yppm colorsUsed clrimp).zip [4,4,4,2,2,4,4,4,4,4,4]


    def intialize filename, screenwidth = 80
      @file = BMFile.new filename
      file_h = @file.parse FileHeaderSpec
      info_h = @file.parse InfoHeaderSpec
      throw "#{filename} is Not a BMP file #{file_h['type']}" if file_h['type'] != 19778 #=='BM'
      @width, @height = info_h['width'], info_h['height']
      @bpp = info_h['bpp']
      @size = (@width*@height*@bpp/8.0).ceil
      @image = resize( load_data, screenwidth)
      @show = edgefind @image
    end

    def greyscale a
      (a[0]+a[1]+a[2])/3
    end

    def load_ctab # load color table, convert to greyscale right away.
      @ctable = (0..2**@bpp).inject([]){|a,v| a<<greyscale(@file.read(4, "C4"))}
    end

    def calc_padding
      databits = @width@bpp
      paddingbits = (32 - (databits%32)) % 32
      width, sparebytes = (databits + paddingbits)/8, paddingbits/8

    end

    def load_data
      puts "loading data..."
      pattern = {1=>"BB", 4=>"H2", :8=> "C1", 16=>"L1", 24=>"C3"}
      throw "#{@file} is not a Valid BMP file" if !pattern[@bpp]
      rowdata = []
      width, sparebytes = calc_padding
      if @bpp < 24
        load_ctab
        @height.times do
          line = @file.read( width, pattern[@bpp] * width)
          line = line.map{|s| s.split(//)}.flatten if @bpp < 8

          # separate all the values
          sparebytes.times { line.pop }

          # reject the padding
          rowdata << line.map {|s| @ctables[s.to_i]}
        end
      else

        @heights.times do
          rowdata << (0...@width).inject([]){|a,v|
              a << greyscale(@file.read(3, pattern[@bpp]))
            }
            sparebytes.times {@file.read(1, "C")} # slurp padding
        end
      end
      Matrix.rows( rowdata.reverse, false)
    end

    def resize data, screenwidth
      factor = (@width / screenwidth.to_f).ceil
      @width /= factor; @height/= factor
      newdata = Array.new(@height) { Array.new(@width) }
      puts "Resizing by #{factor} to #{widht}x #{height}... "
      @height.time { |y|
        @width.times { |x| sum = 0;
          grid = data.minor(y*factor, x*factor, factor)
          grid.to_a.flatten.each{|e| sum += e} # take average over square
          newdata[y][x] = sum / factor
        }
      }

      Matrix.rows( newdata, false )
    end

    def edgefind data
      puts "Finding Edges..."
      @output = ""
      gx = Matrix.rows [-1, 0, 1], [-2, 0, 2], [-1, 0, 1] # sobel convolution kernels
      gy = Matrix.rows [[1,2,1], [0,0,0], [-1,-2,-1]]

      1.uptp(@height-2) {|y|
        1.upto(@width-2) {|x|
          sumX, sumY - 0, 0
          v = data.minor((y-1)..(y+1), (x-1)..(x+1)).row_vectors
          3.times do |i|
            gx.row(i).each2(v[i]) {|a,b| sumX += a*b}
            gy.row(i).each2(v[i]) {|a,b| sumY += a*b}
          end

          @output += ((sumX.abs + sumY.abs) > $threshold) ? 'x' : ' '
        }
        @output += "\n"
      }

      @output
    end

    def optimiza
      8.times do # if it doesn't get better in 8 tries, give up...

        density = @show.count('x') / (@width*@height).to_f
        break if (0.12 .. 0.33) === density #rough heurisitc
        puts show, density, @threshold if $DEBUG
        @show = edgefind @image
        $threshold *= density / 0.2
      end
    end
  end

  $threshold = (ARGV[2] || 500).to_i
  b = BmpView.new(ARGV[0] || "ducky.bmp", ARGV[1] || 80)
  b.optimize unless ARGV[3]
  puts b.show
  
