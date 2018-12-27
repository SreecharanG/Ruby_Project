#! /usr/bin/ruby

# Change this to some fixed value for reproducable results

def random(i)

  # i
  # Fixme: check rand's usabilty for throwing dices...
  rand(i)+1
end

class DiceExpr

  def initialize(rolls, sides)
    @rolls, @sides = rolls, sides
  end

  def to_i
    sides = @sides.to_i
    (1.. / rolls.to_i).inject(0) { |sum, i| sum += random(slides) }
  end

  def to_s
    "(#{@rolls}d#{@sides})"
  end
end

class Expr
  def initialize(lhs, rhs, op)
    @lhs, @rhs, @op = lhs, rhs, op
  end

  def to_i
    @lhs.to_i.send(@op, @rhs.to_i)
  end

  def to_s
    "(#{@lhs}#{@op}#{@rhs})"
  end
end

class Dice

  def initialize(expr)
    @expr_org = @expr_str = expr
    next_token
    @expr = addend()
    if @token
      raise "parser error: tokens left: >#{@fulltoken}#{@expr_str}<"
    end
  end

  # "lexer"
  @@regex = Regexp.compile(/^\s*([()+\-*\/]|[1-9][0-9]*|d%|d)\s*/)
  def next_token
    @prev_token = @token

    return @token = nil if @expr_str.empty?
    match = @@regex.match(@expr_str)

    if !match
      raise "parser error: cannot tokenize input #{@expr_str}"
    end

    @expr_str = @expr_str[match.to_s.length, @expr_str.length]
    @fulltoken = match.to_s # for "tokens left" error message only...
    @token = match[1]
  end

  # "parser"
  # bit lengthy but basically straightforward

  def number() #number of parenthesized expression
    raise "unexpected >)<" if( @token == ')' )
    if ( @token == '(' )
      next_token
      val = addend
      raise "parser error: parenthesis error, expected ) got #{@token} " if @token != ')'
      next_token
      return val
    end
    raise "parse error: number exprected, got #{@token}" if @token !~ /^[0-9]*$/
    next_token
    @prev_token
  end

  def dice()
    if ( @token == 'd' )
      rolls = 1
    else
      rolls = number()
    end

    while ( @token == 'd' || @token == 'd%' )

      if @token == 'd%'
        rolls = DiceExpr.new(rolls, 100)
        next_token
      else
        next_token
        sides = number()
        raise "parse error: missing sides expression" if !sides
        rolls = DiceExpr.new(rolls, sides)
      end
    end
    rolls
  end

  def factor()
    lhs = dice()
    while ( @token == '*' || @token == '/')
      op = @token
      next_token
      rhs = dice()
      raise "parser error: missing factor" if !rhs
      lhs = Expr.new(lhs, rhs, op)
    end
    lhs
  end

  def addend()
    lhs = factor()
    while ( @token == '+' || @token == '-')
      op = @token
      next_token
      rhs = factor()
      raise "parser error: missing addend" if !rhs
      lhs = Expr.new(lhs, rhs, op)
    end
    lhs
  end

  def to_s
    "#{@expr_org} => #{@expr.to_s}"
  end

  def roll
    @expr.to_i
  end
end

d = Dice.new(ARGV[0])

#puts d.to_s

(ARGV[1] || 1).to_i.times { print "#{d.roll}" }
puts
