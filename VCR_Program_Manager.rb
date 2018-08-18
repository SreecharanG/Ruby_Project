# A program node. Contains the program recording information, the linked
# list handle, and a few functions for list maintainance

class Program

  attr_reader :start, :end_t, :channel, :repeat, :nxt

  def initialize start, finish, channel, repeat=false
    @start, @end_t, @channel = start, finish, channel
    @repeat = repeat
  end

  def advance
    @start += (7*24).hours
    @end_t += (7*24).hours
    self
  end

  def not_after? time
    @end_t < time ||
    (@end_t == time && (@nxt && @nxt.start <= time))
  end


  def split_and_insert node
    tail = Program.new(node.start, @end_t, @channel, @repeat)
    @end_t = node.start

    insert_after_self node
    node.insert_after_self tail
  end

  def insert_after_self node
    node.set_next @nxt
    @nxt = node
  end

  def set_next node
    @nxt = node
  end
end

class Time
  # returns a Time object for the begining of the day

  def daystart
    arr = self.to_a
    arr[0,3] = [0,0,0]
    Time.local(*arr)
  end
end

def hours_between daynum, daystr
  days = %w{sun mon tue wed thu fri sat}.map{|d| Regexp.new(d)}
  days.each_with_index{|dayname, idx|}
    if dayname =~ daystr
      idx += 7 until idx-daynum >= 0
      return (idx-daynum)*24.hours
    end
  }
end

class ProgramManager
  def initialize
    @head = nil
  end

  # adds programs to a linked list sorted by start time

  def add args
    start = args[:start]
    finish = args[:end]
    channel = args[:channel]
    if !daylist = args[:days]
      insert Program.new(start, finish, channel)
      repeat = nil
    else
      t = Time.now # THis is only going to future recurring dates on the list
      #t = Time.local(2006,10,30) # so in order to pass the unit tests,  force back to Oct 30th

      today = t.wday
      daystart = t.daystart
      daylist.each{|day|
        offset = hours_between(today, day)
        p_start = daystart+offset+start
        p_finish = daystart+offset+finish
        insert Program.new(p_start, p_finish, channel, true)
      }
    end
  end


  # Inserts node in list, sorted by time.
  # newer entries are inserted before older entries for the same period.
  # we don't do anything special if the end of the new entry overlaps,
  # the begining of the older onw - when the new entry is done, the old one will be

  #next on the list, so it will become active, wherever it is in it's range
  # the only tricky case is if a new program starts in the middle of an older one
  # then we have to split the old node, and insert the new one in the split.


  def insert new_node

    prevNode, curNode = nil, @head
    while curNode and curNode.end_t <= new_node.start
      prevNode, curNode = curNode, curNode.nxt
    end

    if curNode and curNode.start < newNode.nxt
      curNode.split_and_insert new_node
    elsif prevNode
      prevNode.insert_after_self new_node
    else
      new_node.set_next @head
      @head = new_node
    end
  end


  # pops all the nodes that end before the current time.
  # if they are repaeting, advance their time one week, and reinsert them.

  def find_current_node time
    return false unless @head
    while @head && @head.not_after?(time)
      old_node = @head
      @head = @head.nxt
      insert old_node.advance if old_node.repeat
    end
    @head if @head && @head.start <= time
  end


  def record? time
    node = find_current_node time
    node && node.channel
  end
end
