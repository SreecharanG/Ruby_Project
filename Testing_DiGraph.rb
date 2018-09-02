require 'test/unit'

DiGraph = RubyQuiz73.class_under_test("james / grayproduction.net")

class TestDiGraph < Test::Unit::TestCase
  def test_construction
    graph = nil
    assert_nothing_raised(Exception) { graph = DiGraph.new }
    assert_not_nil(graph)
    assert_kind_of(DiGraph, graph)

    assert_nothing_raised(Exception) do
      graph = DiGraph.new(Array.new(rand(10)) { |i| [i * 2, i * 2 + 1]})
    end
    assert_not_nil(graph)
    assert_kind_of(DiGraph, graph)
  end

  def test_size
    graph = DiGraph.new
    assert_equal(0, graph.size)
    assert_equal(0, graph.num_edges)

    graph = DiGraph.new([1,2], [2,3])
    assert_equal(3, graph.size)
    assert_equal(3, graph.num_edges)

    graph = DiGraph.new([1,2], [2,3], [3,2])
    assert_equal(3, graph.size)
    assert_equal(3, graph.num_edges)
  end

  def test_max_length_of_simple_path_including_node
    10.times do |count|
      graph_straight_line(count)
      assert_equal(count, @graph.num_edges)
      0.upto(count) do |i| assert_equal(count, @graph.max_length_of_simple_path_including_node(i))
    end
  end


  # BUG: [0,1], [1,0] => 6 # there are only two edges
  # 10.times do |count|
  #   graph_down_and_back(count)
  #   assert_equal(count * 2, @graph.num_edges)
  #   0.upto(count) do |i|
  #     assert_equal( @graph.num_edges, @graph.max_length_of_simple_path_including_node(i) )
  #     end
  #   end
  # end

  def test_strongly_connected_component_including_node
    10.times do |count|
      graph_down_and_back(count)
      0.upto(count) do |i|
      scc = @graph.strongly_connected_component_including_node(i)
        assert_equal(@graph.size, scc.size)
        assert_equal(@graph.num_edges, scc.num_edges)
      end
    end
  end
    # BUG: [0,1],[1,2] => [0,1],[1,2] # One-way is not a strong connect
    # 10.times do |count|
    #   graph_straight_line(count)
    #   0.upto(count) do |i|
    #     scc = @graph.strongly_connected_component_including_node(i)
    #     assert_equal(count.zero ? 0 : 1, scc.size)
    #     assert_equal(0, scc.num_edges)
    #   end
    # end
    # end

  private

  def straight_line( size )
    Array.new(size) { |i| [i, i + 1] }
  end

  def graph_straight_line( size )
    @graph = DiGraph.new(*straight_line(size))
  end

  def graph_down_and_back( size )
    data = straight_line(size)
    @graph = DiGraph.new(*(data + data.reverse.map { |edge| edge.reverse }))
  end
end 
