
require 'pp'
require_relative '../../Sed/sed'

SedMod = BeerBot::Modules::Sed

describe "sed module" do
  describe "substituting last line" do
    it "should substitute someone's last line" do
      SedMod.hear "test test",from:'from1',to:'to1',me:false
      m = SedMod.hear("s/test/bar/",from:'from1',to:'to1',me:false)
      m[0].class.should == Hash
      m[0][:msg].should match(': bar test')
    end
    it "should handle flags" do
      SedMod.hear "test test",from:'from1',to:'to1',me:false
      m = SedMod.hear("s/test/bar/g",from:'from1',to:'to1',me:false)
      m[0].class.should == Hash
      m[0][:msg].should match(': bar bar')
    end
  end
end
