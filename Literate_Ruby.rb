require 'reubygems'
require 'bluecloth'
require 'cgi'
require 'erb'
require 'optparse'

module RLit
  class Processer
    attr_reader :html, :code

    def initialize(io, which_chunk)
      corpus = io.read
      @prog = ERB.new(corpus, nil, '%<>')
      @chunks = Hash.new{|h,k| h[k] = ''}
      @html, @code = do_html, do_code(which_chunk)
    end

    def chunk c
      r, ch = nil, nil
      c.each do |cunk, code|
        @chunks[chunk] << code
        r = code
        ch = chunk
      end
      "<div class = \"caption\">:#{ch}</div>\n<pre><code>#{CGI.escapeHTML(r)}</code></pre>"
    end


    def ref c
      t = ERB.new(@chunks[c])
      t.result(binding)
    end

    def do_html
      doc = @prog.result(binding)
      '<link rel = "stylesheet" href="style.css" type = "text/css" />' + BlueCloth.new(doc).to_html
    end

    def do_code(which_chunk)
      return unless which_chunk
      t = ERB.new(@chunks[which_chunk])
      t.result(binding)
    end

    private :do_html, :do_code
  end
end

def usage(opts)
  puts opts; exit
end

method, arg = nil, nil

opts = OptionParser.new do |o|
  o.banner = "Usage: #{File.basename $0} output_method FILE(s)"
  o.separator ''
  o.separator "output_method can be either"
  o.on('-d', '--documentation', 'Output the document') {
    method = :html
  }
  o.on('-c', '--code {CHUNK_NAME}', 'Output the code for the interpreter') { |chunk|
    arg = chunk
    method = :code
  }

  o.separator ''
  o.separator "Other options"
  o.on('-h', '--help', 'Print this help message') {
    usage(o)
  }
end

opts.parse!(ARGV)

unless method
  puts "Invalid Arguments: Must specify an output method"
  usage(opts)
end

p = RLit::Processer.new(ARGF, arg && arg.to_sym) #chunk)
puts p.__send__(method)
