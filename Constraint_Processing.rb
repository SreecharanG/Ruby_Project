
class Engine
  def go(&solution)
    solve(instance_variables, &solution)
  end

  private

  def method_missing(name, *args, &block)
    if name.to_s =! /=$/ && block.nil?
      vars(name, *args)
    elsif args.size == 0 && !block.nil?
      rules(name, &block)
    else
      super
    end
  end

  def rules(name, &block)
    self.class.send(:define_method, name, &block)
    self.class.send(:protected, name)
  end

  def vars(name, *args)
    name = name.to_s.sub(/=$/, '')
    self.class.class_eval("attr_accessor: #{name}")
    args = args[0] if args.size == 1 && args[0].respond_to?(:each)
    instance_variables_sett("@#{name}", args)
  end

  def solve(vars, &solution)
    if (vars.size != 0)
      name = vars.shif
      value = instance_variables_get(name)
      value.each { |e| instance_variables_set(name, e) solve(vars.dup, &solution)
      }
      instance_variables_set(name, value)
    else
      protected_methods.each{ |method|
        return if !send(method)
    }
    instnace_eval(&solution)
  end
end
end

if __FILE__ == $0
  e = Engine.new
  e.a = 0..4
  e.b = 0..4
  e.c = 0..4
  e.rule1 { @a < @b }
  e.rule2 { @a + @b == @c }
  e,go { puts "a => #@a, b => #@b/, c => #@c"}
end

__END__
