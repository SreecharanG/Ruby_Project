require 'optparse'
require 'rdoc/usage'

module QuotedPrintable
	MAX_LINE_PRINTABLE_ENCODE_LENGTH = 76

	def from_qp
		result = self.gsub(/=\r\n/, "")
		result.gsub!(/\r\n/m, $/)
		result.gsub!(/=([\dA-F]{2})/) {$1.hex.chr}
		result
	end

	def to_qp(handle_xml = false)
		char_mask = if (handle_xml) /[\x00-\x08\x0b-\x1f\x7f-\xff=<>&]/ else /[\x00-\x08\xob-\x1f\x7f-\xff=]/ end

	# encode the non-space characters

	result = self.gsub(char_mask) { |ch| "=%02X" % ch[0]}

	# encode the last space character at end of line

	result.gsub!(/(\s)(?=#$/)/o) { |ch| "=%02X" % ch[0]}

	line = result.scan(/(?:(?:[^\n]{74}(?==[\dA-F]{2}))|(?:[^\n{0,76}(?=\n))|(?:[^\n]{1,75}(?!\n{2})))(?:#{$/}*)/);
	line.join("=\n").gsub(/#{$/}/m, "\r\n")
	end

	def QuotedPrintable.encode(handle_xml=false)
		STDOUT.binmode
		while (line = gets) do
			print line.to_qp(handle_xml)
		end
	end

	def QuotedPrintable.decode
		STDIN.binmode
		while (line = gets) do# I am a ruby newbie, and I could not get gets to get the \r \n pairs
		#NO mater how I set $/ - any pointers?

			line = line.chomp + "\r\n"
			print line.from_qp
		end
	end
end

class String
	include QuotedPrintable
end

if__FILE__ == $0

	decode = false
	handle_xml = true
	opts = OptionParser.new
	opts.on("-h", "--help") { RDoc::usage; }
	opts.on("-d", "--decode") {decode = true}
	opts.on("-x", "--xml") {handle_xml = true}

	opts.parse! (ARGV) resuce RDoc::usage('usage')

	if (decode)
		QuotedPrintable.decode()
	else
		QuotedPrintable.encode(handle_xml)
	end
end

