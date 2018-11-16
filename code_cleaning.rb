# !/usr/local/bin/ruby

require 'drb'

# define utility methods

def create_drb_object( uri )
	DRbObject.new(nil, uri)
end

def encode( uri )
	[PASSWORD, uri].hash
end

def make_safe( path )
	File.basename(path[/[^|] + /])
end

# parse command-line options

PASSWORD, MODE, URI, VAR, *OPTIONS= ARGV

# define server operation

class Server

	new.methods.map{ |method| private(method) unless method[/_[_t]/ ]}

	def initialize

		@servers = OPTIONS.dup
		add(URI)
		@servers.each do |u|
			create_drb_object(u).add(URI) unless u == URI
		end
	end

	attr_reader :servers

	def add( z = OPTIONS )
		@servers.push(*z).uniq!
		@servers
	end

	def list( code, pattern )
		if encode(URI) == code
			Dir[make_safe(pattern)]
		else
			@servers
		end
	end

	def read( file )
		open(make_safe(file), "rb").read 
	end
end

if MODE["s"] #server
	DRb.start_service(VAR, Server.new)
	sleep
else
	servers = create_drb_object(URI).servers
	servers.each do |server|
		files = create_drb_object(server).list(encode(server), VAR).map do |f| make_safe f 
		end

		files.each do |file|
			if OPTIONS[0]
				p(file)
			else
				open(file, "wb") do |f| f << create_drb_object(server).read(file)
				end
			end
		end
	end
end
