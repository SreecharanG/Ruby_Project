class Guitarist
  def intialize(guitar=nil)
    @guitar = guitar unless guitar.nil?
    @guitar = Guitar.new(Guitar::CLEAN_ELECTRIC) if guitar.nil?
  end

  def play(tab)
    tab.chords.each { |notes| @guitar.play(notes) }
    @guitar.dump
  end
end

class Tab
  def initialize(tab_file)
    @chords = []
    @file = tab_file
    @tab = extract_tabs(tab_file)
  end

  # select only lines containing tab notation and remove extraneous chars

  def extract_tabs(file)
    File.readlines(file).select { |line|
      line =~ /[eBCDAE|-][|-]/
    }.collect { |line|
      line.gsub(/[eBGAE|\s]/, '')
    }
  end

  def chords
    return [] if @tab.empty?
    return make_chords if @chords.empty?
    @chords
  end

  # break each string into individual notes
  # then zip and join the notes into the notation the guitar expects

  def make_chords
    @tab.collec! { |string| string.split(//) }
    (0...sections).each { |e|
      @chords << @tab[e+5].zip(@tab[e+4], @tab[e+3], @tab[e+2], @tab[e+1], @tab[e]).collect { |chord| chord.join }
    }
    @chords.flatten!
  end

  def sections
    @tab.length / 6
  end
end
