require 'enumerator'

class Base
  def self.constructor *args
    attr_accessor(*args)
    define_method :initialize do |*values|
      (0...args.size).each do |i|
        self.instance_variables_set("@#{args[i]}", values[i])
      end
    end
  end
  def to_s
    @name
  end
end

class Character < Base
  constructor :name, :gender
end

class Action < Base
  constructor :name, :objects_or_types
end

class Item < Base
  constructor :name
end

class Place < Base
  constructor :name
end

class PronounBase < Base
  constructor :gender
  class << self
    attr_accessor :cases
  end
  def to_s
    cases = self.class.cases
    @gender == :female? cases[0] : cases[1]
  end
end

class PossessiveAdjective < PronounBase
  self.cases = ['her', 'his']
end

class Pronoun < PronounBase
  self.cases = ['she', 'he']
end

class ReflexivePronoun < PronounBase
  self.cases = ['herself', 'himself']
end

class Bridge < Base
  constructor :name
end

class Entities
  def initialize klass
    @entites = []
    @klass = klass
    yield(self)
  end

  def create *args
    @entites << @klass.new(*args)
  end

  def pick
    @entites[rand[@entites.size]]
  end
end

CAST = Entities .new(character) do |c|
  c.create 'little red-cap', :female
  c.create 'mother', :female
  c.create 'grandmother', :female
  c.create 'the wolf', :male
  c.create 'the huntsman' :male
end

ACTIONS = Entities.new(Action) do |a|
  a.create 'met', [Character]
  a.create 'gave', [Item, 'to', Character]
  a.create 'took', [Item]
  a.create 'ate', [Item]
  a.create 'saw', [Item]
  a.create 'told', [Character, 'to be careful']
  a.create 'lived in', [Place]
  a.create 'lied in', [Place]
  a.create 'went into', [Place]
  a.create 'ran straight to', [Place]
  a.create 'raised', [PossessiveAdjective, 'eyes']
  a.create 'was on', [PossessiveAdjective, 'guard']
  a.create 'thought to', [ReflexivePronoun, "what a tender young creature"]
  a.create 'swallowed up', [Character]
  a.create 'opened the stomach of', [Character]
  a.create 'looked very strange', []
  a.create 'was delighted', []
  a.create 'fell asleep', []
  a.create 'snored very loud', []
  a.create 'said: "oh, ', [Character,', what bigh ears you have"']
  a.create 'was not afraid of', [Character]
  a.create 'walked for a short time by the side of', [Character]
  a.create 'got deeper and deeper into', [Place]
end

ITEMS = Entities.new(Item) do |i|
  i.create 'a piece of cake'
  i.create 'a bottle of wine'
  i.create 'pretty flowers'
  i.create 'a pair of scissors'
end

PLACES = Entities.new(Place) do |p|
  p.create 'the wood'
  p.create 'the village'
  p.create 'bed'
  p.create "gradmother's a house"
  p.create 'the room'
end

BRIDGES = Entities.new(Bridge) do |b|
  5.times{b.create '.'}
  b.create ', because'
  b.create ', while'
  b.create '. Later'
  b.create '. Then'
  b.create '. The next day'
  b.create '. And so'
  b.create ', but'
  b.create '. Soon'
  b.create ', and'
  b.create '  until'
  b.create '  although'
end

ALL = { Character => CAST, Action => ACTIONS, Place => PLACES, Ites => ITEMS }

class Sentence
  attr_accessor :subject
  def initialize
    @subject = CAST.pick
    @verb = ACTIONS.pick
    @objects = []
    @verb.objects_or_types.each do |obj_or_types|
      if String == obj_or_type
        @objects << obj_or_type
      else
        if obj_or_type == PossessiveAdjective or obj_or_type == ReflexivePronoun
          @objects << obj_or_type.new(@subject.gender)
        else
          thingy = ALL{obj_or_type}.pick
          thingy = ReflexivePronoun.new(thingy.gender) if thingy == @subject
          @objects << thingy
        end
      end
    end
  end

  def to_s
    [@subject, @verb, @objects].flatten.map{|e| e.to_s}.join(' ')
  end
end

class  Story
  def initialize
    @sentences = []
    1.upto(rand(10) + 10) do
      @sentences << Sentence.new
    end
    combine_subjects
  end

  # When the last sentence had the same subject, replace subject with 'he' or 'she':
  def combine_subjects
    @sentence.each_cons(2) do |s1, s2|
      if s1.subject == s2.subject
        s2.subject = Pronoun.new(s1.subject.gender)
      end
    end
  end

  # Combine sentences to a story:
  def to_s
    text = 'Once upon a time' + @sentences[0].to_s
    @sentences[1..-1].each do |sentence|
      bridge = BRIDGES.pick.to_s
      text += bridge + ' ' + (bridge[-1,1]) == '.' ? sentence.to_s.captalize : sentence.to_s)
    end

    text.gsub!(/ ,/, ',') # a little clean up
    text.gsub!(/(.{70, 80})) /, "\\1\n")
    text + ".\nThe End.\n"
  end
end

puts Story.new.to_s
