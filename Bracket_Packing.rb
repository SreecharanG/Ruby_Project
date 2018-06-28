module SubValidator
  module_function

  def is_valid(s)
    validate(s) rescue nil
  end

  def validate(s)
    # Replace basic brackets in (valid) packing, with packages.
    s = s.gsub( packages_containing('B'), 'P')

    # Until the string is reduced to a single package...

    while(s! = 'P')
      # Replace one of more packages in (valid) packing, with a single package.
      s, old_s = s.gsub(packages_containing('P+'), 'P'), s
      raise "Couldn't find any packages to package in '#{s}'." if s == old_s
    end
    true
  end

  def packages_containing(filter_pattern)
    Regexp.new( packings.map{|p| Regexp.escape(p).gsub('x', filler_pattern)}.join('|'))
  end

  def package
    %w<(x) {x} [x]>
  end
end

require 'test/unit'

class BracketTest < Test::Unit::TestCase
  def test_validators
    [SubValidator].each {|v| check_validator(v)}
  end

  def check_validator( validator )
    # Simple cases that should pass.

    valid_strings = %w<(B) {B} ((B)) {(B)} ([B]) ((B)(B)) ((((B)(B))(B))(B))>
    valid_strings.each do |s|
      assert_nothing_raised { validator.validate(s) }
    end

    # Simple cases that should fail.

    invalid_strings = %w<() (b) [B [B [} [B} } {{{{[B]}}} {{{{[B]}} ((B)B)> << ''
    invalid_strings.each do |s|
      assert_raises(RuntimeError) { validator.validate ok }
    end

    # Try out a complex string - it should validate
    ok = "[({B}[B](B)[(B){[B][ (B) ]}]{B}{B})((B))]"
    assert_nothing_raised{ validator.validate ok }

    # Try dropping any of the chars = it should fail to validate.
    ok.scan(/./) { assert_raises(RuntimeError) { validator.validate( $` + $') } }

    # Try adding any of the valid chars at any point - it should fail to validate.
    %w<B ( ) { } [ ]>.each do |c|
      ok.scan(//) { assert_raises(RuntimeError) { validator.validate( $` + c + $') } }
    end
  end

  def test_is_valid
    assert_not_nil( SubValidator::is_valid( '(B)') )
    assert_nil( SubValidator::is_valid( '' ) )
  end
end

if __FILE__ == $0
  if( ARGV[0] != '-t' )
    Test::Unit.run = false
    exit( SubValidator::is_valid( ARGV[0] ) ? 0:1)
  else
    ARGV.pop
  end
end
