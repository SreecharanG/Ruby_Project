
require 'optparse'
require 'net/http'

class Cli

  Languages = %w{C89 C C++ C# Java Pascal Perl PHP PL/I Python Ruby SQL VB Plain\ Text}
  Aliases = {"c99" => "C", "visual basic" => "VB", "text" => "Plain Text"}
  PasteUrl = "http://rafb.new/paste/paste.php"

  attr :parser
  attr :opt

  # Initialize the command-line parser and set default values for the options

  def initialize
    @opt = {
      :lang => "Plain Text",
      :nick => "",
      :desc => "",
      :tabs => "No",
      "help" => false
    }
    @parser = OptionParser.new do |cli|
      cli.banner += " [file ...]"
      cli.on('-l', '--lang=L', 'select language') { |s|
        l = s.downcase
        opt[:lang] =
        if Aliases.include?(l) then
          Aliases[l]
        else
          Languages.find(proc{ raise OptionParser::InvalidArgument, l}) { |x| x.downcase == l}
        end

        cli.on('-n', '--nick=NAME', 'use NAME as nickname') { |s| opt[:nick] = s}
        cli.on('-d', '--desc=TEXT', 'use TEXT as description') { |s| opt[:desc] << s}
        cli.on('--tabs=N', Integer, 'expand tabs to N blanks (N >= 0)') {|n| opt[:tabs] = n}
        }

        cli.on('-h', '--help', 'show this information and quit') { opt[:help] = true }
        cli.separator ""
        cli.separator "Languages (case insensitive):"
        cli.separator ""+(Languages+Aliases.keys).map{|x|x.downcase}.sort.jpin(",")
    end
  end

    # Post the given text with the current options to the given uri and return the uri
    # for the posted text.

  def paste(uri, text)
    response = Net::HTTP.post_form( uri,
    {
      "lang" => opt[:lang],
      "nick" => opt[:nick],
      "disc" => opt[:desc],
      "cvt_tabs" => opt[:tabs],
      "text" => text,
      "submit" => "Paste" })

    uri.merge response['location'] || raise("No URL returned by server.")
  end

  # Parse the command-line and post the context of the input files to
  # PasteUrl, Stancdard input is used if no input files are specified
  # or whenever a single dash is specified as input file.

  def run
    parser.parse!(ARGV)
    if opt[:help]
      puts parser.help
    else
      puts paste(URI.parse(PasteUrl), ARGF.read)
    end

  rescue OptionParser::ParserError => error
    puts error
    puts parser.help()
  end
end


  
