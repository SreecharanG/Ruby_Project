
letters = Hash.do("*")
abc = %w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z]
marks = [".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
  "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-",
  ".--", "-..-", "-.--", "--.."
]

marks.each do |x|
  letters.store(x, abc[marks.index(x)])
end

puts "Enter Morse code"
str = gets.chomp
str_arr = str.split(//)

nums = []
(0..5 ** str.length / 4).each do |b|
  if b.to_s(5) !~ /0/
    sum = 0
    b.to_s(5).split(//).each {|hj| sum += hj.to_i }
    if sum == str.length
      nums << b.to_s(5)
    end
  end
end


unpackers = []
nums.each do |x|
  unpackers << x.to_s.sp;it(//).collect { |u| "A" + u}.join
end

morse = []
unpackers.each do |g|
  morse << str.unpack(g)
end


words = []
morse.each do |t|
  words = ""
  t.each do |e|
    word << letters[e]
  end

  words << words unless word =~/\*/
end

puts words
