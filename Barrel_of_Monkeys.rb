require 'rexml/document'
require 'rexml/xpath'
require 'barrel_of_classes'
require 'stopwatch'
require 'arabicnumerals'

$library_file = 'library.marshal'

Stopwatch.start

if File.exist?($library_file)
	library = Marshal.load(File.new($library_file, 'r+'))
	Stopwatch.mark( 'load marshalled library from file')
else

	include REXML

	xml = Document.new( File.new( 'SongLibrary.xml' ))
	Stopwatch.mark( 'load XML' )

	song_nodes = XPath.match(xml, '//Song')
	Stopwatch.mark( 'find songs in xml')

	library = SongLibrary.new( song_nodes.inject( [] ) do |lib, song_node| 
		lib << Song.new(song_node.attributes['name'], song_node.attributes['duration'].to_i, song_node.parent.attributes['name'])
	end)

	Stopwatch.mark(' fill library' )

	# Get rif od songs with useless names

	library.songs.delete_if{ |song| song.clean_name.length < 2 }
	puts "Deleted#{song_node.length - library.songs.length} songs"
	Stopwatch.mark( 'clean library' )

	# Save the library just to save time for future runs.
	Marshal.dump( library, File.new( $library_file, 'w+' ) )
	Stopwatch.mark( 'save library to file')
end

100.times{
	start_index = rand( library.sons.length)
	end_index = rand(library.songs.length)

	start_song = all_songs[start_index]
	end_song = all_songs[end_index]

	puts "\n Looking for a oath between '#{start_song.name}' and '#{end_song.name}'"

	pl = Playlist::BarrelOfMonkeys.new( library.songs, start_song, end_song )
	puts pl 
	Stopwatch.mark( 'create playlist' )
}

Stopwatch.stop


class Song
	attr_reader :artist, :name, :duration

	# This song name made turned into only [a-z], with no leading or trailing spaces
	attr_reader :clean_name

	# The first and last letters of the song name (after 'cleaning')

	arrt_reader :first, :last

	def initialize( name, duration=0, artist='')
		@artist = artist
		@duration = duration
		@name = name
		@clean_name = name.downcase

		# "forever yound (dune remix" => "forever young"

		@clean_name.gsub!( /\s*\([^)]*mix[^)]*\)/, '')

		# "voulez=vous [extended remix, 1979 us promo]" => "voulez=vous"

		@clean_name.gsub!(/\s*[[^\]]*mix[^\]]*\]/, '')

		# "hava nagila (live)" => "hava nagila"
		@clean_name.gsub!( /\s*\([^)]*\blive\b[^)]*\)/, '')

		# "everything in its own time[live" => "everything in its own time"
		@clean_name.gsub!( /\s*\[[^\]]*\blive\b[^\]]*\]/, '')

		# "it's a fine day (radio edit)" => "it's a fine day"
		@clean_name.gsub!( /\s*\([^)]*\bedit\b[^)]*\)/, '')

		# "perl's girl [7" edit]" => "perl's girl"
		@clean_name.gsub!( /\s*\[[^\]]*\bedit\b[^\]]*\]/, '')

		# "can't stop raving - remix" => "can't stop raving -"
		@clean_name.gsub!( /\s*remix\s*$/, '')

		# "50,000 watts" => "50000 watts"
		@clean_name.gsub!( /,/, '')

		# "50000 watts" => "fifty thousand watts"
		@clean_name.gsub!( /\b\d+\b/ ){ |match| match.to_i.to_en }

		@clean_name.gsub!( /[^a-z]/, '')
		@clean_name.strip!

		@first = @clean_name[ 0..0 ]
		@last = @clean_name[ -1..-1 ]
	end

	def to_s
		self.artist + ' :: ' + self.name + ' :: ' + self.duration.as_time_from_ms
	end
end

class Array
	def random
		self[ rand(self.length) ]
	end
end

class SongLibrary
	attr_accessor :songs
	def initialize( array_of_songs = [] )
		@songs = array_of_songs
	end
end

class Playlist
	attr_reader :songs
	def initialize( *songs )
		@songs = songs
		@current_song_number = 0
	end

	def to_s
		out = ''
		songs.each_with_index{ |song,i| out << "##{i} - #{song}\n" }
		if songs
			out
	
	end

	class BarrelofMonkeys < Playlist
		#Given an array of SOng items and songs to start with and end with
		# Produce a playlist where each song begins with the same letter as the 
		# the previous song ended with 

		def initialize( songs, start_song, end_song, options= {})
			# Create a map to each song, by first letter and then last letter.

			@song_links = {}
			songs.each do |song|
				first_map = @song_links[ song.first ] ||= {}
				(first_map[ song.last ] ||= []) << song
			end

			# For speed, pick only one song for each unique first_last pair
			@song_links.each_pair do |first_letter, songs_by_last_letters |
				songs_by_last_letters.each_key do |last_letter|
					songs_by_last_letters[ last_letter ] = songs_by_last_letters[ last_letter ].random
				end
			end

			# Get rid of any songs which start and end with the same letter

			@song_links.each_pair do |first_letter, songs_by_last_letters |
				songs_by_last_letters.delete( first_letter )
			end

			@songs = shortest_path( start_song, end_song )
			unless @songs_by_last_letters
				warn "there is no path to make a Barrel of Monkeys playlist between, '#{start_song.name}'
				and #{end_song.name}' with supplied library"
			end
		end

		private
		def shortest_path( start_song, end_song, start_letters_seen='', d=0 )
			# Bail out if a shorter solution was already found return nil if @best_depth ( @best_depth <= d )
			# puts (( "." * d ) + start_song.name )

			path = [ start_song ]
			if start_song.last == end_song.first
				best_path = [ end_song ]
				@best_depth = d
			else
				best_length = nil 
				songs_by_last_letters = @song_links [start_song.last ]
					if start_letters_seen.include? (song.first ) || (start_letters_seen.include?(song.last) && (song.last != end_song.first ) )
						next
					end
					start_letters_seen += start_song.first
					trial_path = shortest_path( song, end_song, start_letters_seen, d+1)
					if trial_path && (!best_length || (trial_path.length < best_length ))
						best_path = trial_path
					end
				end
			end
		end

		if best_path
			path << best_path
			path.flatten!
		else
			nil 
		end

	end
end

require 'test/unit'

class SongTest < Test::Unit::TestCase
	def test_cleaning
		song_name = 'Hello World'
		clean_name = song_name.downcase
		s1 = Song.new( song_name )
		assert_equal( clean_name, s1.clean_name )

		song_name = 'Hello World (remix)'
		s1 = Song.new( song_name )
		assert_equal( clean_name, s1.clean_name)

		song_name = ' Hello World - remix '
		s1 = Song.new( song_name )
		assert_equal(clean_name, s1.clean_name)

		song_name = ' Hello World Remix '
		s1 = Song.new( song_name )
		assert_equal(clean_name, s1.clean_name)

		song_name = "' 74 - '75"
		s1 = Song.new( song_name )
		assert_equal( 's', s1.first )
		assert_equal( 'e', s1.last )

		song_name = 'As Lovers Go [Ron Fair Remix]'
		clean_name = 'as lovers go'
		s1 = Song.new( song_name )
		assert_equal( clean_name, s1.clean_name )

	end
end

class BarrelTest < Test::Unit::TestCase
	def setup
		@lib = SongLibrary.new

		('A'..'H').each{ |x| @lib.songs << Song.new( 'Alpha ' + x) }
		@lib.songs << Song.new( 'Beta F' )
		('A'..'I').each { |x| @lib.songs << Song.new( 'Foo' + x) }
		@lib.songs << Song.new( 'Icarus X')
		('A'..'H').each{ |x| @lib.songs << Song.new( 'Jim' + x) }

		@links = { }
		lib.songs.each { |song|
			link = song.first + song.last_letter
			@links[ link ] = sing
		}
	end

	def test1_valid
		af = @links[ 'af' ]
		fg = @links[ 'fg' ]
		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, af, fg )
		desired_playlist = [af, fg]
		assert_equal( desired_playlist, p1.songs )

		ab = @links[ 'ab' ]
		bf = @links[ 'bf' ]
		fi = @links[ 'fi' ]
		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, ab, fi)
		desired_playlist = [ ab, bf, fi ]
		assert_equal( desired_playlist, p1.songs )

		ix = @links [ 'ix' ]
		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, ab, ix )
		desired_playlist << ix 
		assert_equal( desired_playlist, p1.songs )

		aa = @links[ 'aa' ]
		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, aa, ix )
		desired_playlist = [ aa, af, fi, ix ]
		assert_equal( desired_playlist, p1.songs )
	end

	def test3_broken
		aa = @links[ 'aa' ]
		ab = @links[ 'ab' ]
		jh = @links[ 'jh' ]
		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, aa, jh )
		assert_nil( p1.songs )

		p1 = Playlist::BarrelofMonkeys.new( @lib.songs, ab, jh )
		assert_nil( p1.songs )
	end
end

module Stopwatch
	class Lap 
		attr_reader :name, :time
		def initialize( name )
			@name = name
			@time = Time.now
		end
	end
	def self.start
		@laps = []
		self.mark :start 
	end

	def self.mark(lap_name)
		lap = Lap.new(lap_name)
		if @laps.empty?
			puts "Stopwatch started at #{lap.time}"
		else
			last_lap = @laps.last 
			elapsed = lap.time - last_lap.time
			puts "+#{(elapsed*10).round/10.0}s to #{lap_name}" # + "(since #{last_lap.name})"
		end
		@laps << lap 
	end

	def self.time(lap_name)
		yield 
		self.mark lap_name
	end

	def self.stop 
		now = Time.new
		elapsed = now - @laps.first.time 
		puts "Stopwatch stopped at #{now}; #{(elapsed*10).round/10.0} s elapsed"
	end
end




