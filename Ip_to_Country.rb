require 'ipaddr'

class IPAddr

  def country_code()
    open('IpToCountry.csv'){|file| code(file, to_i, 0, file.stat.size)}
  end

  private

  def code(file, ip, min, max)
    median = (min + max) / 2
    file.seek(median - 512)
    ary = file.read(1024).scan(/^"(\d*)", "(\d*)", "(?:\w*)", "(?:\d*)", "(\w*)"/)
    return code(file, ip, median, max) if ary.empty? || ary.last[1].to_i < ip
    return code(file, ip, min, median) if ary.first[0].to_i > ip
    ary.find{|l| l[1].to_i >= ip}[2]
  end
end

ARGV.each{|arg| puts IPAddr.new(arg).country_code} if $0 == __FILE__
