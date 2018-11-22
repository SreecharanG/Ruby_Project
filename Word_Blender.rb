class Game
  def initialize
    @short_words = []
    @long_words []
    get_dict
  end

  def get_dict
    puts "Reading File..."
    File.open("english.txt", "r").each_line do |line|
      line.chomp!
      @short_words << line.downcase if (3..5).include?(line.length)
      @long_words << line.downcase if line.length == 6
    end

    puts "Short words: " + @short_words.length.to_s
    puts "Six letter words"
    @long_words.length.to_s
  end

  def start
    round_number = 0
    begin
      create_targets
    end while play_round(round_number+= 1)
  end

  def create_targets
    @target_word = @long_words[rand(@long_words.length)]
    @target_letters = @target_word.clone

    10.times do
      pos = rand(6)
      @target_letters[0,1], @target_letters[pos, 1]= @target_letters[pos, 1], @target_letters[0, 1]
    end
  end

  def letter_match?(gues, target)
    0.upto(guess.length - 1) do |i|
      letter = guess[1, 1]
      if target.include?(letter) then target[letter]= ""
      else return false
      end
    end
    return true
  end

  def get_score(words_guessed, guess, target)
    points, round_end = 0, false
    if @short_words.include?(guess) ||
      @long_words.include?(guess)
      if words_guessed.include?(guess)
        puts "You've used that word, No points this time."
      else
        if letter_match?(guess, target)
          words_guessed << guess
          if guess.length == 6
            puts "*** Well Done! You got the big one! ***"
            points = 1
            round_end = true
          else
            puts "Well done (+1 point)"
            points = 1
          end
        else puts "I know that word, but it doesn't use the right letters, no points."
        end
      end
    else puts "I don't know that word"
    end
    return points, round_end
  end


  def play_round(round_number)
    words_guessed = []
    quit = false
    puts "\n\n---Round Number #{round_number}----"
    puts "\n Letters are: #{@target_letters.upcase}"

    begin
      print "\n[#{@target_letters.upcase}]"
      #Points: #words_guessed.length. Guess(<Q>uit)>"
      guess  = gets.downcase.chomp
      quit = (guess== 'q')
      if quit then puts "Bye"
      else points, round_end = get_score(words_guessed, guess, @target_letters.clone)
      end
    end
    while not (rounnd_end || quit)
      puts "YOu guessed#{words_guessed.sort.join(",")} \n Word was #{@target_word}" if !quit
      return !quit
    end #paly_round

  end # class
  game = Game.new
  game.start
  
