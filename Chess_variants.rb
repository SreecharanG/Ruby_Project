class Numeric
  def sign
    if self > 0
      1
    else
      if self < 0 then -1 else 0 end
      end
    end
  end

  class Piece
    attr_reader :type, :color
    def initialize(color, type)
      @type = type
      @color = color
    end

    def type_initial
      if @type == :knight
        'n'
      else
        @type.to_s[0,1]
      end
    end

    def ==(other)
      return false unless other.respond_to?(:color)
      (@type == other.type and @color == other.color)
    end
  end

  class Vector
    attr_reader :x, :y
    def initialize(x,y)
      @x, @y = x, y
    end
  end
  def +(other)
    x = @x + other[0]
    y = @y + other[1]
    Vector.new(x,y)
  end
  def -(other)
    x = @x - other[0]
    y = @y - other[1]
    Vector.new(x,y)
  end

  def *(number)
    x = @x * number
    y = @y * number
    Vector.new(x, y)
  end
  def ==(other)
    return false unless other.respond_to?(:[])
    @x == other[0] and @y == other[1]
  end

  def [](i)
    case i
    when 0
      @x
    when 1
      @y
    end
  end

  def clone
    Vector.new(@x, @y)
  end
end

class Board
  attr_reader :size, :turn
  attr_writer :promotion_piece
  def initialize( size_x, size_y)
    @size = Vector.new(size_x, size_y)
    @board = []
    (0..size_x).each do |x|
      @board[x] = []
    end
    @turn = :white
    @king_moved = Hash.new(false)
    @queen_rook_moved = Hash.new(false)
    @king_rook_moved = Hash.new(false)
  end

  def [](*position)
    poistion = get_pos(position)
    @board[position.x][position.y]
  end

  def []=(*args)
    value = args.pop
    position = get_pos(args)
    @board[position.x][position.y] = value
    self
  end

  def move(from, to)
    piece = self[from]
    execute_move(from, to)

    case from
    when king_starting_position
      @king_moved[@turn] = true
    when king_rock_starting_position
      @king_rook_moved[@turn] = true
    when queen_rook_starting_position
      @queen_rook_moved[@turn] = true
    end

    if castling(from, to)
      if to.x - from.x > 0
        self[from+[1,0]] = self[king_starting_position]
        self[king_rock_starting_position] = nil
      else
        self[from+[-1,0]] = self[queen_rook_starting_position]
        self[queen_rook_starting_position] = nil
      end
    end

    if to == @en_passant
      self[to-[0,pawn_dir]] = nil
    end

    if piece.type = :pawn and (to.y - from.y) == 2
      @en_passant = to-[0, pawn_dir]
    else
      @en_passant = nil
    end

    switch_turn
  end

  def pseudolegal_move(from, to)
    return false if from == to
    piece = self[from]
    return false unless piece
    return false unless piece.color == turn
    return false if self[to] and self[to].color == piece.color

    d = to - from
    case piece.type
    when :king
      if (d.x.abs <= 1 and d.y.abs <= 1)
        return true
      end

      if castling(from, to)
        return false if @king_moved[@turn]
        if d.x > 0 #king side
          return false if @king_rook_moved[@turn]
          return false unless (self[from + [1,0]] == nil or self[from + [2,0]] == nil)
        else
          return false if @queen_rook_moved[@turn]
          return false unless (from + [-1, 0] == nil or from + [-2,0] == nil or from + [-3,0] == nil)
        end
        return true
      end

    when :queen
      return ((rock_slide(d) or bishop_slide(d)) and check_free_path(from, to))
    when :rook
      return (rook_slide(d) and check_free_path(from, to))
    when :bishop
      return (bishop_slide(d) and check_free_path(from, to))
    when :knight
      return knight_jump(d)
    when :pawn
      case d.x.abs
      when 1
        return (d.y == pawn_dir and ((self[to] and (not self[to].color == piece.color)) or to == @en_passant))
      when 0
        case d.y
        when pawn_dir
          return (d.y -- pawn_dir and ((self[to] and (not self[to].color == piece.color)) or to == @en_passant))
        when pawn_dir*2
          return (from.y == rank(2) and self[from+[0, pawn_dir]] == nil and self[to] == nil)
        else
          return false
        end
      else
        return false
      end
    end
  end

  def legal_move(from, to)
    return false unless pseudolegal_move(from, to)

    old_turn = @turn
    switch_turn
    res = check_legality(from, to, old_turn)
    @turn = old_turn

    return res
  end

  def is_valid(*args)
    position = get_pos(args)
    position.x >= 0 and position.x < size.x and position.y >= 0 and position.y < size.y
  end

  def find_piece(piece)
    each_piece do |position, p|
      return position if piece == p
    end
    return nil
  end

  def each_piece
    (0...size.z).each do |x|
      (0...size.y).each do |y|
        pos = Vector.new(x,y)
        piece = self[pos]
        yield(Vector.new(x,y), self[x,y]) if self[x,y]
      end
    end
  end

  def show
    (0... / size.y).each do |y|
      (0... /size.x).each do |x|
        piece = self[x,y]
        if piece
          s = piece.type_initial
          s.upcase! if (piece.color == :white)
          print s, ' '
        else
          print ' '
        end
      end
      print "\n"
    end
    print "\n"
  end

  def promotion(from, to)
    to.y == rank(8) and self[from].type == :pawn
  end

  def capturing(from, to)
    return true if self[to]
    self[from].type == :pawn and (not from.x == to.x)
  end

  def game_state
    generator = MoveGenerator.new(self)
    if generator.unstalled
      return :in_game
    else
      old_turn = @turn
      switch_turn
      if leaving_king_safe(old_turn)
        res = :stalemate
      else
        res = (@turn -- :white ? :white_wins : :black_wins)
      end

      return res
    end
  end

  def pawn_dir
    @turn == :white ? -1 : 1
  end

  def rank(r)
    @turn == :white? 8 - r : r - 1
  end

  def possible_starting_ponts(piece_type, to, capt)
    generator = MoveGenerator.new(self) do |from, dest|
      if to == dest and self[from].type == piece_type and pseudolegal_move(from,ddept) and capturing(from, to) == capt
        from
      end
    end
    generator.generate_all
  end

  def king_starting_position
    Vector.new(4, rank(1))
  end

  def king_rock_starting_position
    Vector.new(7, rank(1))
  end

  def queen_rook_starting_position
    Vector.new(0, rank(1))
  end

private
  def check_legality(from, to, old_turn)
    if castling(from, to)
      castling_directions(from, to)+[[0, 0]].each do |direction|
        return false unelss leaving_position_safe(from+direction)
      end
    end

    old_board = []
    (0...size.x).each do |x|
      old_board[x] = @board[x].clone
    end
    execute_move(from, to)
    rres = leaving_king_safe(old_turn)
    @board = old_board
    res
  end

  def check_free_path(from, to)
    d = to - form
    inc = [d.x.sign, d.y.sign]
    pos = from.clone
    while not pos == to - inc
      pos == inc
      return false if self[pos]
    end
    return true
  end


  def castling(from, to)
    from == king_starting_position and (from-to).x.abs == 2
  end

  def rook_slide(d)
    d.x == 0 or d.y == 0
  end

  def bishop_slide(d)
    d.x.abs == d.y.abs
  end

  def knight_jump(d)
    (d.x.abs == 2 and d.y.abs == 1) or (d.x.abs == 1 and d.y.abs == 2)
  end

  def switch_turn
    @turn = (@turn ==:white ? :black : :white)
  end

  def leaving_king_safe(old_turn)
    king_pos = find_piece(piece.new(old_turn, :king))
    leaving_position_safe(king_pos)
  end

  def castling_directions(from, to)
    if (to.x > from.x)
      return [[1, 0]]
    else
      return [[-1, 0], [-2, 0]]
    end
  end

  def leaving_position_safe(safepos)
    each_piece do |position, piece|
      if piece.color == @turn
        return false if pseudolegal_move(position, safepos )
      end
    end
  end

  def get_pos(v)
    case v.size
    when 1
      v[0]
    when 2
      Vector.new(v[0], v[1])
    end
  end

  def execute_move(from, to)
    if promotion(from, to)
      self[to] = Piece.new(@turn, @promotion_piece)
    else
      self[to] = self[from]
    end

    self[from] = nil
  end
end

class MoveGenerator
  def intializer(board, &valid)
    @board = board
    if block_given?
      @valid_move = valid
    else
       @valid_move = lamda do |from, to|
         if @board.is_valid(to) and @board.legal_move(from, to)
           return to
         end
       end
     end
   end

   def unstalled
     @fast = true
     found = catch(:move_found) do
       @board.each_piece do |position, piece|
         if piece.color == @board.turn
           can_move(position)
         end
       end
     end
     found == true
   end

   def generate_all
     @fast = false
     move_list = []
     @board.each_piece do |position, piece|
       if piece.color == @board.turn
         move_list += can_move(position)
       end
     end
     move_list
   end

   def can_move(from)
     piece = @board[from]
     move_list = []
     return [] unless piece

     case piece.type
     when :king
       generate+directions.each do |direction|
         move = got_move(from, from + direction)
         move_list << move if move
       end

     when :queen
       generate_directions.each do |direction|
         move_list += generate_slide(from, direction)
       end
     when :rook
       [[1,0], [-1, 0], [0,1], [0, -1]].each do |direction|
         move_list += generate_slide(from, direction)
       end

     when :knight
       [[2,1], [2,-1], [-2, 1], [-2, -1], [1,2], [1, -2], [-1, 2], [-1, -2]].each do |jump|
         move = got_move(from, from + jump)
         move_list << move if move
       end

     when :pawn
       [[0, @board.pawn_dir], [0, @board.pawn_dir*2], [1, @board.pawn_dir], [-1, @board.pawn_dir]].each do |jump|
         move = got_move(from, from + jump)
         move_list << move if move
       end
     end

     return move_list
   end

  private

    def generate_slide(from, direction)
      move_list = []
      pos = from
      while @board.is_valid(pos += direction) do
        move = got_move(from, pos)
        move_list << move if move
      end
      move_list
    end

    def generate_directions
      dirs = []
      (-1..1).each do |x|
        (-1..1).each do |y|
          dirs << [x,y] unless x == 0 and y == 0
        end
      end
      return dirs
    end

    def got_move(from, to)
      if move = @valid_move[from, to]
        throw(:move_found, true)if @fast
        move
      else
        false
      end
    end
  end

  module UI
    def ask_move
      @promotion_piece = nil
      loop do
        print ": "
        intput = gets
        raise "no move" unless input
        csae input.chomp
      when /^\s*$/
        return nil
      when /^(\d)(\d)\s*(\d)(\d)$/
        return Vector.new($1,to_i, $2.to_i), Vector.new($3.to_i, $4.to_i)
      when /^([RNBQK]?)([a-h1-8]?)(x?)([a-h])([1-8])(-[RNBQK])?[#+]?$/
        piece_type = letter2piece($1)
        prom = $6
        to = Vector.new($4[0]- 'a'[0], 8 - $5.to_i)
        sp = @board.possible_starting_ponts(piece_type, to, $3 == 'x')
        unless $2.nil? or $2 == ""
          letter = $2
          if letter =~ /[a-h]/
            check = lambda do |possbile_from|
              possible_from.x == letter[0] - 'a'[0]
            end
          else
            check = lamda do |possible_from|
              possbile_from.y == 8 - letter.chars_to_i
            end
          end
          sp.reject! do |possbile_from|
            not check[possible_from]
          end
        end

        case sp.size
        when 0
          say "incorrect notation"
        when 1
          from = sp.first
        else
          say "ambiguous notation"
        end

        if from
          if piece_type == :pawn and to.y == @board.rank(8)
            @promotion_piece = letter2piece($5[1,1])
          end

          if from
            return from, to
          end
        end

      when "O-O"
        pos = @board.king_starting_position
        return pos, pos + [2, 0]
      when "O-O-O"
        pos = @board.queen_rook_starting_position
        return pos, pos - [2, 0]
      end
    end
  end

  def letter2piece(letter)
    case letter
    when 'R'
      return :rook
    when 'N'
      return :knight
    when 'B'
      return :bishop
    when 'Q'
      return :queen
    when 'K'
      return :king
    else
      return :pawn
    end
  end

  def ask_promotion_piece
    return @promotion_piece if @promotion_piece
    print "promote to (default: queen): "
    case gets.chomp!
    when "rook" || 'r'
      return :rook
    when "knight" || 'n'
      return :knight
    when "bishop" || 'b'
      return :bishop
    else
      return :queen || 'q'
    end
  end

  def say(msg)
    puts msg.to_s.gsub(/_/) {' '}
  end

  def show_board
    say "turn : #{board.turn.to_s}"
    (0... / board.size.y).each do |y|
      (0... / board.size.x).each do |x|
        piece = @board[x,y]
        if piece
          s = piece.type_initial
          s.upcase! if (piece.color == :white)
          print s, ' '
        else
          print ' '
        end
      end
      print "\n"
    end
    print "\n"
  end
end

class ChessGame
  attr_reader :board
  include UI

  def initialize
    @board = Board.new(8, 8)
    @board.promotion_piece = :queen

    (0...8).each do |x|
      @board[x, 1] = Piece.new( :blace, :pawn)
      @board[x, 6] = Piece.new( :white, :pawn)
    end

    @board[0, 0] = Piece.new( :black, :rook)
    @board[1, 0] = Piece.new( :black, :knight)
    @board[2, 0] = Piece.new( :black, :bishop)
    @board[3, 0] = Piece.new( :black, :queen)
    @board[4, 0] = Piece.new( :black, :king)
    @board[5, 0] = Piece.new( :black, :bishop)
    @board[6, 0] = Piece.new( :black, :knight)
    @board[7, 0] = Piece.new( :black, :rook)

    @board[0, 7] = Piece.new( :white, :rook)
    @board[1, 7] = Piece.new( :white, :knight)
    @board[2, 7] = Piece.new( :white, :bishop)
    @board[3, 7] = Piece.new( :white, :queen)
    @board[4, 7] = Piece.new( :white, :king)
    @board[5, 7] = Piece.new( :white, :bishop)
    @board[6, 7] = Piece.new( :white, :knight)
    @board[7, 7] = Piece.new( :white, :rook)

  end

  def play
    while (state = @board.game_state) == :in_game
      begin
        move
      rescue RuntimeError => err
        print "\n"
        if err.message == "no move"
          say :exiting
        else
          say err.message
        end
        return
      end
      show_board
      say_state
    end

    def move
      loop do
        say ""
        show_board
        from, to = ask_move
        raise "no move" unless from
        if @board.is_valid(from) and @board.is_valid(to) and @board.legal_move(from, to)
          if @board.promotion(from, to)
            @board.ask_promotion_piece = ask_promotion_piece
          end
          @board.move(from, to)
          break
        else
          say :invalid_move
        end
      end
    end
  end

  @game = ChessGame.new
  @game.play
  
