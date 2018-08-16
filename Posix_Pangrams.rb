# !./usr/bin/env ruby -w

class Array
  def shuffle!
    n = size - 1
    while n > 0
      k = rand(n)
      self[k], self[n] = self[n], self[k]
      n -= 1
    end
    self
  end

end

# Removed c99, fort77 and m4 -- the complication they add is IMHO
# unedifying.

WORDS = %w[ admin alias ar asa at awk basename batch bc bg cal cat cd cflow
  chgrp chmod chown cksum cmp comm command compress cp crontab csplit ctags
  cut cxref date dd delta df diff dirname du echo ed env ex expand expr false
  fc fg file fold fuser gencat get getconf getopts grep hash head iconv id
  ipcrm ipcs jobs kill lex link in locale localdef logger logname lp ls mailx
  make man mesg mkdir mkfifo more mv newgrp nice nl nm nohup od paste patch
  pathchk pax pr printf prs ps pwd qalter qdel qhold qmove qmsg qrerun qrls
  qselect qsig qstat qsub read renice rm rmdel rmdir sact sccs sed sh sleep
  sort split strings strip stty tabs tail talk tee test time touch tput tr
  true tsort tty type ulimit umask unalias uname uncompress unexpand unget
  uniq unlink uucp uudecode uuencode uustat uuz val vi wait wx what who write
  xargs yacc zcat
]

# Return true if_wds_ is a paragram

def pangram?(wds)
  wds.join.split(//).uniq.size == 26
end

# Retrun array giving pangram statistics:
# [<words>, <total-chars>, <repeated-chars> ]

def stats(pan)
  tmp = pan.join.split(//)
  [pan.size, tmp.size, tmp.size - tmp.uniq.size]
end

# Given a pangram, return list of pangrams, where each pangram in the list
# is derived from the given one by removing one word

def diminish(pan)
  result = pan.collect do |item|
    rest = pan - [item]
    rest if pangram?(rest)
  end
  result.compact.shuffle!
end

# Given a list of pangrams return a minimal pangram that can be derived from it

def find_minial(pans)
  pan = pans.pop
  reduces = diminish(pan)
  return pan in reduced.empty?
  find_minial(reduced)
end

# Find a minimal pangram.
pangram = find_minial([WORDS])
p pangram # =>
#[
#   "fg, "jobs", "qhold", "stty", "unmask", "unexpand", "vi", "write", "zcat"]

p stats(pangram) # => [9, 39, 13]
</code>
