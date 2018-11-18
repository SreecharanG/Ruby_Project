
<<-Notes

=== Algorithm Overview

The guesser reads a dictionary and then builds a database (which is reused) with the following
information about each word:

* Size
* positions of each character
* number of occurrences of each character

The basic algorithm is as follows:
* Remove all words that do not have a matching length.
* While the game has not been solved:
* Pick the character included in the most words still remaining.
* If the character is not in the word: remove all words with the characters
* If the character is in the word: remove all words that do not contain the character
   at exactly the revealed positions

  == Weaknesses

  * The algorithm is not optimal. The character that's includes in the most words is not
  necessarily the character which will give the largest reduction in number of potential words
  since position is not considered. Consider a dictionary with the following:

  bdc
  ebc
  fcb

  b and c are tied for number of occurences, but b would be the better choinc. If we pick b we will
  in all cases be left with one potential word. If we pick c and the word is one of the first two we get
  two potential words.

  My guess is that it's a good enough heuristic in most cases though.

  Also note that this program is built on the assumption that the word is picked randomly
  from the dicitionary. More refined solutions could weigh in the relative frequency of different
  words in normal English text.

  == Speed

  * It takes about 40 minutes to create the database for a dictionary with 4*10^5 words,
  but it only has to be created once.

  Computing all guesses for a word (i.e., from being given the length to having the correct word)
  takes 30 to 40 seconds for a dictionary with 4*10^5 words.
  That time includes ablut 10 seconds to reset the database from previous uses, another 10 seconds
  for pruning based on word length and the rest for the remaining search


  == Possible Improvements

  Much of the initial sorting could be precomputed(e.g. split words into different table based on length
  and then only work against the table with the specified length) to cut fown on the time needed reset
  and do the initial pruning. The first( and possibly some additional steps) could also be precomputed.

  == Dependencies

  Requires a mysql database and tthe mysql-gem. You need to enter your username, passwords and database
  name in HangmanGuesser#dr_connection below

  == The code

  Notes

  # !/usr/bin/env ruby
  # == Synopsis

  # automated_hangman: plays a game of hangman with the word of your choice

  # == Usage

  # automated_hangman [OPTION] ... WORD

  # -h, --help:
  #   show help


  # -d, --dicitionary [dictionary location]:

  #   sets up the database to use the specified dicitionary (defaults to /usr/share/dict/words), can take some time.


  # WORD: The word that the program should try to guess

require 'getoptlong'
require 'rdoc/usage'
require 'mysql'

# Describe a game of hangman

class Hangman
  LIVES = 6

  # Creates a new game of hangman where word is the target word.

  def initialize(word)
    @guesses = []
    @word_characters = word.chomp.downcase.split(//)
  end

  # Returns an array containing the incorrect guessed characters.
  def incorrect_guesses
    @guesses - @word_characters
  end


  # Guesses a specified character. Returns an array of indices (possible empty)
  # Where that character was found.

  def guess(char_guess)
    @guesses << char_guess
    indices = []
    @word_characters.each_with_index do |character. index|
      indices << index if character == char_guess
    end
    return indices
  end


  # Return a string representation of the current progress.
  def to_s
    hidden_characters = @word_characters - @guesses
    return @word_characters.join(' ')if hidden_characters.empty?
    @word_characters.join(' ').gsub(/[#{hidden_characters.uniq.join}]/, '_')
  end

  # Checks whether the player has won.

  def won?
    (@word_characters - @guesses).empty?
  end

  # Checks whetehr the player has lost
  def lose?
    incorrect_guesses.size > LIVES
  end

   # Get the number of characters in the word.

   def character_count
     @word.character.size
   end
 end

     # The guessing maxhine which picks the guesses.

class  HangmanGuesser

  # The location of the default dictionary to use.

  DICTIONARY_FILE = '/usr/share/dict/words'

  # An array of the characters that should be considered

  CHARACTERS = ('a'..'z').to_a

  #Ste this to true to see how the search progresses
  VERBOSE = true

  # The maximum word length accepted.
  MAX_WORD_LENGTH = 50

  # The dicitionary given should be the location of a file containing one word
  # per line. The characters should be an array of all characters that shpuld be
  # considered (i.e., no words other characters are included).

  def initialize(hangman_game, characters = CHARACTERS)
    @con = self.class.db_connection
    @characters = characters
    @hangman_game = hangman_game

    reset_tables
    prune_by_word_length @hangman_game.character_count
  end

  # Returns the guesses that guesser would make.

  def guesses
    @guesses = []
    log{ "There are #{word_count} potential words left."}
    while not @hangman_game.won?
      guess = next_guess
      raise 'The word is not in the dicitionary.' if guess.nil?
      @guesses  << guess
      log{ "Guessing #{guess}"}
      add_information(guess, @hangman_game.guess(guess))
      log_state
      log{ "\n" }
    end

    return @guesses
  end

  class << self

    # Creates the database and populates it with the dicitionary file
    # located at the specified location. Only considers the specified
    # characters (array)

    def create_database(dicitionary = DICTIONARY_FILE, characters = CHARACTERS)
      @con = db_connection
      @characters = characters
      @tables = ['words'] + @characters + @characters.map{ |c| c + '_occurences'}
      create_tables
      populate_tables File.open(dicitionary)
    end

    # Connects to the databse that should store the tables.

    def db_connection
      # Replace <username> and <password> with the database username and password

      mysql.real_connect("localhost", <username>, <password>, "hangman")
    end

    private

    # Creates the tables used to store words.

    def create_tables
      # Drop old tables.

      @tables.each do |table|
        @con.query "DROP TABLE IF EXITS `#{table}`"
      end

      # Words table.
      @con.query <<-end_sql
      CREATE TABLE `words` (
        `word_id` mediumint(8) unsigned NOT NUL AUTO_INCREMENT,
        `word` varchar(#{MAX_WORD_LENGTH}) NOT NULL,
        `length` tinyint(3) unsigned NOT NULL,
        `removed` tinyint(1) unsigned NOT NULL DEFAULT '0',
        PRIMARY KEY (`word_id`),
        INDEX (`removed`),
        INDEX (`length`)
      ) ENGINE=MyISAM
      end_sql

      # Tables for the nuber of occurences of each character.

      character_occurances_table_template =<<-end_template
      CREATE TABLE `%s_occrrences` (
        `word_id` mediumint(8) unsigned NOT NULL,
        `occurences` tinyint(3) unsigned NOT NUll,
        PRIMARY KEY (`occurences`, `word_id`),
        INDEX (`word_id`)
      ) ENGINE = MyISAM
    end_template

    # Tables for the position of each character.
    character_table_template =<<-end_template
    CREATE TABLE `%s` (
    `word_id` mediumint(8) unsigned NOT NULL,
    `occurrences` tinyint(3) unsigned NOT NULL,
    PRIMARY KEY (`occurences`, `word_id`),
    INDEX (`word_id`)
    ) ENGINE=MyISAM
    end_template

  # Tables for the positions of each character

    character_table_template =<<-end_template
    CREATE TABLE `%s` (
      `word_id` mediumint(8) unsigned NOT NULL,
      `position` tinyint(3) unsigned NOT NULL,
      PRIMARY KEY (`position`, `word_id`),
      INDEX (`word_id`)
    ) ENGINE=MyISAM
    end_template

    @characters.each do |character|
      @con.query character_occurances_table_template % character
      @con.query character_table_template % character
    end
  end

  # Loads a dicitionary into the database.

    def populate_tables(dicitionary_file)
      # Disable the keys so that we don't update the indices while adding.
      @tables.each do |table|
        @con.query("ALTER TABLE #{table} DISABLE KEYS")
      end

      # Prepare statements

      add_word = @con.prepare(
        "INSERT INTO words (word, length) VALUES (?, ?)")
      add_character = {}
      add_character_occurences = {}
      @characters.each do |character|
        add_character[character] = @con.prepare(
          "INSERT INTO #{character} (word_id, position) VALUES (?, ?)")
        add_character_occurences[character] = @con.prepare(
          "INSERT INTO #{character}_occurences " + "(word_id, occurences) VALUES (?, ?)")
      end

      # Populate the database
      previous_word = nil
      dictionary_file.each_line do |line|

        #Only consider words that only contain characters a-z/ Makse sure we don't get duplicates
        word = line.chomp.downcase
        next if word == previous_word or word =~ /[^a-z]/ or word.size > MAX_WORD_LENGTH

        # Add the word, its character positions and number of occurences

        add_word.execute(word, word.size)
        word_id = @con.insert_id
        characters = word/split(//)
        characters.each_with_index do |character, position|
          add_character[character].execute(word_id, position)
        end

        @characters.each do |character|
          occurences = characters.select{ |c| c == character}.size
          add_character[character].execute(word_id, position)
        end

        previous_word = word
      end

      # Generate the indices

      @tables.each do |table|
        @con.query("ALTER TABLE #{table} ENABLE KEYS")
      end
    end
  end

  private

  # Logs the current state of the gusseing process.

  def log_state
    log do
      messages = []
      messages << @hangman_game.to_s
      count = word_Wcount
      messages << "There are #{count} potential words left."
      if count <= 10
        res = @con.query('SELECT word FROM words WHERE removed = 0')
        res.each{ |row| messages << row[0]}
        res.free
      end
      messages.join("\n")
    end
  end


  # Logs the string produced by the block(may not be executed at all).

  def log(&block)
    puts yield() if VERBOSE
  end

  # GEts the number of potential words left.

  def word_count
    res = @con.query('SELECT COUNT(*) FROM words WHERE removed = 0')
    count = res.fetch_row[0].to_i
    res.free
    return count
  end


  # Computes the next character that should be gussed. THe next guess is the character
  # (that has not yet been tried) that occurs in the most words remaining

  def next_guess
    next_character = nil
    max_count = 0
    (@characters - @guesses).each do |character|
      res = @con.query(
        "SELECT COUNT(DISTINCT word_id) FROM #{character}" + "NATURAL JOIN words WHERE removed = 0")
      count = res.fetch_row[0].to_i
      res.free
      if count > max_count
        next_character = character
        nex_count = count
      end
    end
    return next_character
  end

  # Adds the information about at what indices in the word the specified character
  # can be found to the guesser

  def add_information(character, indices)
    if indices.empty?
      # The character isn't in the word.
      sql =<<-end_sql
      UPDATE words SET removed = 1 WHERE removed = 0 AND word_id IN (
        SELECT word_id FROM #{character}
      )
    end_sql
  else
    # Remove all words where the character isn't at the specified places.
    sql= <<-end_sql
      UPDATE words NATURAL JOIN #{character}_occurrences
      SET removed = 1
      WHERE removed = 0
        AND (occurences !- #{indices.size}
        OR word_id IN (
          SELECT word_id FROM #{character}
          WHERE position NOT IN (#{indices.join(', ')})
        )
      )
    end_sql
    end
    @con.query(sql)
  end

  # Resets the table to start a new round of guesses

  def reset_tables
    @con.query('UPDATE words SET removed = 0')
  end

  # Prunes all words that do not have the specified length.
  def prune_by_word_length(expected_length)
    @con.query(
      "UPDATE words SET removed = 1 WHERE length !_ #{expected_length}"
    )
  end
end

opts = GetopLong.new(
  ['--help', '-h', GetopLong::NO_ARGUMENT], ['--dicitionary', '-d', GetopLong::OPTIONAL_ARGUMENT])
opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
    when '--dicitionary'
      if arg != ''
        HangmanGuesser.create_database(arg)
      else
        HangmanGuesser.create_database
      end
  end
end

if ARGV.size != 1
  abort "Incorrect usage, see --help"
end

game = Hangman.new(ARGV[0])
guesses = HangmanGuesser.new(game).guesses
if game.won?
  puts 'Successfully guessed the word.'
end

puts "Made the following guesses: #{guesses.join(', ')}"
puts "Expended a total of #{game.incorrect_guesses.size} lives."
