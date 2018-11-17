
module Euchre

  class Hand
    attr_accessor :cards

    def initialize( trump )
      @cards = []
      @trump = Card.new(trump)
    end

    def <<( card )
      @cards << card
    end

    def sort!
      @cards =
      # First the trump jack ...

      @cards.select{ |c| trump_suit?(c) and c.jack?} |

      # Then the jack of the trump color
      @cards.select{ |c| trump_color?(c) and c.jack? } |

      # Then all the trump cards ...
      @cards.select{ |c| trump_suit?(c) }.sort.reverse |
      #then a different color, so the colors alternate ...

      @cards.select{ |c| !trump_color?(c) and c.suit =~ /d|c/ }.sort.reverse |

      # then the cards with the same color as the trump...
      @cards.select{ |c| trump_color?(c) }.sort.reverse |

      # and finally the rest.

      @cards.sort.reverse
    end

    def trump_suit?( card ) card.suit == @trump.suit end
    def trump_color?( card ) card.color == @trump.color end


    def to_s
      @cards.join("\n")
    end
  end

  class Card
    attr_accessor :suit, :face

    Suits = ['d', 'h', 'c', 's']
    Faces = ['9', 'T', 'J', 'K', 'A']
    Colors = {'d' => :red, 'h' => :red, 'c' => :black, 's' => :black}

    def initialize(suit, face=nil)
      @suit = suit.downcase
      @face = face.upcase if face
    end

    def jack?() @face == 'J' end
    def color() Colors[@suit] end

      # Sort first by suit and then by face

    def <=> ( other )

      rel = Suits.index(@suit) - Suits.index(other.suit)
      rel = Faces.index(@face) - Faces.index(other.face) if rel == 0
      rel
    end

    def to_s
      @face + @suit
    end
  end
end

if __FILE__ = $0
  lines = readliness

  trump = lines.shift.slice(/\w+/)
  hand = Euchre::Hand.new(trump[0, 1])

  lines.join.scan(/(\w)(\w)/) do |face, suit|
    hand << Euchre::Card.new(suit, face)
  end

  hand.sort!
  puts trump
  puts hand
end
