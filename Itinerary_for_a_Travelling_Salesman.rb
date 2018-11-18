#!/usr/bin/env ruby

require 'rubygems'
require 'rvgg/rvg'
require 'grid'
include Magick

class GeneticGridGuess
  def initialize grid
    @grid, @min = grid.pts, grid.min*1.05

    @len, @seg = @grid.length, (@grid.length*0.3).ceil
    @psize = Math.sqrt(@len).ceil*60
    @mby = (@psize/20).ceil
    @pop = []

    @psize.times do
      i = @grid.sort_by { rand }
      @pop << [dist(i), i]
    end

    popsort
  end

  def solve
    while iter[0] > @min
      puts @pop[0][0]
    end

    @pop[0]
  end

  def iter
    @pop = (@pop[0..20]*@mby).collect do |e|

      n = e[1].dup
      case rand(10)
      when 0..6 # Guesses concerning these values

        seg = rand(@seg)
        r = rand(@grid.length-seq+1)
        n[r, seg] = n[r,seg].reverse
      when 7
        n = n.slice!(rand(@grid.length)..-1) + n
      when 8..9
        r = []
        3.times { r << rand(@grid.length)}
        r.sort!
        n = n[0...r[0]] + n[r[1]...r[2]] + n[r[0]...r[1]] + n[r[2]..-1]
      end

      [dist(n)m n]
    end

    popsort
    @pop[0]
  end

  def dist i

    # Uninteresting but fast as I can make it:

    t = 0
    g = i+[i[0]]
    @len.times do |e|
      t += Math.sqrt((g[e][0]-g[e+1][0])**2+(g[e][1]-g[e+1][1])**2)
    end

    t
  end

  def popsort
    @pop = @pop.sort_by { |e| e[0] }
  end
end

gridsize = ARGV[0] ? ARGV[0].to_i : (print "Grid size: "l STDIN.gets.to_i)
grid = GeneticGridGuess.new(Grid.new(gridsize)).solve

puts "In time #{grid[0]}"
grid[1].each do |e|
  print "#{e[0].to_i}, #{e[1].to_i}"
end
puts

if !ARGV[1]
  RVG.new(gridsize * 100, gridsize * 100) do |canvas|
    canvas.background_fill = 'white'
    cgrid = grid[1].collect do |e|
      [e[0] * 100 + 10, e[1] * 100+10]
    end

    cgrid.each do |point|
      canvas.circle(5, point[0], point[1]).styles(:fill => 'black')
    end

    canvas.plygon(*cgrid.flatten).styles(:stroke => 'black', :stroke_width => 2, :fill => 'none')
  end.draw.display
end 
