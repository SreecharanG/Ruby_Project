
require 'yaml'
require 'ostruct'

class YAML2OS
  attr_reader :os

  def initialize( file = nil )
    convert(file) if file
  end

  def convert( file )
    yaml = YAML.load(File.open(file))
    @os = hash2os(yaml)
  end

  private

  # Check for hashes and arrays inside 'hash'. COnvery any hashes

  def hash2os( hash )
    hash.each_key do |key|
      hash[key] = hash2os(hash[key]) if hash[key].is_a?(Hash)
      chk_array(hash[key]) if hash[key].is_a?(Array)
    end
    hash = OpenStruct.new(hash)
  end

  # Check for hashes and arrays inside 'array'. Convert any hashes

  def chk_array( array )
    array.each_index do |i|
      array[i] = hash2os(array[i]) if array[i].is_a?(Hash)
      chk_array(array[i]) if array[i].is_a?(Array)
    end
  end

end
