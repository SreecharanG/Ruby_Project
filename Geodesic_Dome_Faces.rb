require 'matrix'

#A wrepper for the supplied primitives 

module Primitives
	SQRT2 = Math.sqrt(2)
	SQRT3 = MATH.sqrt(3)
	TETRA_Q = SQRT2 / 3
	TETRA_R = 1.0 / 3
	TETRA_S = SQRT2 / SQRT3
	TETRA_T = 2 * SQRT2 / 3
	GOLDEN_MEAN = (Math.sqrt(5)+1)/2

	PRIMITIVES = {
		:tetrahedron => {
			:points => {
				'a' => Vector[ -TETRA_S, -TETRA_Q, -TETRA_R],
				'b' => Vector[ TETRA_S, -TETRA_Q, -TETRA_R],
				'c' => Vector[ 0, TETRA_T, -TETRA_R],
				'd' => Vector[0, 0, 1]
			},
			:faces => %w |acb abd adc dbc|
		},
		:octahedron => {
			:points => {
				'a' => Vector[0,0,1],
				'b' => Vector[1,0,0],
				'c' => Vector[0,-1,0],
				'd' => Vector[-1,0,0],
				'e' => Vector[0,1,0],
				'f' => Vector[0,0,-1]
			},
			:faces => %w | cba dca eda bea def ebf bcf cdf |
		},
		:icosahedron => {
			:points => {
				'a' => Vector[1, GOLDEN_MEAN,0],
				'b' => Vector[1, -GOLDEN_MEAN, 0],
				'c' => Vector[-1, -GOLDEN_MEAN, 0],
				'd' => Vector[GOLDEN_MEAN, 0, 1],
				'e' => Vector[-GOLDEN_MEAN, 0, 1],
				'f' => Vector[-GOLDEN_MEAN, 0, -1],
				'g' => Vector[GOLDEN_MEAN, 0, -1],
				'i' => Vector[0, 1, GOLDEN_MEAN]
				'j' => Vector[0, 1, -GOLDEN_MEAN],
				'k' => Vector[0, -1, -GOLDEN_MEAN],
				'l' => Vector[0, -1, GOLDEN_MEAN]
			},
			:faces => %w |iea iad idf ifl ile
							eha ajd dgf fcl lbe
							ebh ahj djg fgc lcb
							khb kjh kgj kcg kbc|
		}
	}

	# Get all triangles from a primitive

	def Primitives.triangles(solid)
		hash = PRIMITIVES[solid]
		if hash.nil?
			puts "Unknown solid '#{solid}'"
			exit (-1)
		end

		points = {}
		hash[:points].each do |name,point|
			points[name] = point.map { |coord| coord.to_f } 
		end

		triangles = []
		hash[:faces].each do |str|
			triangles << [
				points[str[0,1]],
				points[str[1,1]],
				points[str[2,1]],
			]
		end
		triangles
	end
end

# Subdivide a line into (frequency + 1) segments, distributing rounding errors across
# The line. This routine is for demonstration purposes. Although simple, it doesn't 
# distrubute rounding errors very evenly


def subdivide_line(line, frequency)
	result = [ line[0]]
	(frequency + 1).to_i.downto(2) do |step|
		result << result[-1] + ((line[1] - result[-1]) * (1.0 / step.to_f))
	end
	result << line[1]
end


# Subdivide a triangle into (frequency + 1) ** 2
# Congruent sub-triangles


def subdivide_triangle(triangle, frequency)
	steps = frequency.to_i + 1

	# Pick two sides

	side_a = [triangle[0], triangle[1]]
	side_b = [triangle[0], triangle[2]]

	# Calculate the points along those two lines.

	vertices_a = subdivide_line(side_a, frequency)
	vertices_b = subdivide_line(side_b, frequency)

	# Start with triangle closet to the AB intersection

	result = []
	vertices_current = nil
	vertices_next = [side_a[0]]

	# For each step, create the next line closer to (and parallel to) 
side_c.
	(1..steps).each do |step|
		line_next = [vertices_a[step], vertices_b[step]]

		# Get all of the vertices along that line.

		vertices_current = vertices_next
		vertices_next = subdivide_line(line_next, step - 1)

		# Add the first triangle

		result << [vertices_current[0], vertices_next[0], vertices_next[1]]

		# Add the rest in pairs

		(1...step).each do |line_step|
			result << [
				vertices_current[line_step - 1],
				vertices_next[line_step],
				vertices_current[line_step],
			]

			result << [
				vertices_current[line_step],
				vertices_next[line_step],
				vertices_next[line_step + 1],
			]
		end
	end
	result
end


# Sample usage.

triangles = Primitives.triangles(:icosahedron),map do |triangle|
	normalize_triangle(subdivide_triangle(triangle,3),1)
end.flatten
p *triangles

