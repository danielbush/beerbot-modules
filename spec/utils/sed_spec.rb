require 'pp'
require 'byebug'
require_relative "../../utils/sed.rb"

Sed = BeerBot::Modules::Utils::Sed

describe "sed regex", :utils => true do

  it "should do sed extraction", :sed => true do
    s = [
      "s/test/foo/",
      "s#test#foo#",
      "s/test/foo/g",
      "s/test/foo/abc",
      "s/test/foo/abc ",
      ",test 1 s/test/foo/g",
      ",test 1 s#test#foo#g"
    ]
    s.map{|ss| Sed.sed_regex.match(ss)[:sep]}.should ==
      ['/','#','/','/','/','/','#']
    s.map{|ss| Sed.sed_regex.match(ss)[:pattern]}.should ==
      7.times.inject([]){|s,v| s << 'test'}
    s.map{|ss| Sed.sed_regex.match(ss)[:replacement]}.should ==
      7.times.inject([]){|s,v| s << 'foo'}
  end

end

