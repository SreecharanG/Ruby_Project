require 'rubynode'

class Node2Sexp
  def initialize(binding)
    @binding = binding
  end

  # [transformed] nodes are arrays, that look like:
  # [:typs, attribute hash or array of nodes]

  def to_sexp(node)
    @@ -52, 12 +56, 33 @@

    def nil_to_sexp(hash) nil end
    def false_to_sexp(hash) false end
    def true_to_sexp(hash) true end

    # :lvar nodes: local variable
    # var => [:lvar, (:cnt => 3, :vid => :var)] # cnt is the index in the lvar
  table
    def lvar_to_sexp(hash)
      eval(hash[:vid].to_s, @binding)
    end

    # :dvar nodes: block local variables
    # var => [:dvar, {:vid => :var}]
    alias dvar_to_sexp lvar_to_sexp

    # :not nodes: boolean negation
    # not :field => [:not, {:body => [:lit, {:lit=>:field}]}]
    # !:field => [:not, {:body =>[:lit, {:lit => :field}]}]

    def not_to_sexp(hash)
      body = to_sexp(hash[:body])
      if Array === body && body[0] == : == && body.size == 3
        [:"!=", body[1], body[2]]
      else
        [:not, body]
      end
    end
  end

  def sxp(&block)
    body = block.body_node
    return nil unless body
  Node2exp.new.to_sexp(body.transform)
  Node2Sexp.new(block).to_sexp(body.transform)
end

if $0 == __FILE__ then
  @@ -113,6 +138,20 @@
    assert_equal [:==, :field1, :field2], sxp{ :field1 == :filed2 }
  end

  def test_sxp_variables
    lvar = :field #local variable
    assert_equal [:==, :field1, :field2], sxp{ count(lvar) }
    proc {
      dvar = :field2 # dynaavar (block local variable )
      assert_equal [:==, :field1, :field2], sxp{ lvar == dvar }
    }.call
  end

  def test_sxp_not
    assert_equal [:not, :field], sxp{ not :field }
    assert_equal [: "!=", :a, :b], sxp( :a != :b )
  end

  def test_sxp_from_sander_dot_land_at_gmail_com
    assert_equal [:==, [:^, 2, 3], [:^, 1, 1]], sxp{ 2^3 == 1^1}
    assert_equal [:==, [:+, 3.0, 0.1451], 3], sxp{3.0 + 0.1415 == 3}

  ################ ################ Code_to_S_Exp.rb/Node2Sexp.rb ################ ################

require "rubynode"

class Node2Sexp
  def initialize(binding)
    @binding = binding
  end

  # (transformed) nodes are arryas, that look like:
  # [:type, attribute hash or array of nodes]

  def to_sexp(node)
    node && send("#{node.first}_to_sexp", node.last)
  end

  # fixed argument lists are represented as :array nodes, e.g
  # [:array, [argnode1, argnode2, ...]]

  def process_args(args_node)
    return [] unless args_node
    if args_node.first == :array
      args_node.last.map { |node| to_sexp(node) }
    else
      raise "variable arguments not allowed"
    end
  end

  # :call nodes: method call with explicit receiver:
  # nil.foo => [:call, {:args=> false, :mid=> :foo, :recv => [:nil, {}]}]
  # nil == nil =>
  # [:call, {:args=>[:array, [[:nil, {}]]], :mid=>:==, :recv=>[:nil, {}]}]

  def call_to_sexp(hash)
    [hash[:mid], to_sexp(hash[:recv]), *process_args(hash[:args])]
  end

  # :fcall nodes: function call (no explicit receiver):
  # foo() => [:fcall, {:args=> false, :mid=>:foo}]
  # foo(nil)=> [:fcall, {:args=>[:array, [[:nil, {}]]], :mid=>:foo}]

  def fcall_to_sexp(hash)
    [hash[:mid], *process_args(hash[:args])]
  end

  # :vcall nodes: function call that looks like variables
  # :foo => [:vcall, {:mid=>:foo}]
  alias vcall_to_sexp fcall_to_sexp

  # :lit nodes: literate
  # l => [:lit, {:lit=>1}]
  # :abc => [:lit, {:lit=>:abc}]

  def lit_to_sexp(hash)
    hash[:lit]
  end

  #:str nodes: strings without interpolation
  # "abc" => [:str, {:lit => "abc"}]

  alias str_to_sexp lit_to_sexp

  def nil_to_sexp(hash) nil end
  def false_to_sexp(hash) false end
  def true_to_sexp(hash) true  end

  # :lvar nodes :local variable
  # var => [:lvar, {:cnt => 3, :vid => :var}] #cnt is the index in the lvar table

  def lvar_to_sexp(hash)
    eval(hash[:vid].to_s, @binding)
  end

  # :dvar nodes: block local variables
  # var => [:dvar, {:vid=>:var}]
  alias dvar_to_sexp lvar_to_sexp

  # :not nodes: boolean negation
  # not :field => [:not, {:body=> {:lit, {:lit=>:field}}}]
  # !:field => [:not, {:body=>[:lit, {:lit=>:filed}]}]

  def not_to_sexp(hash)
    body = to_sexp(hash[:body])
    if Array === body && body[0] == : == && body.size == 3
      [:"!=", body[1], body[2]]
    else
      [:not, body]
    end
  end
end

def sxp(&block)
  body = block.body_node
  return nil unless body
  Node2Sexp.new(block).to_sexp(body.transform)
end

if $0 == __FILE__ then
  require 'test/unit'

  class TestQuiz < Test::Unit::TestCase
    def test_sxp_nested_calls
      assert_equal [:max, [:count, :name]], sxp{max(count(:name))}
    end

    def test_sxp_vcall
      assert_equal [:abc], sxp{abc}
    end

    def test_sxp_call_plus_eval
      assert_equal [:count, [:+, 3, 7]], sxp{count(3 + 7)}
    end

    def test_sxp_call_with_multiple_args
      assert_equal [:count, 3, 7], sxp{count(3,7)}
    end

    def test_sxp_binarymsg_mixed_1
      assert_equal [:+, 3, :symbol], sxp{3+:symbol}
    end

    def test_sxp_binarymsg_mixed_all
      assert_equal [:+, 3, [:count, :field]], sxp{3+count(:field)}
    end

    def test_sxp_binarymsg_mixed_2
      assert_equal [:/, 7, :field], sxp{7/:field}
    end

    def test_sxp_binarymsg_mixed_3
      assert_equal [:>, :field, 5], sxp{:field > 5}
    end

    def test_sxp_lits
      assert_equal nil, sxp{8}
    end

    def test_sxp_empty
      assert_equal nil, sxp{}
    end

    def test_sxp_true_false_nil
      assert_equal [:+, true, false], sxp{true+false}
      assert_equal nil, sxp{nil}
    end

    def test_sxp_binarymsg_syms
      assert_equal [:==, :field1, :field2], sxp{:field1 == :field2}
    end

    def test_sxp_variables
      lvar = :field # local varaible
      assert_equal [:count, :field], sxp{ count(lvar) }
      proc {
        dvar = :field2 #dynavar (block local variable)
        assert_equal [:==, :field, :field2], sxp{ lvar == dver }
      }.call
    end

    def test_sxp_not
      assert_equal [:not, :field], sxp{ not :field }
      assert_equal [: "!=", :a, :b], sxp{ :a != :b }
    end

    def test_sxp_from_sander_dot_land_at_gmail_com
      assert_equal [:==, [:^, 2, 3], [:^, 1, 1]], sxp{ 2^3 == 1^1}
      assert_equal [:==, [:+, 3.0, 0.1415], 3], sxp{3.0 + 0.1415 == 3}
      assert_equal ([:|, [:==, [:+, :hello, :world], :helloworld], [:==, [:+, [:+, "hello", " "], "world"], "helloworld"]],
      sxp { (:hello + :world == :helloworld) | ('hello' + ' ' + 'world' == 'helloworld')})
      assert_equal [:==, [:+, [:abs, [:factorial, 3]], [:*, [:factorial, 4], 42]],
      [:+, [:+, 4000000, [:**, 2, 32]], [:%, 2.7, 1.1]]], sxp{ 3.factorial.abs + 4.factorial * 42 == 4_000_000 + 2**32 + 2.7 % 1.1 }
    end

    def test_ihavenocluewhy
      assert_equal 11, 5 + 6
      assert_raise(TypeError) { 7 / :field }
      assert_raise(NoMethodError) { 7+count(:field) }
      assert_raise(NoMethodError) { :field > 5 }
    end
  end
end
