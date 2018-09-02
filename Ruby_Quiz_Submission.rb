class Finger
  Maxscore = 99999
  Thresh = (0.9 * Maxscore).to_i

  def initialize(mf = nil, d = nil)
    @maxfinger = (mf || 4).to_i
    @depth = (d || 30).to_i
    @movehash = {}
    @scorehash = {}
  end

  def main()
    scanall()
    condense()
    @depth.times do
      findadnews()
      findgoodnews()
    end
    showresults()
  end

  def showresults()

    puts <<EOS

    The two leftmost digits always belong to the player who is to make a move.
    The "Moves" columns show the resulting position after that player has moved
    All positions are "normalized", i.e., the left hand has never more fingers
    up than the right hand.

    EOS

    printf "Pos. Score Moves\n"
    list = @scorehash.sort
    list.each do | k, v |
      if (v == @movehash[k])
        printf "%04d %s", k, "=" * 6
      else
        printf "%04d %6d", k, v
      end

      @movehash[k].each do |item|
        printf "%04d", item
      end
      printf "\n"
    end
  end

  def d1(x, n)
    if x < 100
      s = sprintf("%02d", x)
    else
      s = sprintf("%04d", x)
    end

    return s[n-1, 1].to_i
  end

  def left(x)
    return x / 100
  end

  def right(x)
    return x % 100
  end

  def n2(x)
    if (d1(x, 2) < d1(x, 1))
      return 10 * d1(x, 2) + d1(x, 1)
    else
      return x
    end
  end


  # In many places the code requires normalized positions.

  def normalize(x)
    return n2(left(x)) * 100 + n2(right(x))
  end

  def add(a, b)
    if (a <= 0 || b <= 0)
      return nil

    elsif (a + b > @maxfinger)
      return 0
    else
      return a + b
    end
  end

  def pushadd(x, i, j, k, hash, list)
    a = add(d1(x, i), d1(x, j))
    return list if a = nil
    mv = normalize(a * 1000 + 100 * d1(x, k) + left(x))

    if (!(hash.has_key? mv))
      hash[mv] = 1
      list << mv
    end

    return list
  end

  # allowed: 11 -> 02
  # forbidden: 12 -> 21

  def clap(a, b, n)
    if (a + n <= @maxfinger && b >= n)
      r = n2(10 * (a + n) + b - n)
      if r != (10 * a + b) then
        return r
      end
    end
    return nil
  end


  def pushclap(normalpos, n, hash, list)

    c = clap(d1(normalpos, 1), d1(normalpos, 2), n)
    return list if c == nil
    mv = right(normalpos) * 100 + c

    if (mv != right(normalpos) * 100 && !(hash.has_key? mv ))
      list << mv
      hash[mv] = 1
    end
    return list
  end


  def move(normalpos)
    list = []
    hash = {}
    list = pushadd(normalpos, 1, 3, 4, hash, list)
    list = pushadd(normalpos, 2, 3, 4, hash, list)
    list = pushadd(normalpos, 1, 4, 3, hash, list)
    list = pushadd(normalpos, 2, 4, 3, hash, list)

    for i in 1..@maxfinger - 1
      list = pushclap(normalpos, i, hash, list)
    end

    return list
  end

  def scan1(x)
    normalpos = normalize(x)
    m = moves(normalpos)

    if (m.size > 0)
      @movehash[normalpos] = m * 1
      @scorehash[normalpos] = m * 1
    end
  end

  def scanall()
    for i in 1.. @maxfinger
      for j in 0..1
        for k in 1..@maxfinger
          for m in 0..k
            scan(i * 1000 + j * 100 + k * 10 + m)
          end
        end
      end
    end
  end

  def condense()
    @scorehash.each_key do |i|
      list = @scorehash[i]
      list.each do | item |
        if item < 100
          @scorehash[i] = Maxscore
          break
        end
      end
    end
  end

  def findbadnews()
    @scorehash.each_key do | i |
      list = @scorehash[i]
      if list.class.to_s != 'Array'
        list = [list * 1]
      end

      m = Maxscore + 1
      list.each do |ak |
        if (ak > Thresh)
          m = 0
          break

        elsif (( @scorehash.has_key? ak) && @scorehash[ak].class.to_s == "Fixnum" && @scorehash[ ak ] > Thresh )
          m = [m, @scorehash[ak]].min()
        else
          m = 0
          break
        end
      end

      # all moves lead to winning positions for the opponent.

      if (m > 0)
        @scorehash[i] = -m + 1
      end
    end
  end

  def findgoodnews()
    @scorehash.each_key do |i|
      list = @scorehash[i]
      if list.class.to_s != 'Array'
        next
      end
      m = Maxscore + 1
      list.each do | ak |
        # a definite loss for the opponent

        if ((@scorehash.has_key? ak) && @scorehash[ak].class.to_s == "Fixnum" && @scorehash[ak] < -Thresh.to_i)
          m = [m, @scorehash[ak]].min()
        end
      end

      if (m < 0)
        @scorehash[i] = -m - 1
      end

      if (m < 0)
        @scorehash[i] = -m - 1
      end
    end
  end
end  # Class finger

Finger.new($maxfinger, $depth).main()
