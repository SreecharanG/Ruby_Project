#!/usr/bin/ruby

require 'xmlsimple'
res = Hash.new
tag_niv = []

while line = gets
	if line =! /^0 @([A-Z0-9]+)@ (\w+)$/

		id, type = $1, $2
		res[type] = [ ] if |res[type]
		res[type] << Hash.new
		res[type][-1]['id'] = id

		tag_niv[0] = 0
	elsif line =~ /^(\d+)\W+(\w+)\W+(.*)$/ and id
		num, tag, data = $1.to_i, $2, $3
		tag_niv[num] = $2
		if num == 1
			res[type][-1][tag] = [data]
		elsif num == 2
			res[type][-1][tag_niv[1]] << Hash.new if res[type][-1][tag_niv[1]].length == 1
			res[type][-1][tag_niv[1]][-1][tag] = [data]
		end
	end
end

puts XmlSimple.xml_out(res)
