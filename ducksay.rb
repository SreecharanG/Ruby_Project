require 'open-uri'
require 'singleton'

# Here we have a bubble machine

class Bubble
  def self.make(text)
    return '' if text.nil? or text == ''
    result = ''
    lines = text.split("\n")
    max_length = lines.max{ |a, b| a.length <=> b.length}.length
    hf = proc {|s| " #{s*(max_length + 2)} \n"}
    result << hf['_']
    case lines.length

    when 1: result << "< #{lines[0]} >\n"
    else
      pad_it = proc {|s| s.ljust(max_length)}
      result << "/ #{pad_it[lines.shift]} \\\n"
      0.upto(lines.length - 2) do |i|
        result << "| #{pad_it[lines[i]]} | \n"
      end
      result << "\\ #{pad_it[lines[-1]]} /\n"
    end

    result << hf['-']
  end
end

## Our lovely zoo, full of many wacky animals

class Zoo
  include Singleton
  attr_reader :animals
  def initialize
    @animals = {}
    current_key = nil
    DATA.each do |line|
      if line.chomp =~ /^'(\w*)':$/
        current_key = $1
        @animals[current_key] = []
      elsif current_key
        @animals[current_key] << line
      end
    end
  end

  # A random animal has escaped!

  def escape
    choices = @animals.keys
    @animals[choices[rand[choices.length]]]
  end
end

# Since I wrote this on Windows I don't have fortune but the internet does
def get_fortune
  open('http://www.coe/neu.edu/cgi-bin/fortune') do |page|
    page.read.scan(/<pre>(.*)<\/pre>/m)[0][0].gsub("\t", '   ')
  end
end

if $0 == __FILE__
  anumal = nil
  message = nil
  case ARGV[0]
  when 'list':
    puts "Your zoo contains the following animals"
    puts Zoo.instance.animals.keys.sort.join("\n")
    exit(0)

  when /\A(\w*)\.say/:
    animal = Zoo.instance.animals[$1]
    unless animal
      puts "Unknown animal #$1! Try 'list' to list your animals."
      exit(1)
    end

    if ARGV.length > 1
      message = ARGV[1..-1].join(" ")
    end

  when nil:
    animal = Zoo.instance.escape
  else
    puts "Usage: #$0 <command>",
    "Where command is",
    "\t list: to list your animals."
    "\t<animak>.say \"<message>\": to have the animal say that",
    "\t\tmessage, where the message is optional.",
    "\nWith no command the default is a random animal, with a",
    "message from fortune."
    exit(1)
  end

  unless message
    message = get_fortune
  end
  puts Bubble.make(message)
  puts animal
end

# The ASCII animals below are coutesty of http://www.ascii-art.de

__END__
'crazyduck':
'crazyduck':
    \                                _____
     \                         \\_-~~     ~~-_
      \                        /~             ~\
       \                     _|  _              |
        \                ___) ~~) ~~~--_         |
         \            _-~   ~-_   ___   \        |/
          \          /         _-~   ~-_          /
           \        |         /         \         |
            \      |  O)     |           |        |
                   |        |             |      |
                    |       |        (O   |      |
                     \       |           |      |\
                     (~-_   _-\         / _--_ / \
                      \__~~~   ~-_   _-~ /    ~\
                      /  ~---~~-_ ~~~ _-~  /|   |
                   _-~      / \  ~~--~    | |   |
                _-~                      | /   |
   ,-~~-_ __--~~                        |-~   /
   |     \                             |   _-~
    \                                 |--~~
     \                               |  |
      ~-_            _              |   |
         ~-_          ~~---__   _--~~\  |
            ~~--__                   /  |
                  ~~---___     __--~~|  |
                          ~~~~~      |  |
                                     |  |
'lazyduck':
   \
    \  .-"""-.   _.---..-;
      :.)     ;""      \/
__..--'\      ;-"""-.   ;._
`-.___.^.___.'-.____J__/-._J
'duck':
        \
         \    _.-.
         __.-' ,  \
        '--'-'._   \
                '.  \
                 )-- \ __.--._
                /   .'        '--.
               .               _/-._
               :       ____._/   _-'
                '._          _.'-'
                   '-._    _.'
                       \_|/
                      __|||
__/'
'chunkybacon':
      \
       \  __      _.._
       .-'__`-._.'.--.'.__.,
      /--'  '-._.'    '-._./
     /__.--._.--._.'``-.__/
     '._.-'-._.-._.-''-..'
'raccoon':
   \
    \              __        .-.
     \         .-"` .`'.    /\\|
       _(\-/)_" ,  .   ,\  /\\\/
      {(#b^d#)} .   ./,  |/\\\/
      `-.(Y).-`  ,  |  , |\.-`
           /~/,_/~~~\,__.-`
          ////~    // ~\\
        ==`==`   ==`   ==`
'bat':
     \
      \
    ,  \    ,
  ./(       )\.
  )  \/\_/\/  (
  `)  (^Y^)  (`
   `),-(~)-,(`
       '"'
'buffalo':
    \
     \          _.-````'-,_
      _,.,_ ,-'`           `'-.,_
    /)     (\                   '``-.
   ((      ) )                      `\
    \)    (_/                        )\
     |       /)           '    ,'    / \
     `\    ^'            '     (    /  ))
       |      _/\ ,     /    ,,`\   (  "`
        \Y,   |  \  \  | ````| / \_ \
          `)_/    \  \  )    ( >  ( >
                   \( \(     |/   |/
                  /_(/_(    /_(  /_(
'gecko':
         \
          \
              ___
       )/_  ,@  /
       |(_,' _@/
       |    /
  \)/ /    (_)/
  ((_/   ,----~
   \    (_)/
   / ,-----~
  (('  _,-.
   \\=//
'gorilla':
       \
        \
         \  ."`".
        .-./ _=_ \.-.
       {  (,(oYo),) }}
       {{ |   "   |} }
       { { \(---)/  }}
       {{  }'-=-'{ } }
       { { }._:_.{  }}
       {{  } -:- { } }
       {_{ }`===`{  _}
      ((((\)     (/))))
'gryphon':
    \                            ______
     \                ______,---'__,---'
      \           _,-'---_---__,---'
           /_    (,  ---____',
          /  ',,   `, ,-'
         ;/)   ,',,_/,'
         | /\   ,.'//\
         `-` \ ,,'    `.
              `',   ,-- `.
              '/ / |      `,         _
              //'',.\_    .\\      ,{==>-
           __//   __;_`-  \ `;.__,;'
         ((,--,) (((,------;  `--'
         ```  '   ```
'wombat':
  \            ,.--""""--.._
   \         ."     .'      `-.
    \       ;      ;           ;
     \     '      ;             )
      \   /     '             . ;
         /     ;     `.        `;
       ,.'     :         .     : )
       ;|\'    :      `./|) \  ;/
       ;| \"  -,-   "-./ |;  ).;
       /\/              \/   );
      :                 \    ;
      :     _      _     ;   )
      `.   \;\    /;/    ;  /
        !    :   :     ,/  ;
         (`. : _ : ,/""   ;
          \\\`"^" ` :    ;
                   (    )
                   ////
'seaturtle':
        /
       /        _,.---.---.---.--.._
      /     _.-' `--.`---.`---'-. _,`--.._
     /     /`--._ .'.     `.     `,`-.`-._\
          ||   \  `.`---.__`__..-`. ,'`-._/
     _  ,`\ `-._\   \    `.    `_.-`-._,``-.
  ,`   `-_ \/ `-.`--.\    _\_.-'\__.-`-.`-._`.
 (_.o> ,--. `._/'--.-`,--`  \_.-'       \`-._ \
  `---'    `._ `---._/__,----`           `-. `-\
            /_, ,  _..-'                    `-._\
            \_, \/ ._(
             \_, \/ ._\
              `._,\/ ._\
                `._// ./`-._
                  `-._-_-_.-'
'lemur':
    \             ,,
     \            ==
      \            ==
       \             ==
        \             ==
                ==     ==
              ==  ==  ==
             ==     ==
      ,  ,    ==
      |\/|   ,-..-,
  ,d__(..)\_/      \
  ;-,_`o/          |
      '-| \_,' /^| /
        ( //  /  \ \
        || \ <    \ )
       _\|  \ )   _\\
        ~`  _\|    ~`
             ~`
'koala':
      \
       \       )    (   |
        \      )    (  /    .-
        _ ,---. _   ( /    /
      (~-| . . |-~)  V    /
       \._  0  _,/       /
        / `-^-'`-._     /
       '           `-. (
      :               )E
      :          ,---' (
       .            )E (
        '._____,---'   (
               )       (
               )       (
               )       (
               )       (
'armadillo':
    \
     \           __-----.,
             .-:::,\\\\\::::,
        \|\;`:::`` \\\\\\\'':\
        /`'\\::     ||||||   '\
       / e  (\`     ||||||   , '.
     .` _.-`~\_____/`````_X__/'-__~===-
    '-~`       ~~        ~~
