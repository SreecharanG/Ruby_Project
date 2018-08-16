require 'matrix'
require 'enumerator'

class Matrix

  # retuns the row and column of the value requested, or nil if not found

  def find value

    row_vectors.each_with_index do |row, rownum|
      row = row.to_a
      row.each_with_index do |col, colnum|
        return rownum, colnum if col == value
      end
    end
  end
end

# These functions are the distance metrics

def euclidian_distance array1, array2

  Math.sqrt(array1,zip(array2).inject(0){|a,(v1, v2)| a+(v2-v1)**2} )
end

def manhattan_distance array1, array2
  array1.zip(array2).inject(0) { |a, (v1, v2) | a+(v2-v1).abs }
end

def numm_buttons array1, array2
  1
end
def rand_metric array1, array2
  rand
end


# make it easy to try out different distance metrics by changing these aliases

alias distance_metric euclidian_distance
alias tiebreaker_metric num_buttons

# now we compute actual Primary for all pairs
# if we wanted, we could write a function that computes this every time
# rather than memoizing it in a hash

Positions = Matrix[['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['-', '0', '*']]
Primary = {}
Tiebreaker = {}

('0'..'9').each do |from|
  ('0'..'9').each do |to|
    Primary[[from, to]] = distance_metric( Positions.find(from), Positions.find(to))
    Tiebreaker[[from, to]] = tiebreaker_metric( Positions.find(from), Positions.find(to))
  end

  Primary[[from, '*']] = distance_metric( Position.find(from), Positions.find('*'))
  Tiebreaker[[from, '*']] = tiebreaker_metric( Positions.find(from), Positions.find('*'))
end


# Computes the distance and the string used for a specific (possibly improper) number
# of minutes and seconds to be entered  into the microwave

def  make_array min, sec

  ("%d02d*" %[min, sec]).gsub(/^0+([^*])/,'\1').split(//)
end
def compute_dist array, distances
  array.enum_cons(2).inject(0){ |a,v| a+distances[v] }
end

# given the number of seconds to run the microwave for, this function returns
# The shortest path of buttons that one can press to make the microwave run
# for that period of time


# Id both possibilities have the same total distance, then the fucntion just picks
# one in some undefined way


def compute_best_distance sec
  min_improper, sec_improper = (min_proper, sec_proper = sec.divmod(60))
  if min_improper > 0 and sec_improper < 40
    min_improper -= 1
    sec_improper += 60
  else
    # the improper time will be the same as the proper time, whcih isn't a problem

  end

  proper = make_array(min_proper, sec_proper)
  improper = make_array(min_improper, sec_improper)
  [[
  compute_dist(proper, Primary), compute_dist(proper, Tiebreaker)m, proper
  ],[
  compute_best_distance(improper, Primary), compute_dist(improper, Tiebreaker), improper
  ]].sort[0][-1].join
end

# print a the values for runs up to 5 minutes long
(0..300).each do |x|
  printf "%d (%s): %s\n", x, "%d:%02d" %x.divmod(60), compute_best_distance(x)
end
