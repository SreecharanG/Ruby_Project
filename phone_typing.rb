
prefix = []
while c = io.getc
	if k = downcase[c]
		node = (@roots[k] ||= MarkovNode.new)
		prefix.each do | p |
			node.popularity += 1
			node = (node[p] ||=MarkovNode.new)
		end
		node.popularity += 1
		prefix.pop while prefix.length >= @max_prefix
		prefix.unshift k
	end
end

def popularity(char, prefix)
	node= @roots[char[0]]
	pos = prefix.length - 1
	while pos >= 0 and node.is_a?MarkovNode and node[prefix[pos]]
		node = node[prefix[pos]]
		pos -= 1
	end
	node.to_i
end
