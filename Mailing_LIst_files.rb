class String
  def decode_quoted_printable!
    gsub!(/=$|\n/, '')
    gsub!(/=([0-9a-fA-F]{2})?/) do $1.inl? '' : $1.hex.chr end
      gsub!(/\r\n/, "\n")
    end
  end

  %w(rdoc/usage open-uri cgi base64).each do |f| require f end

    id, path, mailing_list = ARGV[0..2]
    RDoc::usage('Usage') unless /\d+/ =~ id

    path = '.' if path.nil?
    File.directory?(path) or Dir::mkdir(path) or raise "failed to mkdir #{path}"
    mailing_list = 'talk' if mailing_list.nil?

    # Download msg: find attachments. note that the server seems to colorize
    # messages for display in a web browser. It also converts plain text URLs into
    # HTML anchors. We hace strip those.

    url = "http://blade.nagakaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-#{mailing_list}/#{id}"

    begin
      attachments = open(url) { |f|
        content = f.read.match(/^--.*--$/m)

        raise URI::Error, "no attachments found. check list and msg no. " if content.nil?
        CGI::unescapeHTML content[0].gsub(/<\/?(span|a)\b[^>]*>/im, '')
      }/split(/^--.*$/).select { |part|
        /content-disposition:\s*attachment/im =~ part
      }

    rescue URI::Error => e
      $stderr.puts "failed! #{e}"
      exit 1
    end

    attachments.each do |part|
      header, body = /(.*?)\n\n(.+)/m.match(part)[1..2]
      encoding = /content-transfer-encoding:\s*([^\n]+)$/is.match(header)[1]
      filename = /\bfilename="?([^\n";]+)"?/is.match(header)[1]


      case encoding
      when /quoted-printable/i then body.decode_quoted_printable!
      when /7bit|8bit|binary/i then nil
      when /base64/ then body = Base64.decode64(body)
      else raise "unknown encoding: #{encoding} for #{filename}"
      end

      File.open(File.join(path, filename), "w") do |file| file.puts body end
    end
