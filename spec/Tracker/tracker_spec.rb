require_relative '../../Tracker/init.rb'

Tracker = BeerBot::Modules::Tracker
describe "Tracker module" do
  describe "the data structure" do
    it "should add new nicks" do
      Tracker.data['user1'].class.should == Hash
      Tracker.data['user1'].has_key?(:channels).should == true
    end
  end
end
