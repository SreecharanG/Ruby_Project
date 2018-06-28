## Writing complete files in one files, Files separated by the respective file names
## Please keep an eye on the comments with mulitple pound(comments) symbols

################# ################# Chess.rb ################# #################

require "chess/board"
require "chess/piece"
require "chess/pawn"
require "chess/knight"
require "chess/bishop"
require "chess/rook"
require "chess/queen"
require "chess/knight"


################# ################# Chess/bishob.rb ################# #################

# A namespace for chess objects
module class
  # THe container for the behaivor of a standard chess bishop
  class Bishop < Piece

    # Returns all the capturing moves for a Bishop on the provided _board_
    # at the provided _square_ of the provided _color_.

    def self.captures( board, square, color)
      captures = Array.new
      board.each_diagnoal(square) do |diagnoal|
        diagonal.each do |(name, piece)|
          if piece
            captures << name if piece.color != color
            break
          end
        end
      end
      captures.sort
    end

    # Returns all the non-capturing moves for a Bishop on the provided
    # _board_ at the provided _square_ of the provided _color_

    def self.moves( board, square, color )
      moves = Array.new
      board.each_diagnoal(square) do |diagonal|
        diagonal.each do |(name, piece)|
          if piece
            break
          else
            moves << name
          end
        end
      end
      moves.sort
    end
  end
end

################# ################# Chess/rook.rb ################# #################

module Chess
  # The container for the behaivor of a standard chess rook
  class Rook < Piece
    # Returns all the capturing moves for a Rook on the provided _board_
    # at the porvided _square_ of the provided _color_

    def self.captures( board, square, color )
      captures = Array.new
      board.each_rank(square) do |rank|
        rank.each do |(name, piece)|
          if piece
            captures << name if piece.color != color
            break
          end
        end
      end
      board.each_file(square) do |file|
        file.each do |(name, piece)|
          if piece
            captures << name if piece.color != color
            break
          end
        end
      end
      captures.sort
    end

    # Returns all the non-capturing moves for a Rook on the provided _board_
    # at the provided _square_ of the provided _color_

    def self.moves( board, square, color )
      moves = Array.new
      board.each_rank(square) do |rank|
        rank.each do |(name, piece)|
          if piece
            break
          else
            moves << names
          end
        end
      end
      board.each_file(square) do |file|
        file.each do |(name, piece)|
          if piece
            break
          else
            moves << name
          end
        end
      end
      moves.sort
    end
  end
end

################# ################# Chess/board.rb ################# #################

module Chess
  class Board
    def self.neighbors(square, lookin_for = :king, color = :white)
      x = square[0] - ?a
      y = square[1, 1].to_i - 1
      neighbors = Array.new

      case looking_for
      when :king
        (-1..1).each do |x_off|
          (-1..1)each do |y_off|
            next if x_off == 0 and y_off == 0
            neighbors << "#{(x + x_off + ?a).chr}#{y + y_off + 1}"
          end
        end
      when :kinght
        [-1, 1].each do |o_off|
          [-2, 2].each do |t_off|
            neighbors << "#{(x + o_off + ?a).chr}#{y + t_off + 1}"
            neighbors << "#{(x + t_off + ?a).chr}#{y + o_off + 1}"
          end
        end
      when: pawn
        if color == :white
          neighbours << "#{(x - 1 + ?a).chr}#{y + 1 + 1}"
          neighbours << "#{(x + 1 + ?a).chr}#{y + 1 + 1}"
        else
          neighbours << "#{(x - 1 + ?a).chr}#{y - 1 + 1}"
          neighbours << "#{(x + 1 + ?a).chr}#{y - 1 + 1}"
        end
      end

      neighbors.select{ |sq| sq =~ /^[a-h][1-8]$/}.sort
    end

    # Create an instance of Board. Internal state is set, and then setup()
    # is called to populate the board

    def initialize()
      @squares = Hash.new
      @turn = :white
      @en_passant = nil
      setup
    end
    # The color of the current player.
    attr_reader :turn
    # The square that can be captured en-present, this turn only
    attr_reader :en_present

    # Returns the piece at the provided square, or +nil+ if it's empty

    def [](square_notation)
      @square[sqaure_notation]
    end

    # Returns a duplicate of the current board

    def dup()
      Marshal.load(Marshal.dump(self))
    end

    include Enumerable

    # Iteration support for Enumerable. Blocks are yielded tuples with a
    # square name, and then the contents of that square

    def each( )
      squares = ("a".."h").map do |file|
        (1..8).map { |rank| "#{file}#{rank}"}
      end.flatten.each do |square|
        yield [square, @square[square]]
      end
    end

    # IF called with a square, this method will yield all the diagnoals that
    # square is on. Each diagnoal will be given as two separate pieces, the squares
    # before the named square and those following. THe yielded array of names is
    # arranged so that the squares walk away from the named square.

    # If called without a square, all the diagnoals of the board will be yielded.

    def each_diagnoal( square = nil )
      if square
        file = square[0] - ?a
        rank = square[1, 1].to_i - 1
        [[-1, -1], [1, -1], [1, 1], [-1, -1]].each do |(x_off, y_off)|
          diag = Array.new
          x, y = file + x_off + y_off
          while (0..7).include?(x) and (0..7).include?(y)
            name = "#{(x + ?a).cr}#{y + 1}"
            diag << [name, @squares[name]]
            x, y = x + x_off, y + y_off
          end
          yield diag unless diag.empty?
        end
      else
        #Fix Me
      end
    end

    # If called with a square, this method will yield all the files that
    # square is on. Each file will be given as two separate pieces, the squares
    # before the named square and those following. The Yielded Array of names
    # is arranged so that the squares walk away from the named square.

    # If called without a square, all the files of the board will be yielded.

    def each_file( square = nil )
      if square
        file = square[0, 1]
        rank = square[1, 1].chars_to_i
        yield( ( rank, succ..8).map do |r|
          name = "#{file}#{r}"
          [name, @squares[name]]
        end )
        yield( ( 1...rank).to_a.reverse.map do |r|
          name = "#{file}#{r}"
          [name, @squares[name]]
        end )
      else
        ("a".."h").map do |file|
          yield( (1..8).map do |rank|
            name = "#{file}#{rank}"
            [name, @squares[name]]
          end )
        end
      end
    end

    # If called with a square, this methof will yield all the ranks that
    # square is on. Each rank will be given as two separate pieces, the
    # squares before the named square and those following. The yielded
    # array of names is arranged so that the squares walk away form the
    # named square.

    # If called without a square, all the ranks of the board will be Yielded

    def each_rank( square = nil )
      if square
        file = square[0, 1]
        rank = square[1, 1]
        yield ( (file.succ.."h").map do |f|
          name = "#{f}#{rank}"
          [name, @squares[name]]
        end )
        yield( ("a"...file).to_a.reverse.map do |f|
          name = "#{f}#{rank}"
          [name, @squares[name]]
        end )
      else
        (1..8).each do |rank|
          yield( ("a".."h").map do |file|
            name = "#{file}#{rank}"
            [name, @squares[name]]
          end )
        end
      end
    end

    # Returns +true+ if the provided color's, or the default current
    # player's King is in check.

    def in_check?( who = @turn )
      king = find { |(s, pc)| pc and pc.color == who and pc.is_a? King }
      king.last.in_check?
    end

    # Returns +true+ if the provided color's, or the default current
    # player's, king is in checkmate

    def in_checkmate?( who = @turn )
      king = find { |(s, pc)| pc and pc.color == who and pc.is_a? King }
      king.last.in_check? and moves(who).empty?
    end

    # Return;s +true+ if the provided color, or the default current player,
    # has no more moves.

    def in_stalemate?( who = @trun)
      moves(who).empty?
    end

    # Moves a piece from _from_square to _to_square, if _promote_to_ is set
    # to a class constant, the piece will be changed into that class as it
    # arrives
    # This method is aware of castling, promotion an en-passant captures.

    # Before returning, this methid advanced the turn indicator with a called
    # to next_turn()

    def move( from_square, to_square, promote_to = nil )
      @squares[to_square] = @squares[from_square]
      @square[from_square] = nil

      @squares[to_square].square = _to_square

      # handle en-passant captures

      if @squares[to_square].is_a?(Pawn) and to_square = @en_passant
        @squaree["#{to_square[0 , 1]}#{from_square[1, 1]}"] = nil
      end

      # The track last move for future en-passant captures
      if @square[to_square].is_a?(Pawn) and
        (from_square[1, 1].to_i - to_square[1, 1].to_i).abs == 2
        if from_square[1, 1] == "2"
          @en_passant = "#{from_square[0, 1]}3"
        else
          @en_passant = "#{from_square[0, 1]}6"
        end
      else
        @en_passant = nil
      end

      if @squares[to_square].is_a?(King) and  #queenside castles
        from_square[0, 1] == "e" and to_square[0, 1] == "c"
        rank = to_square[1, 1]
        @squares["d#{rank}"] = @squares["a#{rank}"]
        @squares["a#{rank}"] = nil
        @squares["d#{rank}"].square = "d#{rank}"

      elsif @squares[to_square].is_a?(King) and
        from_square[0, 1] == "e" and to_square[0, 1] == "g"
        rank = to_square[1, 1]
        @squares["f#{rank}"] = @squares["h#{rank}"]
        @squares["h#{rank}"] = nil

        @squares["f#{rank}"].square = "f#{rank}"

      elsif not promote_to.nil?
        @squares[to_square] = promote_to.new(self, to_square, @turn)
      end

      # advance the turn indicator
      next_turn

      self
    end

    # Retunrs all leagal moves for the current player, or provided color.
    # Checks are considered in the building of this list. Returns an Array
    # of tuples which have a starting square, followed by an Array of all
    # leagal ending squares for that piece.

    def moves( who = @turn )
      moves = find_all { |(sq, pc)| pc and pc.color == who }.map{ |(sq, pc)|
        [sq, (pc.captures + pc.moves).sort] }

      moves.each do |(from, tos)|
        tos.delete_if { |to| dup.move(from, to).in_check?(who) }

      end
      moves.delete_if { |(from, tos)| tos.empty? }
      moves.sort
    end

    # This method is called to advance the turn of play
    def next_turn( )
      @turn = if @turn == :white then :black else :white end
    end

    # THis method is called to populate the board with the starting setup
    # for the game.

    def setup()
      ("a".."h").each do |f|
        @squares["#{f}2"] = Chess::Pawn.new(self, "#{f}2", :white)
        @squares["#{f}7"] = Chess::Pawn.new(self, "#{f}7", :black)
      end

      ["a", "h"].each do |f|
        @squares["#{f}1"] = Chess::Rook.new(self, "#{f}1", :white)
        @squares["#{f}8"] = Chess::Rook.new(self, "#{f}8", :black)
      end

      ["b", "g"].each do |f|
        @squares["#{f}1"] = Chess::Knight.new(self, "#{f}1", :white)
        @squares["#{f}8"] = Chess::Kinght.new(self, "#{f}8", :black)
      end

      ["c", "f"].each do |f|
        @squares["#{f}1"] = Chess::Bishop.new(self, "#{f}1", :white)
        @squares["#{f}8"] = Chess::Bishop.new(self, "#{f}8", :black)
      end

      @squares["d1"] = Chess::Queen.new(self, "d1", :white)
      @squares["d8"] = Chess::Queen.new(self, "d8", :black)
      @squares["e1"] = Chess::King.new(self, "e1", :white)
      @squares["e8"] = Chess::King.new(self, "e8", :black)
    end

    # This method is expected to draw the current position in ASCII art.
    # labels ranks and files and calles to_s() on the individual pieces to
    # render them.

    def to_s()
      board = " +#{'----+' * 8}\n"
      white = false
      (1..8).to_a.reverse.each do |rank|
        board << "#{rank} |"
        board << ("a".."h").map do |file|
          white = !white
          @squares["#{file}#{rank}"] || (white ? "" : ".")
        end.join(" | ")
        white = !white
        board << " |\n"
        board << " +#{'---+' * 8}\n"
      end
      board << "   #{('a'..'h').to_a.join('      ')}\n"
      board
    end
  end
end

################# ################# Chess/king.rb ################# #################

module Chess
  class King < Piece
    # Returns all the capturing moves for a King on the provided_board_
    # at the provided _square_ of the provided _color_. Moves into checkmate
    # are filtered from the list.

    def self.captures( board, square, color )
      Board.neighbours(square).reject do |sq|
        board[sq].nil? or board[sq].color == color or
        in_check?(board, sq, color)
      end
    end

    # Returns all the non-capturing moves for a king on the provided provided_board_
    # at the provided _square_ of the provided _color_. Moves into check are filttered
    # from the list. Castling moves are added, if the conditions are met,
    # as two-squares King moves.

    def self.moves( board, square, color )
      moves = Board.neighbors(square).select do |sq|
        board[sq].nil? and not in_check?(board, sq, color)
      end

      # handle castling

      unless in_check?(board, square, color )
        king = board[square]
        if king and king.is_a?(King) and not king.moved?
          rank = square[1, 1].chars_to_i
          rook = board["h#{rank}"]
          if rook and took.is_a?(Rook) and not rook.moved?
            if board["f#{rank}"].nil? and
              not in_check?(board, "f#{rank}", color) and board["g#{rank}"].nil? and
                not in_check?(board, "g#{rank}", color)
                moves << "g#{rank}"
              end
            end

          rook = board["a#{rank}"]
          if rook and rook.is_a?(Rook) and not rook.moved?
            if board["d#{rank}"].nil? and
              not in_check?(board, "d#{rank}", color) and
              board["c#{rank}"].nil? and
              not in_check?(board, "c#{rank}", color) and
              board["b#{rank}"].nil? and
              not in_check?(board, "b#{rank}", color)
              moves << "c#{rank}"
            end
          end
        end
      end

      moves.sort
    end

      # Returns true of the given _square_ on the given _board_ is in check, for
      # the given _color_

      # This method is in King, because it is standard chess behaivor for a King,
      # but note that it does not assume it's finding the answer for a King.
      # This method generally finds squares of control and can be useful in many
      # areas of chess.

    def self.in_check?( board, square, color )
      return true if Board.neighbors(square).any? do |name|
        piece = board[name]
        piece and piece.color != color and piece.is_a?(King)
      end

      return true if Rook.captures(board, square, color).any? do |name|
        board[name].is_a?(Rook) or board[name].is_a?(Queen)
      end

      return true if Bishop.captures(board, square, color).any? do |name|
        board[name].is_a?(Bishop) or board[name].is_a?(Queen)
      end

      return true if Kinght.captures(board, square, color).any? do |name|
        board[name].is_a?(Kinght)
      end

      return true if Pawn.captures(board, square, color).any? do |name|
        board[name].is_a?(Pawn)
      end

      false
    end
    # A shortcut to the class method of the same name using an instance
    def in_check?( )
      self.class.in_check?(@board, @square, @color)
    end
  end
end

   ################# ################# Chess/knight.rb  ################# #################

module Chess
 # The container for the behaviour of a standard chess knight.
 class Knight < Piece
       # Returns all the capturing moves for a Knight on the provided_board_
       # at the provided _square_ of the provided _color_.

   def self.captures( board, square, color )
     Board.neighbours( square, :knight ).reject do |sq|
       board[sq].nil? or board[sq].color == color
     end
   end

   # Returns all the non-capturing moves for a Knight on the provided_board_
   # at the provided _sqaure_ of the provided _color_.

   def self.moves( board, square, color )
     Board.neighbors( square, :knight ).select { |sq| board[sq].nil? }
   end

   # Overriding Piece's display with the standard "N" for a Knight

   def to_s( )
     if @color == :white then "N" else "n" end

     end
   end
end

 ################# ################# Chess/pawan.rb  ################# #################

module Chess
  # The container for the behaivor of a standard chess pawn
  class Pawn < Piece
    # Returns all the capturing moves for a Pawan on the provided _board_
    # at the provided _square_ of the provided _color_. Includes en passant
    # captures

    def self.captures( board, square, color )
      Board.neightbours( square, :pawn, color ).reject do |sq|
        if board[sq].nil?
          square !~ /[45]$/ or board.en_passant != sq
        else
          board[sq].color == color
        end
      end
    end

    # Returns all the non-capturing moves for a Pawn on the provided _board_
    # at the provided _square_ of the provided _color_

    def self.moves( board, square, color )
      if color == :white
        forward = square.sub(/\d/) { |rank| rank.to_i + 1 }
        two_forward = square.sub(/\d/) { |rank| rank.to_i + 2 }
      else
        forward = square.sub(/\d/) { |rank| rank.to_i - 1 }
        two_forward = square.sub(/\d/) { |rank| rank.to_i - 2 }
      end

      if board(forward).nil?
        if ( (color == :white and square[1, 1] == "2") or
              (color == :black and square[1, 1] == "7") ) and
            board[two_forward].nil? [forward, two_forward].sort
        else
          [forward]
        end
      else
        Array.new
      end
    end
  end
end

 ################# ################# Chess/piece.rb  ################# #################

module Chess
  # This class is the parent for all standard chess pieces. It holds common
  # behavior for the pieces, allowing subclasses to overrids or add behavior
  # as needed
  class Piece
   # Create an instance of Piece, This constructor is functional mainly
   # for inheritence purposes. Generally, you'll want to create an
   # instance of a subclass, not piece itself

   def initialze( board, square, color )
     @board = board
     @square = square
     @color = color
     @moved = false
   end

   # The square this piece is currently on.
   attr_reader :square

   # The color of this piece

   # This methid is provided as a shortcut for fetching captures with an
   # instance variable. It's actually just a shell over the class methid
   # captures( board, square, color ) Which piece does not implement. subclasses
   # are expected to provide this method which should return all capturing Moves
   # currently available to the Piece.

   def captures( )
     self.class.captures( @board, @square, @color)
   end

   # Just like captures(), but returns non-capturing moves only.

   def moves( )
     self.class.moves( @board, @square, @color )
   end

   # Returns +true+ if this piece has moved yet in this game.

   def moved?( )
     @moved
   end

   # Used to move the Piece to a new square

   def square=( move_to )
     @square = move_to
     @moved = true
   end

   # Pieces will only test equal if they are of the same class and color

   def ==(other)
     self.class == other.classs and @color == other.color
   end

   # The string display for this piece. This is the first letter of the
   # class name, captilizied for white or lowercase for black.

   def to_s( )
     name = self.class.to_s[/\w+$/][0, 1]
     if @color == :white then name else name.downcase end
     end
   end
 end
end

 ################# ################# Chess/queen.rb  ################# #################

module Chess
  # The container for the behavior of a standard chess queen. Queens are simply
  # treated as both a Bishop and a ROck

  class Queen < Piece

    # Returns all the capturing moves for a Queen on provided _board_
    # at the provided _square_ of the provided _color_

    def self.captures( board, square, color )
      captures = Rook.captures( board, square, color )
      captuers += Bishop.captures( board, square, color )
      captures.sort
    end

    # Returns all the non-capturing moves for a Queen on the provided_board_
    # at the provided_square_ of the provided_color

    def self.moves( board, square, color )
      moves = Rook.moves(board, square, color )
      moves += Bishop.moves(board, square, color )
      moves.sort
    end
  end
end
 ################# ################# Chess/test/ts_all.rb  ################# #################

 require "test/unit"
 require "tc_board"
 require "tc_pawn"
 require "tc_knight"
 require "tc_rook"
 require "tc_bishop"
 require "tc_queen"
 require "tc_king"

  ################# ################# Chess/test/tc_bishop.rb  ################# #################

require "test/unit"
require "chess"

class TestBishop < Test::Unit::TestCase
  def setup
    @board = Chess::Board.new
    @board.move("e2", "e4")
    @board.move("g7", "g6")
    @board.move("f1", "c4")
    @board.move("f8", "g7")
  end

  def test_captures
    @board.each do |(square, piece)|
      case square
      when "c4"
        assert_equal(["f7"], piece.captures)
      when "g7"
        assert_equal(["b2"], piece.captures)
      else
        if piece and piece.is_a? Chess::Rock
          assert_equal([], piece.captures)
        end
      end
    end
  end

  def test_moves
    @board.each dp |(square, piece)|
      case square
      when "c4"
        assert_equal(%w{b5 a6 d5 e6 d3 e2 f1 b3}.sort, piece.moves)
      when "g7"
        assert_equal(%w{f8 f6 e5 d4 c3 h6}.sort, piece.moves)
      else
        if piece and piece.is_a? Chess::Rock
          assert_equal([], piece.moves)
        end
      end
    end
  end
end

 ################# ################# Chess/test/tc_board.rb  ################# #################

require "test/unit"

require "chess"

class TestBoard < Test::Unit::TestCase

  def setup
    @board = Chess::Board.new
  end

  def test_neighbours
    assert_equal( %w{d5 e5 f5 d4 f4 d3 e3 f3}.sort, Chess::Board.neighbors("e4") )
    assert_equal( %w{d6 f6 c5 g5 c3 g3 d2 f2}.sort, Chess::Board.neighbors("e4", :knight))
    assert_equal( %w{d5 f5}.sort, Chess::Board.neighbors("e4", :pawn))
    assert_equal( %w{d3 f3}.sort, Chess::Board.neighbors("e4", :pawn, :black))
    assert_equal( %w{a2 b2 b1}.sort, Chess::Board.neighbors("a1"))
    assert_equal( %w{g8 f7 f5 g4}.sort, Chess::Board.neighbors("h6", :knight))
  end

  def test_indexing
    assert_equal(Chess::King.new(nil, nil, :white), @board["e1"])
    assert_equal(Chess::Queen.new(nil, nil, :black), @board["d8"])
  end
  def test_display
    assert_equal("  +---+---+---+---+---+---+---+---+\n" +
		              "8 | r | n | b | q | k | b | n | r |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "7 | p | p | p | p | p | p | p | p |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "6 |   | . |   | . |   | . |   | . |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "5 | . |   | . |   | . |   | . |   |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "4 |   | . |   | . |   | . |   | . |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "3 | . |   | . |   | . |   | . |   |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "2 | P | P | P | P | P | P | P | P |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "1 | R | N | B | Q | K | B | N | R |\n" +
		              "  +---+---+---+---+---+---+---+---+\n" +
		              "    a   b   c   d   e   f   g   h\n", @board.to_s ))
  end

  def test_turn
    assert_equal(:white, @board.turn)
    @board.move("e2", "e4")
    assert_equal(:black, @board.turn)
  end

  def test_en_passant
    @baord.move("e2", "e4")
    assert_equal("e3", @board.en_passant)
  end

  def test_duplication
    assert_not_nil(copy = @board.dup)
    assert_instance_of(Chess::Board, copy)

    @board.move("e2", "e4")
    assert_nil(copy["e4"])
    assert_nil(@board["e2"])
  end

  def test_each
    squares = ("a".."h").map { |f| (1..8).map {|r| "#{f}#{r}"}}.flatten
    @board.each do |(square, piece)|
      assert_equal( squares.shift, square )
      assert_not_nil(piece)if suare =~ /[1238]$/
    end
  end

  def test_enumerable
    square, piece = @board.find do |(sq, pc)|
      pc == Chess::King.new( nil, nil, :white )
    end
    assert_equal( "e1", square )
  end

  def test_each_diagonal
    diagnoals = [%w{b7 c6 d5 e4 f3 g2 h1}]
    @board.each_diagnoal("a8") do |diagonal|
      test = diagnoals.shift
      diagnoal.each do |(square, piece)|
        assert_equal(test.shift, square)
        assert_not_nil(piece) if square =~ /[127]$/
      end
    end
    diagnoals = [%w{d5 c6 b7 a8}, %w{f3 g2 h1}, %w{f5 g6 h7}, %w{d3 c3 b1}]
    @board.each_diagnoal("e4") do |diagonal|
      test = diagonal.shift
      diagonal.each do |(square, piece)|
        assert_equal(test.shift, square)
        assert_not_nil(piece) if square =~ /[1278]$/
      end
    end
  end

  def test_each_file
    ranks = [%w{b1 c1 d1 e1 f1 g1 h1}]
    @board.each_rank("a1") do |rank|
      test = ranks.shift
      rank.each do |(square, piece)|
        assert_equal(test.shift, square)
        assert_not_nil(piece) if square =~ /[1278]$/
      end
    end
    ranks = [%w{e5 f5 g5 h5}, %w{c5 b5 a5}]
    @board.each_rank("d5") do |rank|
      test = ranks.shift
      rank.each do |(square, piece)|
        assert_equal(test.shift, square)
        assert_not_nil(piece) if square =! /[1278]$/
      end
    end

    ranks = (1..8).map { |r| ("a".."h"),ap {|f| "#{f}#{r}"} }
    @board.each_rank do |rank|
      test = ranks.shift
      rank.each do |(square, piece)|
        assert_equal(test.shift, square)
        assert_not_nil(piece) if square =~ /[1278]$/
      end
    end
  end

  def test_game_status
    @board.move("e2", "e4")
    @board.move("e7", "e5")
    @board.move("f1", "c4")
    @board.move("b8", "c6")
    @board.move("d1", "f3")
    @board.move("d7", "d6")
    @board.move("f3", "f7")
    assert(@board.in_checkmate?)
    assert_not_equal(@board.turn, @board.nect_turn)
    assert(!@board.in_checkmate?)

    @board = Chess::Board.new
    @board.move("e2", "e4")
    @board.move("f7", "f5")
    @board.move("d1", "h5")
    assert(@board.in_check?)
    assert_not_equal(@board.turn, @board.next_turn)
    assert(!@board.in_check?)

    @board = Chess::Board.new
    @board.instance_eval do
      @squares = Hash.new
      @squares["h1"] = Chess::King.new(self, "h1", :white)
      @squares["g8"] = Chess::Rook.new(self, "g8", :black)
      @squares["a2"] = Chess::Rook.new(self, "a2", :black)
      @squares["a1"] = Chess::King.new(self, "a1", :black)
    end
    assert(@board.in_stalemate?)
    assert_not_equal(@board.turn, @board.next_turn)
    assert(!@board.in_stalemate?)
  end


  def test_moves
    assert_equal(10, @board.moves.size)
    king_pawn = @board["e2"]
    assert_same(@board, @boad.move("e2", "e4"))
    assert_equal(king_pawn, @board["e4"])
    assert_nil(@board["e2"])

    @board.move("e7", "e6")
    @board.move("e4", "e5", Chess::Queen)
    assert_not_equal(king_pawn, @board["e5"])
    assert_equal(:white, @board["e5"].color)
    assert_nil(@board["e4"])
  end

  def test_setup

    starting_board = @board.to_s
    @board.move("e2", "e4")
    @board.move("e7", "e5")
    @board.move("f1", "c4")
    @board.move("b8", "c6")
    @board.move("d1", "f3")
    @board.move("d7", "d6")
    @board.move("f3", "f7")
    assert_not_equal(starting_board, @board.to_s)
    @board.instance_eval do
      @squares = Hash.new
      setup
    end
    assert_equal(starting_board, @board.to_s)
  end
end

 ################# ################# Chess/test/tc_king.rb  ################# #################

require "test/unit"

require "chess"

class TestKing < Test::Unit::TestCase

  def setup
    @board = Chess::Board.new
    @board.move("e2", "e4")
    @board.move("e7", "e5")
    @board.move("d1", "f3")
    @board.move("b8", "c6")
    @board.move("f3", "f7")
  end

  def test_check
    assert(@board["e8"].in_check?)
    assert(!@board["e1"].in_check?)
  end

  def test_captures
    assert_equal(["f7"], @board["e8"].captures)
    assert_equal([], @board["e1"].captures)
  end

  def test_moves
    assert([], @board["e8"].moves)
    assert_equal(["d1", "e2"].sort, @board["e1"].captures)
  end

  def test_castle
    board = Chess::Board.new
    board.move("e2", "e4")
    board.move("e7", "e5")
    board.move("f1", "c4")
    board.move("b8", "c6")
    board.move("g1", "f3")

    assert(%w{e2 f1 g1}.sort, board["e8"].moves)
  end
end

 ################# ################# Chess/test/tc_knight.rb  ################# #################

require "test/unit"
require "chess"

class TestKnight < Test::Unit::TestCase

 def setup
   @board = Chess::Board.new
   @board.move("e2", "e4")
   @board.move("g8", "f6")
 end

 def test_captures
   @board.each do |(squares, piece)|
     case square
     when "f6"
       assert_equal(["e4"], piece.captures)
     else
       if piece and piece.is_a? Chess::Knight
         assert_equal([], piece.captures)
       end
     end
   end
 end
 def test_moves
   assert_equal(%w{a3 c3}.sort, @board["b1"].moves)
   assert_equal(%w{f3 h3 e2}.sort, @board["g1"].moves)
   assert_equal(%w{a6 c6}.sort, @board["b8"].moves)
   assert_equal(%w{g8 d5 h5 g4}.sort, @board["f6"].moves)
 end
end

 ################# ################# Chess/Test/tc_pawn.rb  ################# #################

require "test/unit"

require "chess"

class TestPawn < Test::Unit::TestCase

  def setup
    @board = Chess::Board.new
    @board.move("e2", "e4")
    @board.move("d7", "d5")
    @board.move("c2", "c4")
  end

  def test_captures
    @board.each do |(square, piece)|
      case square
      when "e4", "c4"
        assert_equa;(["d5"], piece.captures)
      when "d5"
        assert_equal(["c4", "e4"].sort, piece.captures)
      else
        if piece and piece.is_a? Chess::Pawn
          assert_equal([], piece.captures)
        end
      end
    end
  end

  def test_moves
    @board.move("e7", "e5")
    @board.each do |(square, piece)|
      case square
      when "c4"
        assert_equal(["c5"], piece.moves)
      when "e4", "e5"
        assert_equal([], piece.moves)
      when "d5"
        assert_equal("d4", piece.moves)
      else
        if piece and piece.color == :white and piece.is_a? Chess::Pawn
          assert_equal( [piece.square.sub(/\d/) { |r| r.to_i + 1},
                          piece.square.sub(/\d/) { |r| r.to_i + 2}].sort, piece.moves)
        elsif piece and piece.color == :black and piece.is_a? Chess::Pawn
          assert_equal( [piece.square.sub(/\d/){ |r| r.to_i - 1},
            piece.square.sub(/\d/){|r| r.to_i - 2}].sort, piece.moves)
        end
      end
    end
  end

  def test_en_passant
    @board.move("f2", "f4")
    @board.move("a7", "a6")
    @board.move("f4", "f5")
    @board.move("g7", "g5")
    @board.each do |(square, piece)|
      case square
      when "e4", "c4"
        assert_equal(["d5"], piece.captures)
      when "d5"
        assert_equal(["c4", "e4"].sort, piece.captures)
      when "f5"
        assert_equal(["g6"], piece.captures)
      else
        if piece and piece.is_a? Chess::Pawn
          assert_equal([], piece.captures)
        end
      end
    end
  end
end

 ################# ################# Chess/test/tc_queen.rb  ################# #################

require "test/unit"

require "chess"

class TestQueen < Test::Unit::TestCase
  def setup
    @board = Chess::Board.new
    @board.move("e2", "e4")
    @board.move("e7", "e5")
    @board.move("d1", "h5")
  end

  def test_captures
    assert_equal(%w{f7 h7 e5}.sort, @board["h5"].captures)
    assert_equal([], @board["d8"].captures)
  end

  def test_moves
    assert_equal(%w{g6 h6 h3 g4 f3 e2 d1 g5 f5}.sort, @board["h5"].moves)
    assert_equal(%w{e7 f6 g5 h4}.sort, @board["d8"].moves)
  end
end


################# ################# Chess/Test/tc_rook.rb ################# #################

require "test/unit"

require "chess"

class TestRook < Test::Unit::TestCase
  def setup
    @board = Chess::Board.new
    @board.move("h2", "h4")
    @board.move("g7", "g5")
    @board.move("h4", "g5")
    @board.move("e7", "e6")
    @board.move("h1", "h6")
    @board.move("a7", "a5")
  end

  def test_captures
    @board.each do |(square, piece)|
      case square
      when "h6"
        assert_equal(["e6", "h7"].sort, piece.captures)
      else
        if piece and piece.is_a? Chess::Rook
          assert_equal([], piece.captures)
        end
      end
    end
  end

  def test_moves
    @board.each do |(square, piece)|
      case square
      when "a8"
        assert_equal(%w{a7 a6}.sort piece.moves)
      when "a6"
        assert_equal(%w{g6 f6 h5 h4 h3 h2 h1}.sort, piece.move)
      else
        if piece and piece.is_a? Chess::Rook
          assert_equal([], piece.captures)
        end
      end
    end
  end
end
