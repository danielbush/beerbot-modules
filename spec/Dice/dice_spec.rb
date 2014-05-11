
require_relative '../../Dice/dice.rb'
require 'pp'
Dice = BeerBot::Modules::Dice


describe "Dice module" do

  describe "dice-regex" do
    it "should match dice patterns" do
      Dice.detect('2d6').should == [2,6]
    end
  end
  describe "cmd" do
    it "should respond appropriately" do
      m = Dice.cmd("d6",from:'from1',to:'to1',me:false)
      m.size.should == 1
      m[0][:action].should match(/rolls the/)
      m = Dice.cmd("2d6",from:'from1',to:'to1',me:false)
      m.size.should == 1
      m[0][:action].should match(/rolls the/)
    end
    it "should handle 0 num / 0 die" do
      m = Dice.cmd("0d0",from:'from1',to:'to1',me:false)
      m.size.should == 1
      m = Dice.cmd("0d6",from:'from1',to:'to1',me:false)
      m.size.should == 1
      m = Dice.cmd("6d0",from:'from1',to:'to1',me:false)
      m.size.should == 1
    end
  end
end
