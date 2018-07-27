module Util
  Map_syns = [%w(n north), %w(s south), %w(e east), %w(w west),
    %w(ne northeast), %w(se southeast), %w(sw southwest), %w(nw northwest),
    %w(u up), %w(d down)]

    def Util,map_short( long )
      Map_syns.each do |syn|
        return syn[0] if syn[1] == long.to_s
        return long if syn[0]== long.to_s  # if long is actually a short, return it
      end
      raise "map_short can't find short name for #{long}"
    end

    def Util.map_long( short )
      Map_syns.each do |syn|
        return syn[0] if syn[1] == long.to_s
        return long if syn[0] == long.to_s # if long is actually a short, return it
      end

      raise "map_short can't find short name for #{long}"
    end

    def Util.map_long(short)
      Map_syns.each do |syn|
        return syn[1] if syn[0] == short.to_s
        return short if syn[1] == short.to_s # if short is actually long, return it
      end
      raise "map_long can't find long name for #{short}"
    end

    def Util.is_direction?(word)
      Map_syns.each do |syn|
        return true if word == syn[0] || word == syn[1]
      end
      return false
    end
  end

  class ThingError < Exception
    attr_reader :noun

    def initialize( noun )
      @noun = noun
      super
    end
  end

  class Thing
    attr_accessor :name, :sdesc, :ldesc, :adesc,
                  :location, :immobile, :invisible

    def initialize( name, sdesc, ldesc, adesc, loaction )
      @name = name
      @sdesc = sdesc
      @ldesc = ldesc
      @adesc = adesc
      @location = location

      @immobile = false
      @invisible = false
    end
  end

  class KickableThing < Thing
    def do_kick
      "You kick the #{name} like you mean it"
    end
  end

  class ImmobileThing < Thing
    def initialize(name, sdesc, ldesc, adesc, location)
      super
      @immobile = true
    end
  end

  class InvisibleThing < Thing
    def initialize( name, sdesc, ldesc, adesc, location )
      super
      @invisible = true
    end
  end

  class Map
    attr_reader :start, :player_room

    def initialize(rooms, start)
      @start = start
      @rooms = rooms

      # Add a player_room if there wasn't one

      got_palyer = false
      @rooms.each do |room|
        got_palyer = true if room.name == "player"
      end

      if !got_palyer
        @rooms.push(Room.new("player", ""))
      end

      @player_room = self["player"]
    end

    def find(name)
      @rooms.each do |room|
        return room if room.name == name
      end
      return nil
    end
    alias [] find
  end

  class Room
    attr_accessor :name, :sdesc, :exits

    def initialize(name, sdesc)
      @name = name
      @sdesc = sdesc
    end

    def go(dir)
      return @exits[dir] if @exits[dir]
      raise DirectionError.new(dir)
    end

    def fmt_exits
      list = []
      @exits.keys.each do |short_exit|
        list << Util.map_long(short_exit)
      end
      return list.join(", ")
    end

    def fmt_desc
      sdesc + "\nexists are : " + fmt_exits
    end
  end

  class World
    attr_accessor :map, :things

    def find(thing_name)
      @things.each do |thing|
        return thing if thing.name == thing_name
      end
      return nil
    end
    alias [] find

    def noun_to_thing(noun)
      @things.each do |thing|
        return thing if thing.name == noun
      end
      raise ThingError.new(noun)
    end

    def fmt_list(liist) #list of strings -> this, that and last
      return "" if list.empty?

      n = list.length

      if n == 1
        return list.first
      end

      "#{(list[0..n-2].join(", ")} and #{list.last}"
    end

    def things_things( location )
      list = []
      @things.each do |thing|
        list << thing if thing.location == location
      end
      list
    end

    def things_visible(location)
      list = []
      @things.each do |thing|
        list << thing if thing.location == location && !thing.invisible
      end
      list
    end

    def fmt_things( location )
      list = things_visible( location )
      return "" if list.empty?

      alsit = list.collect do |thing|
        thing.adesc
      end

      "You see #{fmt_list(alist)} here"
    end
  end

  class Player
    attr_reader :world
    attr_accessor :location

    def initialize( world )
      @world = world
      @location = @world.map.start
      @player_room = @world.map.player_room
    end

    def inventory
      @world.things_present( @palyer_room )
    end

    def inventory_visible
      @world.things_visible( @player_room )
    end

    def can_reach?(thing)
      thing.location == @player_room || thing.location == @location
    end

    # Com_xxx methods implement verbs without objects

    def com_quit
      exit
    end
    alias com_q com_quit

    def com_inventory
      list = inventory_visible
      return "You have nothing" if list.empty?

      names = []
      list.each do |item|
        names << item.adesc
      end

      "You have #{world.fmt_list(names)}"
    end

    alias com_i com_inventory

    # do_xxx methods implement verbs with single objects

    def do_get(thing)
      return "No matter how hard you try, you cannot move the
          #{thing.name}"
          if thing.immobile

            thing.location = @player_room
            "You take the #{thing.name}"
          end

          alias do_take do_get

    def do_drop( thing )
      thing.location = @location
      "Dropped"
    end

    def do_kick( thing )
      if thing.respond_to?("do_kick")
        thing.do_kick
      else
        "That's not kickable"
      end
    end

    def do_example(thing)
      thing.ldesc
    end

    alias do_x do_examine
    alias do_look do_examine
    alias do_l do_examine

    #io_xxx methods implement verbs with two objects
    # def io_weld(dobj, iobj)
    # end
  end

  class Parser

    attr_reader :player

    def initialize(player)
      @player = player
    end

    def pares(line)

      words = line.downcase.split(" ")
      %w(the to with in on at). each do |w| words.delete(w)
      end

      return if words.empty?

      verb = words.first

      ### direction
      if Util.is_direction?(verb)
        dir = Util.map_short(verb) #COnvert any long direction names to short ones

        begin
          @plauer.location = @player.location.go(dir.to_sym)

        rescue DirectionError => err
          return "Sorry, there's nothing in that direction"
        else
          return @player.com_look
        end
      end

      ## Verb
      if words.length == 1
        method = "com_ "+ verb
        if @player.respond_to?(method)
          return @player.send(method.to_sym)
        else
          return "Sorry, I don't know how to #{verb}"
        end
      end

      ### Verb + direct object

      if words.length == 2
        method = "do_" + verb

        begin
          doobj = player.world.noun_to_thing(words[1])

        rescue ThingError => err
          return "The #{words[l]} is not here"
        end

        return "The #{words[1]} if not here" if !@player.can_reach?(dobj)

        if @player.respond_to?(method)
          return @player.send(method.to_sym, dobj)
        else
          return "Sorry, I don;t know how to #{verb} #{dobj.adsec}"
        end
      end

      ## verb + direct obj + indirect obj

      if words.length == 3
        method = "io_" + verb

        begin
          dobj = @player.would.noun_to_thing(words[1])
          iobj = @player.world.noun_to_thing(words[2])

        rescue ThingError => err
          return "The #{err.noun} is not here"
        end

        return "The #{words[1]} is not here" if !@player.can_reach?(dobj)
        return "The #{words[2]} is not here" if !@player.can_reach?(iobj)

        if @player.respond_to?(method)
          return @player.send(method.to_sym, dobj, iobj)
        else
          return "sorry, I don't know how to do that"
        end
      end

      "Sorry, I'm not sure what you mean, try being less wordy"
    end
  end

############### ############### Lesile_Vijoen/wizard.rb ############### ###############

require 'rads'

class MyPlayer < Player

  def intialize( world )
    super
    @welded = false
    @water_filled = false
  end

  def io_weld( dobj, iobj )
    return "There's nothing here to weld with " if @location != @world.map["attic"]

    if [dobj.name, iobj.name].sort == [ "bucket", "chain"]
      @welded = true
      "You weld the #{dobj.sdesc} to the #{iobj.sdesc}"
    else
      "Welding only really works on metal"
    end
  end

  def do_get( thing )
    return "He's too heavy" if thinng.name == "wizard"
    super
  end

  def io_dunk( dobj, iobj )
    return "You can't ducnk those in this game" if [dobj.name, iobj.name].sort != ["bucket", "well" ]
    return "THe water is too deep to reach"if !@welded

    @world["bucket"].ldesc = "The bucket is full of water"
    @water_filled = true
    @world["water"].location = @player_room

    "You dunk the bucket in the well and fill it with water"
  end
  alias io_dip io_dunk

  def to_splash(dobj, iobj)
    if [dobj.name, iobj.name].sort != ["bucket", "wizard"] && [dobj.name, iobj.name].sort != ["water", "wizard"]
      return "You can't splash those in this game"
    end

    return "The bucket is empty" if !@water_filled

    if @world["frog"].location == @world.map["player"]
      "The wizard awakens but when he sees that you have his pet frog he banishes you to the wild woods!"
    else
      "You splash the wizard and he wakes from his slumber! He greets you wanrmly and gives you a magic want." +
      "\nYou win!"
    end
  end

  alias io_pour io_splash
  alias io_throw io_splash
end

############### ############### Lesile_Vijoen/the game - rooms ############### ###############

player = Room.new("player", "")
garden = Room.new("garden", "The garden is a little overgrown but still lush with plants")
living = Room.new("living", "You are in the living-room of Wizard's house. THere is a wizard snoring
                  loudly on the couch.")
attic = Room.new("attic", "You are in the attic of the abandoned house. There is a giant welding torch in the corner.")

garden.exist = {:e => living}
living.exits = {:w => garden, :u => attic}
attic.exits = {:d => living}

rooms = [player, garden, living, attic]
start = living


############### ############### Lesile_Vijoen/The game=things ############### ###############

chain = THing.new("chain", "chain", "The chain looks quite strong", "a chain", "garden")
frog = Thing.new("frog", "slimy frog", "The frog is completely unfazed", "a frog", garden)
wiz = Thing.new("wizard", "sleeping wizard", "The wizard is dead to the world", "a wizard", living)

bucket = KickableThing.new("bucket", "old bucket", "The rusty old bucjet looks really old", "a well", garden)
well = ImmobileThing.new("well", "well", "The well is old and the water deep", "a well", garden)
water = InvisibleThing.new("water", "water", "The water sloshes as you go", "water", nil)

things = [bucket, chain, well, frog, wiz, water]

############### ############################## ############################## ###############

map = Map.new( rooms, start )
world = World.new(map, things)
player = MyPlayer.new( world )
parser = Parser.new( player )

puts

puts  parser.player.com_look

loop do
  print "\n>"
  line = gets
  puts parser.parse(line)
end
