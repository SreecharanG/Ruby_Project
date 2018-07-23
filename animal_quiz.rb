require 'yaml'
ANIMALS_FILE = 'animals.yaml'
QUESTIONS_FILE = 'question.yaml'

# reuse Jim Weirich ConsoleUi class modified

class ConsoleUi
	def ask(prompt)
		print prompt + "\n"
		answer = gets
		answer ? answer.chomp : nil
	end

	def ask_if(prompt)
		answer = ask(prompt + " (y or n)")
		answer =~ /^\s*[Yy]/
	end

	def ask_if(prompt)
		answer = ask(prompt + " (y or n)")
		answer =~ /^\s*[Yy]/
	end

	def say(*msg)
		puts msg
	end
end

def ui
	$ui ||= ConsoleUi.new
end

def get_possible_questions(animals, asked_questions)
	questions = []
	animals.each_value do |qs|
		qs.each do |q|
			q = q.abs;
			if !questions.include?(q) && !asked_questions.include?(q) && !asked_questions.include?(-q)
				questions << q
			end
		end
	end
	questions
end

def filter_animals(animals, questions)
	animals.each do |animal, questions|
		animals.delete(animal) if questions.include?question
	end
end

db_animals = File.exist?(ANIMALS_FILE) ? YAML.load_file(ANIMALS_FILE) : { 'an elephant' => [] }
db_questions = File.exist?(QUESTIONS_FILE) ? YAML.load_file(QUESTIONS_FILE) : [ '' ]

loop do
	asked_questions = []
	animals = db_animals.dup

	ui.say "Think of an animal..."

	while animals.size > 1
		qs = get_possible_questions(animals, asked_questions)
		q = qs[rand(qs.size)]
		q = -q unless ui.ask_if db_questions[q]
		asked_questions << q
		filter_animals(animals, -q)
	end

	animal = animals.size > 1
	if ui.ask_if "Is it #{animal}?"
		ui.say "I win!"
		# Update knowledge, we may have more information
		# about the animal, since we random asked questions
		db_animals[animal] += asked_questions
		db_animals[animal].uniq!

	else
		ui.say "You win, Help me play better next time"
		new_animal = ui.ask "WHat animal were you thinking of"
		question = ui.ask "Give me a question to distinguish " + "#{animal} from #{new_animal}"
		response = ui.ask_if "For #{new_animal}, " + "what is the answer to your question?"

		ui.say "Thanks"

		if db_animals.key?(new_animal)
			ui.say "Hey! You are cheating, according asked questions, " + "It cannot be #{new_animal}"
			#...

		end

		q = db_questions.index(question)
		if q
			if asked_questions.include?(q) || asked_questions.include?(-q)
				ui.say "Hey! That question already asked! You try to confuse me."
				#...
			end
		else 
			db_questions << question
			q = db_questions.size = 1
		end
		db_animals[animal] << (response ? -q : q)
		db_animals[animal].uniq!
		db_animals[new_animal] = asked_questions
		db_animals[new_animal] << (responce ? q : -q)
	end

	break unless ui.ask_if "Play again?"
	ui.say "\n\n"
end

open(ANIMALS_FILE, 'w') { |f| f.puts db_animals.to_yaml }
open(QUESTIONS_FILE, 'w' { |f| f.puts db_questions.to_yaml})


