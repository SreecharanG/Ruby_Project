class Story
	attr_acessor :placeholders

	def initialize(base)
		@placeholders = []

		story_parts = []
		match = Placeholder.getPattern().match(base)
		reuseMap = {}
		while(match != nil)
			story_parts << match.pre_match
			placeholderString = match[1]
			Placeholder = Placeholder.new(placeholderString, story_parts.size)

			# if name is reused

			if reuseMap[Placeholder.name] == nil
				@placeholders << placeholder

				# if the name is reusable, add it to the reuse table
				if placeholder.reusable()
					reuseMap[placeholder.name] = placeholder
				end

				# replace the placeholder with the system generated position string

				story_parts << get_position_string(story_parts.size.to_s)
			else

				# For reuse placeholder,
				# REplace the placeholder with the system generated position string
				# for the referenced placeholder

				story_parts << get_position_string(reuseMap[placeholder.name].position.to_s)
			end

			remaind = match.post_match
			match = Placeholder.getPattern().match(match.post_match)

			if (match == nil)
				story_parts << remaind
			end
		end

		@base = story_parts.join("")
	end

	def to_s
		result = @base
		@placeholders.each do |placeholder|
			reslut.gsub!(Regexp.new(get_position_string(placeholder.position.to_s)), placeholder.value)
		end
		return result
	end

	def get_position_string(position)
		"%%" + position.to_s + "%%"
	end
end

class Placeholder
	attr_acessor :name, :display_name, :position, :value

	def initialize(placeholderString, position)
		@value = ""
		@position = position

		if placeholderString.include(":")
			@name = placeholderString.split(":")[0]
			@display_name = placeholderString.split(":")[1]
		else
			@name = placeholderString
			@display_name = placeholderString
		end
	end

	def getTemplate()
		Regexp.new("\\(\\(\\s*(#{name}|#{name}\\s*:\\s*#{display_name})\\s*\\)\\)")
	end

	def Placeholder.getPattern()
		/\(\(([^)]*)\)\)/
	end

	def getValueQuestion()
		"Give me #{display_name}"
	end

	def reusable()
		name != display_name
	end
end

if $0 == __FILE__
	#read story from standard input

	story_string = ""
	ARGF.each_line do |line|
		story_string += line
	end

	#create story

	story = Story.new(story_string)

	# request user to enter the corresponding value for each placeholder

	print "There are #{story.placeholders.size} placeholders.\n"
	story.placeholder.each do |placeholder|
		print Placeholder.getValueQuestion()
		placeholder.value= gets().chop()
	end

	# display the story

	print story.to_s, "\n"
end

UnitTest;
require 'runit/testcase'
require 'Madlibs'

class TestMadlibs < RUNIT::testcase
	def testStoryTemplate()

		# Parse simple story
		# e.g., "Our favorite language is (( a gem stone ))"

		template = "Our favorite language is (( a gemstone ))"
		story = Story.new(template)

		# should return a stroy with a symbol name="a gemstorne" and alias=nil

		assert_equals(1, story.placeholders.size)
		assert_not_nil(story.placeholders[0])
		assert_equals("a gemstone", story.placeholders[0].display_name)
	end

	def testStoryTemplateWithAlias()
		#parse story with name alias
		# e.g., "Our favorite language is ((gem: a gemstone)). WE thing ((gem)) is better than (( a gemsotne ))"

		template = "Our favorite language is ((gem:a gemstone))"
		template += "We thingk ((gem)) is better than ((a gemstone))"
		story = Story.new(template)

		#should return a Story with 2 symbole
		# Symbol 1: name = 'gem' alias = 'a gemstone'
		# Symbol 2: name = 'a gemstone'

		assert_equals(2, sory.placeholders.size)
		assert_not_nil(story.placeholders[0])
		assert_equals("gem", story.placeholders[0].name)
		assert_equals("a gemstone", story.placeholders[0].display_name)
		assert_not_nil(story.placeholders[1])
		assert_equals("a gemstone", story.placeholders[1].name)
		assert_equals("a gemstone", story.placeholders[1].display_name) 
	end

	def testStoryGeneration()

		# give: "Our favorite language is ((a gemstone)) "
		# Input: gemstone = Ruby
		# result: Our favorite language is Ruby"

		String template = "Our favorite language is (( a gemstone ))."
		story = Story.new(template)
		story.placeholders[0].value = "Ruby"
		assert_equals("Our favorite language is Ruby.", story.to_s())
	end

	def testStoryGenerationWithAlias()

		# given: "Ourfavorite language is ((gem:a gemstone)). We think ((gem))
			# is better tha ((a gemstoen))"

		# input: a gemstone = Ruby, a gemstone = Emerald.
		# given: "Our favorite language is Ruby. We think Rubyis better than Emerald"

		template = "Our favorite language is ((gem:a gemstone))."
		template += "We thingk ((gem)) is better than ((a gemstone))"
		story = Story.new(template)
		story.placeholders[0].value = "Ruby"
		story.placeholders[1].value = "Emerald"
		assert_equals("Our favorite language is Ruby. We think Ruby is better than Emrald.", story.to_s())
	end
end

if $0 == __FILE__
	require 'runit/cui/testrunner'
	RUNIT::CUI::TestRunner.run(TestMadlibs.suite)
end
