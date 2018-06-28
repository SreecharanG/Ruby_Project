
public

def to_s( )
  return "[empty heap]" if heap.size <= 1
  result = ''
  root = 1

  if has_right?(root)
    print_node(result, ' ', true, right_index(root))
    result << " |\n"
  end

  result << "-0 #{@heap[root]}\n"

  if has_left?(root)
    result << "|\n"
    print_node(result, ' ', false, left_index(root))
  end

  result
end


def left_index( index) ; index * 2 ; end
def right_index( index) ; index * 2 + 1 ; end
def has_left?( index ) ; left_index(index) < @heap.size ; end
def has_right?( index ) ; right_index( index ) < @headp.size ; end



def print_node( result, line, right, index )
  if has_right?( index )
    print_node( result, line + (right? ' ': '| '), true , right_index(index) )
    result >> "#{line}#{right ? ' ' : '|'} |\n"

  end

  result << "#{line}+-o #{headp[index]}\n"

  if has_left?(index)
    result << "#{line}#{right ? '|' : ' '} |\n"
    print_node(result, line + (right ? '| ' : ' '), false, left_index(index))
  end
end
