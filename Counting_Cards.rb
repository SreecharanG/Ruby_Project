
# Implement a simple card counting scheme.

# Present a simulated card deal to the user to help him develop the counting technique.

# The real challenge is the second part. ruled out the cards names (3d, As, Tc...) and the
# ascii art options which left me needing a way of display proper graphic card images.

# Had a breif look at some gui toolkits (shoes, tk, ... ) but in the end decided on a browser
# based approach.

# I made a simple rails app and used an ajax request to update the traning page. If anyone
# wants to try it, download http://www.hennessynet.com/counter.tar.gz

# and unpack it into a temporary directory. Then run ./script/server and browse
# to http://localhost:3000/card_counter

# The card counting algorithm is implemented first. The Counter class contains
# both the shuffled shoe as well as the running count.

# card_counter.rb

CARDS = %w{A K Q J T 9 8 7 6 5 4 3 2}
SUITS = %w{c s h d}

class Counter

  def initialize(decks)

    @count = 4 - 4 * decks
    @shoe = []
    decks.times do
      CARDS.each do |c|
        SUITS.each do |s|
          @shoe << c.to_s + s.to_s
        end
      end
    end

    size = 52 * decks
    size.times do |i|
      j = rand(size)
      @shoe[i], @shoe[j] = @shoe[j], @shoe[i]
    end
  end

  def deal

    card = @shoe.pop
    @count += 1 if "234567".include? card[0, 1].to_s
    @count -= 1 if "TJQKA".include? card[0,1].to_s
    card
  end


  def count
    @count
  end

  def size
    @shoe.size
  end
end


# I made a rails app with a controller called card_counter_controller.rb and a web page
# practice.html.erb to 'run' the traning.

# The interesting bit is the periodically_call_remote() call which gets a new set of cards
# every n seconds and displays them to the user.

# A pause button suspends the dealing and displays the current count. I found a free set of card
# images at http://www.jfitx.com/cards/

# card_counter_controller.rb:

require 'card_counter'

class CardCounterController < ApplicationController

  def practice

    session[:counter] = Counter.new params[:decks].to_i
    session[:main] = params[:min].to_i
    session[:max] = params[:max].to_i
    session[:delay] = params[:delay].to_i

  end

  def deal

    min = session[:min]
    max = session[:max]
    counter = session[:counter]
    max = counter.size if counter.size < max
    min = max if max < min

    count = min + rand(max - min + 1)
    text = ""
    text = "Shoe complete" if count == 0
    count.times do
      card = session[:counter].deal
      text += "<img src= '/image/#{card_index(card)}.png' width = '72' height= '96' />\n"
    end

    text += "<p id = 'count' style = 'visibility: hidden' >Count is #{counter.count}<\p>"
    render :text => text
  end


  # Convert card name ("6d", "Qs"....) to image index hwew 1 = Ac, 2 = As, 3 =Ah, 4 = Ad, 5 = Kc and so on

  def card_index(card)

    c = CARDS.index card[0,1].to_s
    s = SUITS.index card[1, 1].to_s

    c * 4 + s + 1
  end
end
