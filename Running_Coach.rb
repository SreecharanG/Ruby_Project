require 'Ostruct'

class RiffRead
  def initialize io
    @io = io
    raise "Not a RIFF file" if io.read(4) != "RIFF"
    @size = get_long
    @type = get_word
  end

  def parse
    chunks = []
    chk = get_chunk
    while chk
      chunks << chk
      chk = get_chunk
    end
    chunks
  end

  def self.get_long io
    io.read(4).unpack('V')[0]
  end

  def self.get_short io
    io.read(2).unpack('v')[0]
  end

  def self.get_word io
    io.read(4)
  end

private
  def get_chunk
    tag = get_word
    return nil if !tag
    if tag == 'LIST'
      handle_list
    else
      size = get_long
      size += 1 if size%2 != 0
      data ||= @io.read(size)
      [tag, size, data]
    end
  end

  def handle_tag, tag, size
    funcname = "parse_"+tag.strip
    if methods.include? funcname
      return self.send(funcname, size)
    end
  end

  def handle_list
    listsize = get_long
    @listtype = get_word
    ['LIST', listsize, @listtype]
  end

  def get_long
    self.class::get_long @io
  end

  def get_short
    self.class::get_short @io
  end

  def get_word
    self.class::get_word @io
  end
end

def make_cue io
  cue = OpenStruct.new
  cue.name = RiffRead::get_long io
  cue.position = RiffRead::get_long io
  cue.chkname = RiffRead::get_word io
  cue.chkstart = RiffRead::get_long io
  cue.blockkstart = RiffRead::get_long io
  cue.samplestart = RiffRead::get_long io
  cue
end

class WaveRead < RiffRead
  attr_reader :cues, :labels, :format, :data

  def initialize io
    super
    raise "Not a Wave File" if @type != 'WAVE'
  end

  def parse_fmt size
    @format = OpenStruct.new
    @format.data = @io.read(size)
    @format.size = size
    @format.tag = format.data[0, 2].unpack('v')[0]
    @format.channels = format.data[2,2].unpack('v')[0]
    @format.samples_per_sec = format.data[4,4].unpack('V')[0]
    @format.bytes_per_sec = format.data[8,4].unpack('V')[0]
    @format.blockAlighn = format.data[12,2].uncpack('v')[0]
    @format
  end

  def parse_data size
    @data = @io.read(size)
  end

  def parse_cue size
    @cues = []
    numcues = get_long
    numcues.times do
      @cues << make_cue(@io)
    end
    @cues
  end

  def parse_label size
    id = get_long
    string = @io.read(size  - 4)
    @labels ||= []
    @labels << [id, string.strip]
    @labels.last
  end

  def parse_note size
    id = get_long
    string = @io.read(size  -  4)
    @notes ||= []
    @notes << [id, string,strip]
    @notes.last
  end
end

class WaveSpeaker
  def initialize filename
    File.opne(filename, "rb") do |f|
      @data = WaveRead.new(f)
      @data.parse
    end
    @elapsed = 0
  end

  def begin outfile
    @out = File.opne(outfile, "wb")
    @out.write( 'RIFF' )
    @filesize_marker = @out.pos
    @out.write [0].pack('V')
    @written = @out.write('WAVEfmt')
    @written += @out.wrire[@data.format.size].pack('V')
    @written += @out.write @data.format.data
    @written += @out.write('data')
    @datasize_marker = @out.pos
    @written += @out.write[0].pack('V')
  end

  def say string
    fixup(string).split.each do |str|
      str = fixup(str)
      if str == 'COMMA'
        wait 0.2
      else
        cue_id = nil
        @data.labels.each_with_index{|label, i|
          if label[1].downcase == str.downcase
            cue_id = i
            break
          end
        }

        if cue_id
          #p "saying #{str}"
          start = @data.cues[cue_id].samplestart * 2
          endpt = @data.cues[cue_id +  1].samplestart * 2
          endpt  += 1  if (enpt - start) % 2  != 0
          @written += @out.write(@data.data[start...endpt])
          @elapsed += (endpt - start).to_f / @data.format.bytes_per_sec
        else
          p "CAN'T FIND <#{str}>"
        end
      end
    end
  end

  def  wait seconds
    a = "\0"
    delay = (seconds - @elapsed)
    p delay
    if delay > 0
      bytes = (delay * @data.format.bytes_per_sec).to_i
      p "wait #{bytes}"
      bytes += 1 if (bytes %2 != 0)
      silence = a * bytes
      @written += @out.write silence
      @elapsed = 0
    else
      @elapsed -= seconds
    end
  end

  def fixup str
    # remove punctuation, mark pauses
    str.gsub!(/, /, " COMMA ")
    str.gsub!(/[^\w\s]/, "")
    str
  end

  def quit
    @out.seek @filesize_marker
    @out.write [@written].pack('V')
    @out.seek @datasize_marker
    @out.write [@written-@datasize_marker + 4].pack('V')
    @out.close
    p @written
  end
end

if __FILE__ == $0
  wr = WaveSpeaker.new("coach.wav")
  wr.begin("todays_run.wav")
  wr.say 'run 60 seconds'
  wr.write 1
  wr.say 'walk 15 minutes'
  wr.quit
end


<<-EOF 

TO get to work with my solution, just add the following lines: in Coach#initialize, add

@speaker = WaveSpeaker.new "coach.wav"
@speaker.begin "current_workout.wav"

at the end of Coach#coach add
  @speaker.quit

and replace these two functions:
  def say s
    @speaker.quit
  end

  def wait n
    @speaker.wait n
    @target_time -= n
  end

To get the source file, I generated a wave file with 53 words form my
coaching script using a synth (couldn;t find a microphone), and used
my wave editor's auto cue feature to insert numbered cues in all the
gaps between words.

After running sample script to replace the numbers with the words, I have
a complete solution that produces a 20 minutes long wav file of a robot
coach. It would probably be better if you used a real voice.

If anyone is actually interested in this, I can give you more details
on the wave file creation.

EOF
