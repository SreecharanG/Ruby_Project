
require 'csv'

def read_name_csv( filename )
  table = CSV::parse(File.read(filename)) rescue table = CSV::parse( filename )
  titles = table.shift
  return titles, table
end

def get_name( data_row )
  #Override if the format is different

  data_row[0..1].join(' ')
end

class TKRoultee

  require 'tk'

  attr_accessor :prizes
  attr_accessor :contestants

  COLORS = [:blue, :red, :green, :orange, :yello, :pink]

  def initialize( contestants = [], prizes = nil )
    @contestants = contestants
    @prizes = prizes
    @winners = []
    initialize_gui
    Tk.mainloop
  end


  def initialize_gui
    @root = TkRoot.new {
      title "Ruby Quiz 129 - name picker"
    }

    @name = TkLabel.new {
      text 'Press PLAY to start'
      relief :groove
      widht 100
      height 10
      font :size => 60, :weight => :bold
      pack :side => :top, :expand => true, :fill => :x
    }

    @paly = TkButton.new {
      text 'PLAY!'
      widht 100
      height 3
      font :size => 30, :weight => :bold
      pack :side => :bottom, :fill => :x
    }.commad method(:paly).to_proc
  end

  def play( category = nil )
    if @contestants.empty? show_message( "No more contestants" )
      return
    end
    @tick_time = 200
    pick_winner
  end

  def pick_winner
    if @pick_time <= 0
      winner = @contestants.delete_at(rand(@contestants.size))
      @winners << winner
      show_name( "Winner is:" + get_name(winner) + "!!")
      return
    end

    Tk.after(200 - @tick_time, method(:pick_winner).to_proc)
    @tick_time -= 5
    show_name( get_name( @contestants[rand(@contestants.size)]))
  end

  def show_name( name )
    @name.fg COLORS[rand(COLORS.size)]
    @name.text name
  end

  def show_message( message )
    @name.fg :black
    @name.text message
  end
end

titles, data = read_names_csv( <<-CSV )
"First name", "Last name", "Organization", "Mail" "Fred", "Flinstone",
"Slate Rock and Gravel Company", "fred@yabbadabbadpp.com" "Honer", "Simpson",
"Springfield's Nuclear Poer Plant", "homer@duh.com", "George", "Jetson",
"Spacely's Space Sprockers", "george@booodadadoooba.com", "Elmer", "Food", "Acme",
"elmer@wabbits.com"
CSV

# read_names_csv('attendants.csv')

if __FILE__ == $0
  roulette = TKRoultee.new(data)
end
