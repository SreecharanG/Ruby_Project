
class MulitpleMethods < NoMethodError
  attr_reader :methods
  def initialize(methods)
    @methods = methods
    super("Mulitple Choices: " + @methods.join(' '))
  end
end

class Module
  attr_reader :abbreviated_methods

  private

  # Define a list of methods to be abbreviated
  # If atuo = true, then all the methods are abbreviated

  # class Test
  #   abbrev # All the methods of Test will be abbreviated
  # end

  # class Test2
  #   abbrev :first, :last # Only the methods firs and last may be abbreviated
  # end

  # If mulitple choices are possible, a MulitpleMethods exception is raised
  # Which contains a list of the matches

  def abbrev(auto = true, *args)
    if auto.respond_to? :to_sym
      @abbreviated_methods ||= []
      @abbreviated_methods += args.collect {|m| m.to_sym }.unshift auto.to_sym

    elsif args.empty?
      auto ? @abbreviated_methods = [] : @abbreviated_methods = nil
    else
      raise ArgumentError
    end
  end
end

class Object
  alias :abbrev_method_missing :method_missing
  def method_missing(sym, *args)
    found = abbreviated_methods.select { |m| m.to_s =~ /^#{sym}/ }

    if found.empty?
      abbrev_method_missing(sym, *args)
    elsif found.size == 1
      send found.first, *args
    else
      raise MultipleMethods.new(found)
    end
  end

  private
  def abbreviated_methods
    if self.class.abbreviated_methods.nil?
      []
    elsif self.class.abbreviated_methods.empty?
      methods
    else
      self.class.abbreviated_methods & methods.collect { |m| m.to_sym }
    end
  end
end
