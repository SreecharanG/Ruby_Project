require 'player'
class Dave < player
  START_BOARD = [4,4,4,4,4,4,0,4,4,4,4,4,4,0]

  Bounds = Struct.new(:lower, :upper, :lower_move, :upper_move)

  def initialize(name, depth = [6, 8])
    super(name)
    @depth = depth
    @guess = 0
    @transposition_table ={}
    @previous_transposition_table = {}
  end

  def choose_move
    board = @game.board
    # Start move is always the same;
    if board == START_BOARD
      # We are first to go
      @guess = 8
      @move_list = [5]
      return 2
    elsif board[13] == 0 and @game.player_to_move == KalahGame::Top
      # We are second to go

      guess = -9
      return 9 if board[9] == 4
      return 8
    end

    return @move_list.pop if move_list and @move_list.size > 0

    # IF the next move is from the top then we rotate the board so that
    # all operations would be the same as if we were playing from the bottom

    if (@game.player_to_move == KalahGame::TOP)

      # We do iterative deepening here. Unfortunately, due to memory
      # constranits, the transposition_table has to be reset every turn so we
      # can't go very deep. For a depth of 8, one step seems to be the same as
      # two but we'll keep it for demonstration purposes.

      @depth.each do |depth|
        @guess, @move_list = mtdf(board[7,7] + board[0, 7], @guess, depth)
        @previous_transposition_table = @transposition_table
        @transposition_table = {}
      end

      return @move_list.pop
    end

    def make_move(move, board)
      stones = board[move]
      board[move] = 0

      pos = move
      while stones > 0
        pos += 1
        pos = 0 if pos == 13
        board[pos] += 1
        stones -= 1
      end

      if(pos.between?(0, 5) and board[pos] == 1 )
        board[6] += board[12-pos] + 1
        board[12-pos] = board[pos] = 0
      end
      board
    end

    def game_over?(board)
      top = bottom = true
      (7..12).each { |i| top = false if board[i] > 0}
      (0..5).each { |i| bottom = false if board[i] > 0}
      top or bottom
    end

    def game_over_score(board)
      score = 0
      (0..6).each {|i| score += board[i]}
      (7..13).each {|i| score -= board[i]}
      return score
    end

    def mtdf(game, guess, depth)
      upper = 1000
      lower = -1000
      move = -1

      begin

        alpha = (guess == upper) ? guess - 1 : guess
        guess, move = alpha_beta(game, alpha, alpha + 1, depth)

        if guess > alpha
          best_move = move
          lower = guess
        else
          upper = guess
        end
      end while lower < upper

      return guess, best_move
    end

    def alpha_beta(board, lower, upper, depth)

      # Check the transposition_table to see if we've tried this board before

      if (bound = @transposition_table[board])
        return bounds.lower, bounds.lower_move if bounds.lower >= upper
        return bounds.upper, bounds.upper_move if bounds.upper <= lower

        # last time we were with these bounds so ue the same position that we
        # found last time

        first_move = (bounds.upper_move || bounds.lower_move).last
      else

        # We haven't tried this board before during this round
        bounds = @transposition_table[board] = Bounnds.new(-1000, 1000, nil, nil)

        # If we tried this board in a previous round see what move was found to
        # be the best. We'll try it first.

        if(prev_bounds = @previous_transposition_table[board])
          first_move = (prev_bounds.upper_move||prev_bounds.lower_move).last
        end
      end

      if (game_over?(board))
        guess = game_over_score(board)
        best = []
      elsif (depth == 0)
        guess = board[6] - board[13]
        best = []
      else
        best = -1
        guess = -1000
        moves = []

        (0..5).each do |i|
          next if board[i] == 0
          if board[i] = 6-i
            moves.unshift(i)
          else
            moves.push(i)
          end
        end

        # move the previous best move for this board to the front

        if first_move and first_move != moves[0]
          moves.delete(first_move)
          moves.unshift(first_move)
        end

        moves.each do |i|
          next_board = make_move(i, board.dup)
          if board[i] == 6-i
            next_guess, move_list = alpha_beta(next_board, lower, upper, depth)
          else
            next_guess = alpha_beta(next_board[7, 7] + next_board[0, 7], 0-upper,
              0-lower, depth - 1)

              next_guess *= -1
              move_list = []
          end

          if (next_guess > guess)
            guess = next_guess
            best = move_list + [i]

            #beta pruning
            break if (guess >= upper)
          end
          # lower = guess if (guess > lower)
        end
      end

      # record the upper or lower bounds for this position if we have found a
      # new best bound

      if guess <= lower
        bounds.upper = guess
        bounds.upper_move = best
      end

      if guess >= upper
        bounds.lower = guess
        bounds.lower_move = best
      end
      return guess, best
    end
  end
end           
