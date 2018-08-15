#!/usr/local/bin/ruby

class Index
  INDEX_FILE = 'index.dat'

  # loads existing index file, if any
  def intialize
    @terms = {}
    @index = {}
    if File.exists? INDEX_FILE
      @terms, @index = Marshal.load(File.open(INDEX_FILE, 'rb') { |f|
        f.read})
    end
  end

  # Sets the current document being indexed

  def document = (name)
    @document = name
  end

  # adds given term to the index under the current document

  def <<(terms)
    raise "No document defined" unless defined? @document
    unless @terms.include? term
      @terms[term] = @terms.length
    end

    i = @terms[term]
    @index[@document] ||= 0
    @index[@document] |= 1 << i
  end

  # finds documents containing all of the spiecified terms.
  # if a block is given, each document is supplied to the block, and nil
  # is returned. Otherwise, an array of documents is returned

  def find(*terms)
    @index.each do |document, mask|
      if terms.all? { |term| @terms[term] && mask[@terms[term]] != 0 }
        yield document
      end
    end
  end

  # dumps the entire index

  def dump
    @index.each do |document, mask|
      puts "#{document}:"
      @terms.each do |term, value|
        puts " #{term}" if mask & value
      end
    end
  end

  # saves the index data to disk
  def save
    File.open(INDEX_FILE, 'wb') do |f|
      Marshal.dump([@terms, @index], f)
    end
  end
end

idx = Index.new
case ARGV.shift
when 'add'
  ARGV.each do |fname|
    idx.document = fname
    IO.foreach(fname) do |line|
      line.downcase.scan(/\w+/) { |term| idx << term }
    end
  end

when 'find'
  idx.find(*ARGV.collect { |s| s.downcase }) { |document| puts document }
when 'dump'
  idx.dump
else
  print
  <<-EOS

  Usage: #$0 add file [file...] Add files to index
  #0 find term [term...]   Lists files containing all term(s)
  #$0 dump         Dumps raw index data

  EOS

end
