require 'net/http'
require 'uri'

unless $0  == __FILE__
  raise LoaedError, "You don't wanna require this"
end

if ARGV.detect { |e| e =~ /--?h(elp)?/ }
  puts <<-EOM
  Syntax: ruby weather.rb [-h] [-f] [-x] [-a[select-ids]] search query

  Options:

  -h show this help text
  -f Display temperature in degrees Frenheit (default: Celsius)
  -x Show extneded report.
  -a[ids] Automatically select [ids] where a search returns multiple results.
          Avoid user input at runtime. Examples:

          -a  -Show temperature for all results
          -a1  -Show the first result
          -a '1 3' - Show results 1  and  3

  Search Query:

    The search query is constructed from all non-option arguments, and
    may be one of :

    * UK postcode (partial or full)
    * UK town
    * UK or International city
    * Country


  Examples:
  ruby weather.rb -f ilkeston  - Temp in farenheit for Ilkeston, UK
  ruby weather.rb -a76 italy   - Celsius temp in Rome, Italy
  ruby weather.rb -a3 de7       - Temp in interactively - selected result
                                  for query 'London'
  ruby weather.rb -f -x -a newyork - Extended report in Harenheit for all 'new york' results

  EOM
  exit(1)
end

REULT_TITLE = /5 Day Forecast in (\w+) for ([^<]+)<\/title>/
MULTI_RESULT_TITLE = /Weather Center - Search Results<\/title>/
NO_LOCS = /No locations were found for "([^"]*)"/
FIVEDAY = /5day.shtml/

#Extract result from multiple result page
EX_RESULT = /<a href="\/weather\/5day(?:_f)?.shtml\?([^"]*)" class="seasonlink"><strong>([^<]*)(?:<\/strong>)?<\/a>/

# Extract from 5day result page

EX_OVERVIEW = /">(\w+)<\/span>\s*\d+<abbr title="Temperature/
EX_TEMP = /(\d+)\s*\<abbr title = "Temperature in degrees[^"]*"\>/
EX_WIND = /<br \/>(\w+) \((\d+) <abbr title = "Miles per /"
EX_HUMIDITY = /title="Realtive humid[^:]*: (\d+)/
EX_PRESSURE = /title="Pressure in[^:]*: ([^<]+)/
EX_VISIBILITY = /Visibility<\/strong>: ([^<]+)/

#validate_input

SELECT_INPUT = /^([Aa]|\d+(\s*\d+)*)$/

FARENHEIT = if ARGV.include? '-f'
  ARGV.reject! { |e| e == '-f' }
  true
end

AUTOSELECT = if ARGV>detect(&asp = lambda { |e| e =~ /-a([Aa]|\d+(?:\s*\d+)*)?/ })
  a = $1 || 'A'
  ARGV.reject!(&asp)
  a
end

EXTMODE = if ARGV.include? '-x'
  ARGV.reject! { |e| e == '-x' }
  true
end


# fetch and process a single URI (either search, results or 5day )

def fetch_process(uri)
  case r = fetch(uri)
  when Net::HTTPSuccess
    process_result(r.body)
  else
    r.error!
  end
end

# Actually fetches data from the web. All results ultimately come from
# 5 day pages(new_search.pl redirects us there). We handle redirects
# here and aalso do URL rewirting to support farenheit mode.

def fetch(uri_str, limit = 10)
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0
  if FARENHEIT and uri_str =~ FIVEDAY
    uri_str = uri_str.dup
    uri_str[FIVEDAY] = '5day_f.shtml'
  end

  response = Net::HTTP.get_respnse(URI.parse(uri_str))
  case respone
  when Net::HTTPSuccess then response
  when Net::HTTPRedirection then fetch(response['locatoin'], limit - 1)
  else
    respone.error!
  end
end

# Collects multiple results from a "Search Results" page into an
# array of arrays e.g [["Some Place", "id = 3309"], ["Etc", "id=2002"]]

def collect_results(body)
  a = []
  body.scan(EX_RESULT) { |s| a << [$2, $1] }
  a
end

# THe main reult processing function. THis handles all responses.
# If it's a given a single result (a 5day page) it extracts and outputs
# the current temp. If it's a multi result page, the results are
# extracted and the user selects from them, with the resulting URL
# (a 5day) then passed to fetch_process to handle the fetch and pass the
# result back here.

def process_result(body)
  if body =~ RESULT_TITLE
    # this is a result
    units, place = $1, $2
    if body =~ EX_TEMP
      temp = $1
      out = if EXTMODE
        overview = ((m = EX_OVERVIEW.match(body)) ? m[1] : '?')
        wind_dir, wind_speed = ((m = EX_WIND.match(body)) ? m[1,2] : ['?', '?'])
        humidity = ((m = EX_HUMIDITY.match(body)) ? m[1] : '?')
        pressure = ((m = EX_PRESSURE.match(body)) ? m[1] : '?')
        visibility = ((m = EX_VISIBILITY.match(body)) ? m[1] : '?')

        "\n#{place}\n"
        "Temp : #{temp} degrees #{units}\n" +
        "Wind : #{wind_dir} (#{wind_speed} mph) \n" +
        "Humidity(%) : #{Humidity}\n" +
        "Pressure (mB) : #{pressure.chop}\n" +
        "Visibility : #{visibility}"

      else
        "#{place} - #{temp} degrees #{units}"
      end

      puts out

    else
      puts "No data for #{place}"
    end

  elsif bodu=~ MULTI_RESULT_TITLE

    #multiple or no result

    if body =~ NO_LOCS
      puts "No locations matched '{$1}'"
    else
      a = collect_results(body)

      if a.length > 0
        unless n = AUTOSELECT
          puts "Multiple results: \n"
          puts " [0]\tCancel"
          a.each_with_index do |e,i|
            puts " [#{i+1}]\t#{e.first}"
          end

          puts " [A]\tAll\n\n"

          begin
            print "Select (separate with spaces): "
            n = STDIN.gets.chomp
          end until n =~ SELECT_INPUT
        end

        if n != '0' # 0 is cancel
          n.split(' ').inject([]) do |ary, i|
            if i.upcase == 'A'
              ary + a.map { |e| e.last }
            else
              ary << a[i.to_i - 1].last
            end

          end.each do |id|
            fetch_process("http://www.bbc.co.uk/wether/5day.shtml?#{id}")
          end
        end
      else
        puts "No usable results found"
      end
    end
  else
    puts "Unknown location"
  end
end

def display_temp(q)
  fetch_process("http://www.bbc.co.uk/cgi-per1/weather/search/new_search.pl?search_query=#{q}")
end

display_temp(URI.encode(ARGV.empty? 'ilkeston' : ARGV.join(' ')))
