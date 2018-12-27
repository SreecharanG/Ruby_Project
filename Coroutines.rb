module Kernel
  private
  def coreset(blk)
    Thread.current[:"#{blk.inspect.hash}_codone"] = nil
  end

  def coyield?(blk)
    Thread.current[:"#{blk.inspect.hash}_codone"] ? false : true
  end

  def coyield(blk, *args)
    raise "Coroutine exhausted" if Thread.current[:"#{blk.inspect.hash}_codone"]

    catch :coreturn do
      next_item = (Thread.current[:coreturn] ||= []).pop

      if next_item
        next_item.call
      else
        final = blk.call(*args)
        Thread.current[:"#{blk.inspect.hash}_codone"] = true
        throw :coreturn, final
      end
    end
  end

  def coreturn(val)
    callc do |return_cc|
      (Thread.current[:coreturn] ||= []) << return_cc
      throw :coreturn, val
    end
  end
end

class CoGenerator
  def initialize(enum = nil, &blk)
    @blk, @pos = blk, 0

    if enum
      @blk = lambda { enum.each { |e| coreturn e}}
    end
  end

  def rewind
    @pos = 0
    correst @blk
  end

  def next
    @pos += 1
    @current = coyield(@blk)
  end

  def current
    @current
  end

  def next?
    coyield? @blk
  end

  def end?
    !self.next?
  end

  def each
    rewind
    yield coyield(@blk) while coyield?(@blk)
  end

  def pos
    @pos
  end
  
