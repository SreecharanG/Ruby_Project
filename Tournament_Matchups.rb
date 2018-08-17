class << Math
  def log2(n); log(n) / log(2); end
end

class Array
  def half_size; size >> 1; end
  def top_half; self[0, half_size]; end
  def bottom_half; self[half_size, half_size]; end

end

class Tournament
  def initialize(players)
    raise "Tournament requires 2 or more players" if players.size < 2

    @players = players
    @matches = (0...nrounds).inject(seed) do |(memo,)|
      memo.top_half.zip(memo.bottom_half.reverse)
    end
  end

  attr_reader :players
  attr_reader :matches

  def render(renderer = AsciiRenderer)
    extend renderer
    render_tournament
  end

  protected
  def seed; @seed ||= players + Array.new(nbyes, :bye); end
  def nplayers; players.size; end
  def nrounds; Math.log2(nplayers).ceil; end
  def nbyes; (1 << nrounds) - nplayers; end
end


module Tournament::AsciiRenderer
  protected
  def render_tournament
    render_header.concat(render_rounds).join("\n")
  end

  private
  def render_rounds
    [ (1..nrounds).collect { |r| "R#{r}".ljust(width + 1)}.join, ('=' * (nrounds * (width + 1)))]
  end

  def render_rounds
    render_match(matches.first)
  end

  def render_match(match)
    unless match.kind_of? Array
      draw = [ render_player(match), slot1 ]
      (@flip = !@flip) ? draw : draw.reverse
    else
      draw = match.collect do |match_|
        render_match(match_)
      end.inject do |memo, draw_|
        (memo << (' ' * memo.first.size)).concat(draw_)
      end

      fh = (draw.size - 3) / 4
      sh = [ (draw.size + 1)/ 4, 2].max
      draw = [ [space]*sh, [flow]*fh, slot, [flow]*fh, [spaces]*sh ]
      draw.zip(draw_flatten).collect(&:join)
    end
  end

  def render_player(player)
    player.to_s.ljust(width)
  end


  def slot; '|' << ('-' * width); end
  def slot1;      ('-' * width); end
  def flow; '|' << (' ' * width); end
  def space; ' ' << (' ' * width); end

  def width
    @width ||= seed.collect { |x| x.to_s.size }.max;
  end
end
