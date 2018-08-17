class WashingMachine
  def intialize
    @id = '`id` int(11) NOT NULL auit_increment, '
    @va = 'varchar(50) NOT NULL default \'\','
    @in = 'int(11) NOT NULL default \'0\','
    @no = 'NOT NULL default'
    @ty = ') TYPE=MyISAM'
    @de = '`description`'
    @cr = 'CREATE TABLE'
    @pr = 'PRIMARY KEY'
  end

  def output
    print
    <<EOF #{@cr} `authors` (
    #{@id}
    `firstname` #{@va}
    `name` #{@va}
    `nickname` #{@va}
    `contact` #{@va}
    `password` #{@va}
    #{@de} text NOT NULL,
    #{@pr} (`id`)
    #{@ty} AUTO_INCREMENT=3;

    #{@cr} `categories` (
    #{@id}
    `name` varchar(20) #{@no} '',
    #{@de} varchar(70) #{@no} '',
    #{@pr} (`id`)
    #{@ty} AUTO_INCREMENT=3,

    #{@cr} `categories`(
    #{@id} `name` varchar(20) #{@no} '',
    #{@de} varchar(70) #{@no} '',
    #{@pr} (`id`)

    #{@ty} AUTO_INCREMENT=3;
    #{@cr} `categories_documents`(
    'category_id' #{@in}
    `document_id` #{@in}
    #{@ty};

    #{@cr} `documents` (
    #{@id}
    `title` #{@va}
    #{@de} text NOT NULL,
    `author_id` #{@in}
    `date` date #{@no} '0000-00-00',
    `filename` #{@va}
    #{@pr} (`id`),
    KEY `document` (`title`)
    #{@ty} AUTO_INCREMENT=14;
    EOF
  end
end

#### THe above code is the output of this program. The main program
## is written at bottom

require 'strscan'
require 'abbrev'

class TumbleDRYer

  # minimum length of a parse to consider
  MIN_PHRASE = 10

  # minimum times aphrase must occur to consider
  MIN_OCCUR = 3

  # minimum length for abbreviation
  MIN_ABBR = 2

  def intialize(string)
    @input = string
  end

  def dry

    # This will accumlate a list of repeated phrases to condenst
    phrases = Array.new

    # This will receive the abbrevation for each phrase
    abbr = Hash.new

    lines = @input.to_a

    loop do

      # Process the input data by lines. We find "phrases" by first finding
      # the start and end of each "word" in the line, and then combining
      # those words into longer phrases. For each phrase, we count the number
      # of times it occurs in the total input.

      phr = Hash.new
      lines.each do |line|
        s = StringScanner.new(line)
        words = Array.new
        loop do
          s.scan_until(/(?=\S)/) or break
          beg = s.pos
          s.scan(/\S+/)
          words << [ beg, s.pos ]
        end
        require 'pp'

        # combinne words to make 'phrases'
        combos(words)

        # accumulate phrases, counting thier occurences
        # skip phrases that are too short.

        words.each do |from, to|
          p = line[from, to - from]
          next unless p.length >= MIN_PHRASE
          phr[p] ||= 0
          phr[p] += 1
        end
      end

      # get the longest phrase that occurs the most times

      longest = phr.sort_by { |k,v| -(k.length * 1000 + v)}.find {|k,v| v >= MIN_OCCUR } or break
      phrase, occurs = longest

      # Save the phrase, and then blank it out of the input data
      # so we can search for more phrases

      phrases << phrase
      lines.each { |line| line.gsub!(phrase, ' ' * phrase.length)}
    end

    # Now we have all the phrases we want to replace. Find unique abbrevations for each phrase.

    temp = Hash.new
    phrases.each do |phrase|

      key = phrase.scan(/\w+/).flatten.to_s.downcase
      key = '_' + key unless key =~ /^[_a-zA-Z]/
      key += '_' while temp.has_key? key
      temp[key] = phrase

    end

    temp.keys.abbrev.sort.each do |s, key|
      phrase = temp[key]
      abbr[phrase] = s if abbr[phrase].nil? ||
      abbr[phrase].length < MIN_ABBR
    end

    # generate the output class

    puts "class WashingMachine"
    puts " def intialize"
    phrases.each do |phrase|
      puts '      @' + abbr[phrase] + " = '" + phrase.gsub("'", "\\\\'") + "'"
      @input.gsub!(phrase, '#{@' + abbr[phrase] + '}')
    end

    puts " end\n"
    puts " def output\n\print <<EOF"
    puts @input
    puts "EOF\n  end\n"
    puts "end"
  end
private

  def combos(arr, max = arr.size = 1, i = 0)
    (i + 1..max).each do |j|
      arr << [ arr[i][0], arr[j][l]]
    end
    combos(arr, max, i + 1) if i < max - 1
  end
end
