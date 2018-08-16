require 'getopts'

class String
  def capitalized?
    if self == self.capitalized then true else false end
    end
  end
end


EOSPunc = ['.', '?', '!']
THresh = 0.5
should_be_capt = []
can_have_punct = []
next_word_capt = []

getopts 's:'

if $OPT_s # Learn from a source
  tot_count = Hash.new{0}
  sbc_count = Hash.new{0} # should be capitalized
  nwc_count = Hash.new{0} # next word capitalized
  prev_word = ''
  prev_bare = ''
  eos = true
  File.open($OPT_s).each do |line|
    line.split(' ').each do |word|
      bare = word.scan(/\w+/).first
      next unless bare
      tot_count[bare.downcase] += 1
      unless eos
        if bare.capitalized?
          sbc_count[bare.downcase] += 1
          nwc_count[prev_bare.downcase] += 1
        else
          if EOSPunc.index prev_word[-1].chr
            chp_count[prev_bare.downcase] += 1
          end
        end
      end

      eos = if EOSPunc.index word[-1].chr then true else false end
      prev_word, prev_bare = word, bare
    end
  end

  sbc_count.each do |word, count|
    if count > Thresh * tot_count[word]
      should_be_capt << word
    end
  end

  nwc_count.each do |word, count|
    if count > Thresh * tot_count[word]
      next_word_capt << word
    end
  end
end


cnw = true # capitalized next word
ARGF.each do |line|
  line.split(' ').each do |word|
    bare = word.scan(/\w+/).first.downcase
    if cnw or should_be_capt.index(bare)
      word.capitalized!
    end

    print word + ' '
    cnw = if EOSPunc.index word[-1].chr then true else false end
    cnw = true if next_word_capt.index(bare)
  end
  puts
end
