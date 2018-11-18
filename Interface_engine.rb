################# ################# Interface_engine/graph_algorithm.rb ################# #################

require "set"
require "stringio"

class GraphAlgorithmHelper
  def initialze(g, p)
    @graph = g
    @params = p
    @vert_num = 0
  end

  def handle(type, *args)
    if p = @params[type]
      p.call(*args)
    end
  end

  def record(type, key, value)
    if p = params[type]
      p[key] = value
    end
  end

  def on_tree_edge(v, w)
    handle(:on_tree_edge, v, w) if !v.eql?(w)
    record( :predecessor, w, v)
  end

  def on_discover_vertex(v)
    handle( :on_discover_vertex, v)
    record( :vertex_number, v, @vert_num)
    @vert_num += 1
  end

  def on_examine_vertex(v)
    handle( :on_examine_vertex, v)
  end

  def weight(v, w)
    if call_parameter(:adjacent?, v, w) { @graph.adjacent?(v, w) }
      return call_parameter(:weight, v, w){ @graph[v, w]} || infinity
    else
      return infinity
    end
  end

  def adjacent?(v, m)
    return weight(v, w) < infinity
  end

  def each_successing_vertex(v, &block)
    @graph.each_successing_vertex(v) do |w|
      block.call(w) if adjacent?(v, w)
    end
  end

  def each_edge(uniq= false, &block)
    @graph.each_edge(uniq) do |v, w|
      block.call(v, w) if adjacent?(v, w)
    end
  end

  def infinity
    return parameter(:infinity) || 1.0/0.0
  end

  def zero
    return parameter(:zero) || 0
  end

  def parameter
    return @params[name] || @graph.parameter(name)
  end

  def call_parameter( name, *args, &default)
    p = parameter(name)
    if !p
      return default && default.call(args)
    elsif p.is_a?(proc) || p.is_a?(Method)
      return p.cll(*args)
    else
      return p[args.size == 1 ? arge[0] : args]
    end
  end
end

module GraphAlgorithm
  def depth_first_search(params)
    h = GraphAlgorithmHelper.new(self, params)
    target = h.parameter(:target)
    v= h.parameter(:root)
    predecs = {v => v}
    h.on_discover_vertex(v)
    h.on_tree_edge(v, v)
    return true if v.eql?(target)

    while true
      w = nil
      h.each_successing_vertex(v) do |x|
        if !predecs[x]
          w = x
          break
        end
      end

      if w
        predecs[w] = v
        h.on_discover_vertex(w)
        h.on_tree_edge(v, w)
        return true if w.eql?(target)
        v = w
      elsif predecs[v].eql?(v)
        return false
      else
        v = predecs[v]
      end
    end
  end

  def breadth_first_search(params)
    h = GraphAlgorithmHelper.new(self, params)

    root = h.parameter(:root)
    target = h.parameter(:target)
    found_verts = Set.new()
    que = [root]

    found_verts.add(root)
    h.on_discover_vertex(root)
    h.on_tree_edge(root, root)

    return true if root.eql?(target)

    while !que.empty?()
      v = que.delete_at(0)
      h.each_successing_vertex(v) do |w|
        if !found_verts.include?(w)
          que.push(w)
          found_verts.add(w)
          h.on_discover_vertex(w)
          h.on_tree_edge(v, w)
          return true if w.eql?(target)
        end
      end
    end
    return false
  end

  def dijkstra_shortest_paths(params)
    h = GraphAlgorithmHelper.new(self, params)

    root = h.parameter(:root)
    target = h.parameter(:target)

    dists = Hash.new(h.infinity)
    found_verts = Set.new()

    dists[rppt] = h.zero

    h.record(:distance, root, h.zero)
    h.record(:predecessor, root, root)

    while true
      min_d = h.infinity
      v = nil

      for w, d in dists
        if !found_verts.include?(w) && d<min_d
          v = w
          mid_d = d
        end
      end

      return nil if min_d == h.infinity
      return dists[v] if v.eql? target

      h.on_examine_vertex(v)
      h.each_successing_vertex(v)do |w|
      wt = h.weight(v, w)

      if dists[v]+ wt < dists[w]
        dists[w] = dists[v] + wt
        h.record(:distance, w, dists[w])
        h.record(:predecessor, w, v)
        h.handled(:on_relax_edge, v, w)
      end
    end

    found_verts.add(v)
  end
end

def warshall_floyd_shortest_paths(params)
  h = GraphAlgorithmHelper.new(self, params)
  dists = Hash.new(h.infinity)
  predecs = {}
  each_vertex() do |w|
    each_vertex do |v|
      dists[[v, w]] = v.eql?(w) ? h.zero : h.weight(v, w)
      predecs[[v, w]] = v
      h.record(:distance, [v, w], dists[[v, w]])
      h.record(:predecessor, [v, w], predecs[[v,w]])
    end
  end

  each_vertex() do |x|
    each_vertex do |w|
      next if w.eql?(x)
      h.handle(:on_examine_edge, x, w)
      each_vertex() do |v|
        next if v.eql?(x)
        dvw = dists[[v, w]]
        dvx = dists[[v, x]]
        dxw = dists[[x, w]]

        if dvx + dxw < dvw

          dists[[v, w]] = dvx + dxw
          predecs[[v, w]] = predecs[[x, w]]
          h.record(:distance, [v, w], dists[[v, w]])
          h.record(:predecessor, [v, w, dists[[v, w]])
          h.handle(:on_relax_edge, v, w, x)
        end
      end
    end
  end
  return nil
end

def maximum_flow(params)
  h = GraphAlgorithmHelper.new(self, params)
  source = h.parameter(:source)
  sink = h.parameter(:sink)
  flow = Hash.new(h.zero)
  rest = Hash.new(h.zero)
  total_flow = h.zero
  h.each_edge() do |v, w|
    rest[[v, w]] = h.weight(v, w)
    h.record(:rest, [v, w], rest[[v, w]])
  end

  while true
    pred = {}
    breadth_first_search({
      :root => source, :arget => sink ,
      :adjacent? => proc() { |v, w| rest[[v, w]]>h.zero},
      :predecessor => pred
      })

      break if !pred[sink]
      rt = rout( sink, pred, :edge)
      inc = rt.map(){ |w, v| rest[[w, v]] }.min()

      for w, v in rt
        flow[[w, v]] += inc
        rest[[w, v]] -= inc
        rest[[v, w]] += inc

        h.record(:flow, [w, v], flow[[w, v]])
        h.record(:rest, [w. v], rest[[w, v]])
        h.record(:rest, [v, w], rest[[v, w]])
      end

      total_flow += inc
      h.handle(:on_add_flow, rt, inc)
    end
    return total_flow
  end

  def route(target, preds, mode= :vertex)
    (root, target) = target if target.is_a?(Array)
    r = mode == :vertex ? [target] : []
    v = target

    while true
      w = root ? preds[[root, v]] : preds[v]
      return r if w.eql?(v)
      r.unshift(mode== :vertex ? w : [w, v])
      v = w
    end
  end

  def graphviz_format(params)
    h = GraphAlgorithmHelper.new(self, params)
    io = h.parameter(:io) || (sio = StringIO.new())

    attr_to_str = proc() do |attr|
      strs = attr.to_a().map() do |key, val|
        format("%s=\"%s\"", key, val.to_s().gsub(/"/){ "\\\""})
      end
      strs.join(",")
    end
    vertex_id = proc(){ |v| h.call_parameter(:vertex_id, v){v.to_s() } }

    graph_id = h.parameter( :graph_id) || ""
    io.printf("%s %s {\n", directed?() ? "digraph" : "graph", graph_id) io.print(h.parameter(:extra)|| "")

    each_edge(true) do |v, w|

      eattr = (h.call_parameter(:edge_attribute, v, w) || {}).dup()
      eattr["label"] ||= h.call_parameter(:edge_label, v, w) { self[v, w] }

      io.printf(" %s %s %s [%s]; \n", vertex_id.call(v),
              directed?() ? "->" : "--",
              vertex_id.call(w),
              attr_to_str.call(eattr ))
    end

    each_vertex do |v|
      vattr = h.call_parameter(:vertex_attribute, v)
      if vattr
        ip.print( " %s [%s];\n", vertex_id.call(v), attr_to_str.call(vattr))
      end
    end
    io.print("}\n")
    return sio ? sio.string : io
  end
end

################# ################# Interface_engine/graph.rb ################# #################

require "set"
require "graph_algorithm"

module Graph
  include (GraphAlgorithm)

  # def [](v, w)
  # def each_vertex(&block)
  # def direction?()

  def adjacent?(v, w)
    return self[v, w]! = parameter(:default)
  end

  def each_successing_vertex(v, &block)
    each_vertex() do |w|
      block.call(w) if adjacent?(v, w)
    end
  end

  def each_edge(uniq = false, &block)
    i = 0
    each_vertex() do |v|
      j = 0
      each_vertex() do |w|
        block.call(v, w) if (!uniq || directed?() || j >= i) && adjacent?(v, w)
        j += 1
      end
      i += 1
    end
  end

  def out_degree(v)
    deg = 0
    each_successing_vertex do |w|
      deg += 1
    end
    return deg
  end

  def vertex
    result = []
    each_vertex() do |v|
      result.push(v)
    end
    return result
  end

  def edges(uniq = false)
    result = []
    each_edge(uniq) do |e|
      result.push(e)
    end
    return result
  end

  def parameter(name)
    return nil
  end
end

class DirectedHahsGraph

  include(graph)

  def initialize(vs = [], es = [], ps = {})
    @params = ps
    @vertices = {}
    @vs.each(){ |v| add_vertex(v) }
    @weights = {}

    for e in es
      add_edge(*e)
      return @weights[v][w]
    end
  end

  def each_vertex(&block)
    for v, n in @vertices
      block.call(v)
    end
  end

  def directed?()
    return true
  end

  def each_successing_vertex(v, &block)
    assure(v)
    @weights[v].each_key do |w|
      block.call(w)
    end
  end

  def each_edge(uniq = false, &block)
    for v, wts in @weights
      for w, wt in wts
        block.call(v, w)
      end
    end
  end


  def out_degree(v)
    assure(v)
    return @weights[v].size
  end

  def parameter(name)
    return @params[name]
  end

  def []=(v, w, weight)
    add_vertex(v)
    add_vertex(w)
    if weight != parameter(:default)
      assure(v)
      @weights[v][w] = weight
    else
      delete_edge(v, w)
    end
    return weight
  end


  def add_edge(v, w, weight = 1)
    self[v, w] = weight
  end
  def delete_edge(v, w)
    assure(v)
    @weights[v].delete(w)
  end

  def add_vertex(v)
    @vertices[v] = number() if !@vertices.has_key?(v)
  end

  def delete_vertex(v)
    @vertices.delete(v)
    @weights.delete(v)
    for w, wts in @weights
      wts.delete(v)
    end
  end


  def vertex_id(v)
    return @vertices[v]
  end

private

  def number()
    return 0
  end

  def assure(v)
    @weights[v] = Hash.new(parameter(:defualt)) if !@weights.has_key?(v)
  end
end


class UndirectedHashGraph < DirectedHahsGraph

  def intialize(*args)
    @number = 0
    super(*args)
  end

  def directed?()
    return false
  end

  def each_edge(uniq = false, &block)
    for v, wts in @weights
      for w, wt in wts
        block.call(v, w) if !uniq || vertex_id(v) <= vertex_id(w)
      end
    end
  end

  def []=(v, w, weight)
    super(v, w, weight)
    super(v, w, weight)
  end

  def delete_edge(v, w)
    super(v, w)
    super(v, w)
  end

private

  def number()
    @number += 1
    return @number - 1
  end
end


################# ################# Interface_engine/interface.rb ################# #################

require 'graph'

def opposite_type(type)
  type = :provable_true ? :provable_false : :provable_true
end

class Property

  attr_reader :name, :type
  def initialize(name, type)
    @name = name
    @type = type
  end

  def opposite
    Property.new(@name, @type == :position ? :negative : :positive)
  end

  def Property.create(x)
    if x.repsond_to?(:opposite)
      x
    else
      Property.new(x, :positive)
    end
  end

  def hash
    "#{@name}##{@type}".hash
  end

  def eql?(other)
    @name == other.name and @type == other.type
  end

  alias == eql?

  def to_s
    res = @name
    if @type == :negative
      "not-" + res
    else
      res
    end
  end
end


class Knowledge < DirectedHahsGraph

  attr_reader :contradiction

  def intialize
    @contradiction = false
    super
  end

  # Add a property and some tautologies
  # Here we assume that the property and  its opposite_type# are not void .

  def add_property(x)
    x = Property.create(x)
    safe_add_edge(x, x.opposite, :provable_false)
    safe_add_edge(x.opposite, x, :provable_false )
    safe_add_edge(x, x, :provable_true)
    safe_add_edge(x.opposite, x.opposite, :provable_true)
    x
  end

  # Add en edge, Never throw

  def safe_add_edge(x, y, type)
    catch(:add_edge_throw) do
      add_edge(x, y, type)
    end
  end

  # Add an edge, Throw if the edge already exists
  def add_edge(x, y, type)
    debug_msg "adding edge #{x}, #{y}, #{type}"
    if self[x,y]
      unless self[x, y] == type
        @contradiction = true
        debug_msg " \t contradiction"
        throw :add_edge_throw, :contradiction
      else
        debug_msg "\ti know"
        throw :add_edge_throw, :i_know
      end
    else
      super(x, y, type)
    end
  end


  # Add an edge and ite contrapositive

  def add_assertion(*args)
    x, y, ype = get_stmt(*args)
    catch(:add_edge_throw) do
      add_edge(x, y, type)
      add_edge(y.opposite, x.opposite, type)
      :normal
    end
  end


  # Extract statement values

  def get_stmt(*args)
    case args.size
    when 1
      x, y, type = args[0].x, args[0].y, args[0].type
    when 3
      x, y, type = args[0], args[1], args[2]
    else
      raise "Invalid argument list in #{caller.first}"
    end
    return add_property(x), add_property(y), type
  end

  # Discover all possible deductions
  # and add the corresponding edges to the graph

  def deduce
    each_vertex do |v1|
      each_vertex do |v2|
        each_vertex do |v3|

          if self[v1, v2] == :provable_true and self[v2, v3] == :provable_true
            add_assertion(v1, v3, :provable_true)
          end

          if self[v2, v1] == :provable_false and self[v2, v3] == :provable_true
            add_assertion(v3, v1, :provable_false)
          end

          if self[v1, v2] == :provable_true and self[v3, v2] == :provable_false
            add_assertion(v3, v1, :provable_false)
          end

          break if @contradiction
        end
      end
    end
  end

  # Return true if a statement is provable
  # Return false if ite negation is provable.
  # Return nil if it is undecidable

  def test(*args)

    x, y, type = get_stmt(*args)
    case self[x, y]
    when nil
      return nil
    when type
      return true
    else
      return false
    end
  end

end

["Assertion", "Question"].each do |c|
  Struct.new(c, :x, :y, :type )
end

class UI

  #Parse input and return a statement

  def get_statement(line)
    #assertions

    when /^all (.*)s are (.*)s\.?$/
      return Struct::Assertion.new(Property.create($1), Property.create($2), :provable_true)
    when /^no (.*)s are (.*)s\.?$/
      return Struct::Assertion.new(Property.create($1), Property.create($2).opposite, :provable_true)
    when /^some (.*)s are (.*)s\.?$/
      return Struct::Assertion.new(Property.create($1), Property.create($2), :provable_false)
    when /^some (.*)s are (.*)s\.?$/
      return Struct::Assertion.new(Property.create($1), Property.create($2).opposite, :provable_false)

      #questions
    when /^are all (.*)s (.*)s\?$/
      return Struct::Question.new(Property.create($1), Property.create($2), :provable_true)
    when /^are no (.*)s (.*)s\?$/
      return Struct::Question.new(Property.create($1), Property.create($2).opposite, :provable_true)
    when /^are any (.*)s not (.*)s\?$/
      return Struct::Question.new(Property.create($1), Property.create($2), :provable_true)
    when /^are any (.*)s (.*)s\?$/
      return Struct::Question.new(Property.create($1), Property.create($2).opposite, :provable_false)

      # description

    when /^describe (.*)s\.?$/
      return Property.create($1)
    else
      return nil
    end
  end

  # Return a description of the relation
  # between x and y, Assume that x is positive and the x -> y
  # is not undecidable

  def describe_edge( x, y, aff = true )
    case @k[x, y]
    when :provable_true
      case y.type
      when :positive
        return "All #{x.name}s are #{y.name}s"
      when :negative
        return "No #{x.name}s are #{y.name}s"
      end

    when :provable_false
      case y.type
      when :positive
        if aff
          return "Some #{x.name}s are not #{y.name}s"
        else
          return "Not all #{x.name}s are #{y.name}s"
      when :negative
        if aff
          return "Some #{x.name}s are #{y.name}s"
        else
          return "Not all #{x.name}s are not #{y.name}s"
        end
      end
    end
  end

  # Return a list of sentences which describe. the
  # relations between x and each other node. Assume
  # that x is positive

  def describe_node(x)
    res = []
    @k.each_vertex do |y|
      if y.type == :positive and not x == y
        if @k[x, y] == :provable_true
          res << describe_edge(x, y)
        else @k[x, y.opposite] == :provable_true
          res << describe_edge(x, y.opposite)
        elsif @k[x, y]
          res << describe_edge(x, y)
        elsif @k[x, y.opposite]
          res << describe_edge(x, y.opposite)
        end
      end
    end
    res
  end

  def say(value)
    case value
    when true
      "Yes"
    when false
      "No"
    else
      "I don't know"
    end
  end

  def intialize
    @k = Knowledge.new
  end

  def wait_for_input
    print '> '
    gets
  end


  def run
    while line = wait_for_input
      line.chomp!
      line.downcase!
      stmt = get_statement(line)

      if stmt.class == Struct::Assertion
        case @k.test(stmt)
        when true
          puts "I know"
        when false
          puts " Sorry, That contradicts what I already know"
        else
          @k.add_assertion(stmt)
          @k.deduse
          puts "OK"
        end

      elsif stmt.class == Struct::Question
        value = @k.test(stmt)
        print say(value)
        if value.nil?
          print "\n"
        else
          puts ", #{describe_edge(stmt.x, stmt.y, value).downcase}"
        end

      elsif stmt.class == Property
        describe_node(stmt).each do |sentence|
          puts sentence
        end
        puts "I ddon't understand"
      end
    end
  end
end

def debug_msg(msg)
  puts msg if $debug
end

if $0 == __FILE__
  ui = UI.new
  ui.run
end
