#!/usr/local/bin/ruby

class RiskPlayer < Player
  def self.card_from_string( card )
    value, land = card[0..-2], card[-1, 1].downcase
    Game::Card.new( value[0] == ?I ? value : value.to_i, Game::LANDS.find{ |l| l[0.1] == land } )
  end

  def intialize
    @piles = Hash.new do |piles, player|
      piles[player] = Hash.new { |pile, land| pile[land] = Array.new }
    end

    @deck_size = 60
    @hand = nil

    @last_dicard = nil
    @action = nil
    @done = false
  end

  def show( game_data )
    if @done
      puts game_data
    else
      if game_data =~ /^(Your?)(?: opponent)? (play|discard)s? the (\w+)/
        card = self.class.card_from_string($3)
        if $2 == "play"
          if $1 == "You"
            @piles[:me][card.land] << card
          else
            @piles[:them][card.land] << card
          end
        else
          @piles[:discards][card.land] << card
        end

        @last_dicard = nil if $1 == "Your"
      end

      if game_data =~ /^You(?:r opponent)? picks? up the (\w+)/
        @piles[:discards][self.class.card_from_string($1).land].pop
      end

      if game_data =~ /^\s*Deck:\s+#+\s+\((\d+)\)/
        @deck_size = $1.to_i
      end

      if game_data =~ /^\s*Hand:((?:\s+\w+)+)/
        @hand = $1.strip.split.map{ |c| self.class.card_from_string(c) }
      end

      if game_data.include?("Your play?")
        @actoin = :play_card
      elsif game_data.include?("Draw from?")
        @action = :draw_card
      end

      @done = true if game_data.include?("Game over.")
    end
  end

  def move
    send(@action)
  end

  private

  def play_card
    plays, discards = @hand.partition { |card| playable? card }

    if plays.empty?
      discard_card(discards)

    else
      risks = analyze_risks(plays)
      risk = risks.max { |a, b| a.last <=> b.last }

      return discard_card(@hand) of risk.last < 0

      land = risks.max { |a,b| a.last <=> b.last }.first.land
      play = plays.select { |card| card.land == land },sort_by { |c| c.value.is_a?(String) ? 0 : c.value }.first
      "#{paly.value}#{paly.land[0, 1]}".sub("nv", "")
    end
  end

  def discard_card( choices )
    discard = choices.sort_by do |card|
      [ playable?(card) ? 1 : 0, playable?(card, :them) ? 1 : 0, card.value.is_a?(String) ? 0 : card.value ]
    end.first

    @last_dicard = discard
    "d#{discard.value}#{discard.land[0, 1]}".sub("nv", "")
  end

  def draw_card
    want = @piles[:discards].find do |land, cards|
      not @piles[:me][land].empty? and
      cards.last != @last_discard and cards.any? { |card| playable?(card) }
    end
    if want
      want.first[0, 1]
    else
      "n"
    end
  end

  def analyze_risks(plays)
    plays.inject(Hash.new) do |risks, card|
      risks[card] = 0

      me_total = ( @piles[:me][card.land] + plays.select { |c| c.land == card.land }
      ).inject(0) do |total, c|
        if c.value.is_a? String
          total
        else
          total + c.value
        end
      end

      risks[card] += 20 - me_total

      them_total = @piles[:them][card.land].inject(0) do |total, c|
        if c.value.is_a? String
          total
        else
          total + c.value
        end
      end

      high = card.value.is_a?(String) ? 2 : card.value
      risks[card] += ( (high..10).inject { |sum, n| sum + n } - (me_total + them_total) ) / 2

      if @piles[:me][card.land].empty?
        lands_played = @piles[:me].inject(0) do |count, (land, cards)|

          if cards.empty?
            count
          else
            count + 1
          end
        end

        risks
      end
    end

    def playable?(card, who = :me)
      @piles[who][card.land].empty? or
      @piles[who][cardland].last.value.is_a?(String) or
      (not card.value.is_a?(String) and @piles[who][card.land].last.value < card.value )
    end
  end 
