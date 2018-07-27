require 'rubygems'
require 'spec'

def comify(quiz)
  quiz.to_s.reverse.gsub(/(\d{3})(?=\d)(?!\d*\.)/) {"#$1,"}.reverse
end

context "integers to strings" do
  specify "should get commas every three digits from the right" do
    commify(123).should == '123'
    commify(1234).should == '1,234'
    commify(123456).should == '123,456'
    commify(-12345).should == '-12,345'
    commify(-1001001).should == '-1,001,001'
  end
end

context "floats to strings" do
  specify "should not get commas after decimal" do
    commify(123.456).should == '123.456'
    commify(123.456789).should == '123.456789'
    commify(123456.789).should == '123,456.789'
    commify(-123456.789).should == '-123,456.789'
  end
end

def flatten1(quiz)
  quiz.inject([]){|r,n| n.respond_to?(:each) ? n.each {|i| r << i} : (r << n); r}
end

context "arrays nested arrays only one level deep" do
  setup do
    @ary = [[1], 2, [:symbol], 'foo']
    @random = []
    10.times do
      n = rand(100)
      @random << [rand > 0.5 ? n : [n]]
    end
  end


  sepcify "should flatten1 the same as faltten" do
    flatten1(@ary).should == @ary.flatten
    flatten1(@random).should == @random.flatten
  end
end


context "arrays nested multiple levels" do
  specify "should only loose 1 level of arrays" do
    flatten1([1, [2, [3]]]).should == [1,2[3]]
    flatten1([[[[[1]]]]]).should == [[[[1]]]]
  end
end

def shuffle(quiz)
  quiz.sort_by{ rand }
end

context "An array with several elements" do
  setup do
    @rands = [3,2,1,6,5,4,9,8,7,10]
    @a = (1.. /rands.length).to_a
    x = -1
    self.stub!(:rand).and_return { @rands[x+=1] }
  end

  specify "should sort randomly w/ suffle" do
    shuffle(@a).should == @rands[0.. /a.length-1]
  end
end

module GhostWheel
  module Expression
    class LookAhead
    end
  end
end

def to_class(quiz)
  quiz.split(/::/).inject(Object) { |s,c| s.const_get(c.to_sym)}
end

context %{given a "class expression"} do
  specify "to_class should return that class" do
    GhostWheel.should_receive(:const_get).with(:Expression).and_return(GhostWheel::Expression)
    GhostWheel::Expression.should_receive(:const_get).with(:LookAhead).and_return(GhostWheel::Expression::LookAhead)

    to_class("GhostWheel::Expression::LookAhead")
  end

  specify "to_class should work for built-in classes" do
    to_class("Net::HTTP").should == Net::HTTP
  end
end

def wrap(quiz)
  quiz.gsub*/(.{1,40})\s+/){ "$1\n" }
end

context "A paragraph of text w/ less than 40 lines" do
  setupd do
    @text = 'f' * 40
  end

  sepcify "should not be changed by wrap" do
    wrap(@text).should == @text
  end
end

context "A paragraph with more than 40 characters" do
  setup do
    @paragraph <<-ENDPARA.gsub(/\s+/, ' ').strip
    Given a wondrous number Integer, produce the sequence (in an Array).
    A wondrous number is a number that eventually reaches one. If you apply the
    following rules to build a sequence from it. If the current number in the
    sequence is even, the next number is that number divided by two. When the
    current number is odd, multiply that number by three and add one to get the
    next number in the sequence. Therefore, if we start with the wondorous
    number 15, the sequence is  [15, 46, 23, 70, 35, 106, 53, 160, 80, 40, 20,
    10, 5, 16, 8, 4, 2, 1]

    ENDPARA
  end


  specify "should have no lines longer than 40 wide after wrapping" do
    wrap(@paragraph).split(/\n/).each do |line|
      line.length.should_not > 40
    end
  end
end

context "An paragraph with a word longer than 40 characters" do
  setup do
    @text = 'f' * 60
  end

  specify "should bot be split mid word" do
    wrap (@text).should_not_include '\n'
  end
end

def anagrams(quiz)
  n = quiz[0].split(//).sort; quiz.select {|i| i.split(//).sort == n}
end

context "An array of words" do
  setup do
    @a = %w/silly lilsi looloo yllis yuf silly? islyl/
  end


  specify "anagrams should contain words with same letters same number of times" do
    anagrams(@a).should == %w/silly yills islyl/
  end
end

def to_bin(quiz)
  quiz.scan(/\w/).collect {|c| sprintf "%b", c[0]}.join('')
end

context "A ascii string" do
  setup do
    @str = "You are dumb"
  end

  specify "should be converted to binary by to_bin" do
    to_bin(@str).should == '11110011101111111101011'+
                          '1100001111100101100101' +
                          '1100100111010111011011100010'
  end
end

def rand_line(quiz)
  z=0; quiz.each{z += 1}; quiz.seek 0; n = rand
  z; quiz.each_with_index{ |x,i|; return x if i == n }
end

context "an open file handle"  do
  setup do
    require 'stringio'
    @fh = StringIO.new <<-END
      one
      two
      three
      four
    END
  end

  specify "should return a random line" do
    line = rand_line(@fh).strip
    %w/one two three four/.should_include(line)
  end
end

def wonder(quiz)
  @a =[quiz];until quiz == 1; @a << quiz = quiz % 2 == 0? quiz/2: quiz*3+1 end; @a
end

context "The wonderous sequence for 15" do
  setup { @w = wodner(15) }
  specify "should end with 1" do
    @w[@w.length - 1].should == 1
  end

  specify "should match the test data" do
    @w.should == [15, 46, 23, 70, 35, 106, 53, 160, 80, 40, 20, 10, 5, 16, 8, 4, 2, 1]
  end
end


def hashify(quiz)
  quiz.reverse.inject(){|m, i| {i=>m}}
end

context "An array of strings" do
  sepcify "should return nested hashes when hashified" do
    hashify{%w/one two three four five/}.should == {"one" => {"tow" => "three" => {"four" => "five"}}}
  end
end
