require 'pp'
require_relative "../../utils/more"

More = ::BeerBot::Modules::Utils::More

describe "More buffering" do

  it "should buffer" do
    more = More.new(4)
    more.size.should == 4
    more.size = 2
    more.size.should == 2

    more[:mine] = [1,2,3,4,5,6]

    more.more(:mine) == [1,2]
    more.more(:mine).should == [3,4]
    more.more(:mine).should == [5,6]
    more.more(:mine).should == []
  end

  it "should buffer even if set_more not called" do
    more = More.new(2)
    a = more.more(:random)
    a.should == []
  end

end
