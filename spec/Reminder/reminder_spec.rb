
require 'pp'
require_relative '../../Reminder/reminder'

Reminder = BeerBot::Modules::Reminder

describe "Reminder module", :reminder => true do

  describe "parsing inputs from users" do
    it "should parse cron args" do
      Reminder.parse_args('at 1-3 17 4-11/2 * * foo')
        .should == ['at', 'foo', [[1, 2, 3], [17], [4, 6, 8, 10], true, true], "1-3 17 4-11/2 * *"]
    end
  end

  describe "adding jobs" do

    before(:each) {
      config = BeerBot::Config.new(datadir: '/tmp', moduledir: '/tmp')
      Reminder.init(config)
      Reminder.scheduler.reject!{true}
    }

    it "should add at-commands" do
      r = Reminder.cmd("at * * * * * test message", from: 'from1', to: 'to1')
      r.first[:msg].should == 'Created job 1, from1'
      Reminder.scheduler.size.should == 1
      Reminder.scheduler.first[:id].should == 1
      Reminder.scheduler.first[:once].should == true
      Reminder.scheduler.first.run.should == [to: 'to1', msg: 'test message']
    end

    it "should add cron-commands" do
      r = Reminder.cmd("cron * * * * * test message", from: 'from1', to: 'to1')
      r.first[:msg].should == 'Created job 1, from1'
      Reminder.scheduler.size.should == 1
      Reminder.scheduler.first[:id].should == 1
      Reminder.scheduler.first[:once].should == nil
      Reminder.scheduler.first.run.should == [to: 'to1', msg: 'test message']
    end

    it "should set the owner property on the cronjob", :owner => true do
      r = Reminder.cmd("at * * * * * test message", from: 'from1', to: 'to1', me: false)
      Reminder.scheduler[0][:owner].should == 'to1' # to1 = channel
      r = Reminder.cmd("at * * * * * test message", from: 'from1', to: 'to1', me: true)
      Reminder.scheduler[1][:owner].should == 'from1' # personal cron job
    end

    it "should store the message (so we can persist it)" do
      r = Reminder.cmd("at * * * * * test message", from: 'from1', to: 'to1', me: false)
      Reminder.scheduler.first[:msg].should == [to: 'to1', msg: 'test message']
    end

  end

  describe "removing jobs" do

    before(:each) {
      Reminder.scheduler.reject!{true}
      Reminder.scheduler.push(Reminder::Job.new(1))
      Reminder.scheduler.push(Reminder::Job.new(2))
      # Create some jobs that have ownership set:
      j = Reminder::Job.new(3)
      j[:owner] = '#some-channel'
      Reminder.scheduler.push(j)
      j = Reminder::Job.new(4)
      j[:owner] = 'some-user'
      Reminder.scheduler.push(j)
    }

    it "should remove by id" do
      r = Reminder.cmd("atrm 1", from: 'from1', to: 'to1')
      Reminder.scheduler.map {|job| job[:id]}.sort.should == [2, 3, 4]
    end

    it "should respond to cronrm in the same way" do
      r = Reminder.cmd("cronrm 1", from: 'from1', to: 'to1')
      Reminder.scheduler.map {|job| job[:id]}.sort.should == [2, 3, 4]
    end

    it "should remove if ownership matches" do
      r = Reminder.cmd("atrm 3", from: 'from1', to: '#some-channel')
      Reminder.scheduler.map {|job| job[:id]}.sort.should == [1, 2, 4]
      expect(r.first[:msg]).to match(/Deleted job 3/)
    end

    it "should refuse to remove if ownership doesn't match" do
      r = Reminder.cmd("atrm 3", from: 'from1', to: '#not-some-channel')
      Reminder.scheduler.map {|job| job[:id]}.sort.should == [1, 2, 3, 4]
      expect(r.first[:msg]).to match(/I'm afraid you don't have permission/)
    end

  end

  describe "listing jobs" do

    # We should only list jobs on the channel
    # or for the user when pm'ing the bot.

    before(:each) {
      Reminder.scheduler.reject!{true}
      Reminder.scheduler.push(job=Reminder::Job.new(1,1,2,3,4,5){[to: '#some-channel', msg: 'msg1']})
      job[:msg] = [to: '#some-channel', msg: 'msg1']
      job[:owner] = '#some-channel'
      job[:reminder] = true
      Reminder.scheduler.push(job=Reminder::Job.new(1,1,2,3,4,5){[to: '#some-channel', msg: 'msg3']})
      job[:msg] = [to: '#some-channel', msg: 'msg3']
      job[:owner] = '#some-channel'
      job[:reminder] = true
      Reminder.scheduler.push(job=Reminder::Job.new(2,true,7,8,9,10){[to: 'someone', msg: 'msg2']})
      job[:msg] = [to: 'someone', msg: 'msg2']
      job[:owner] = 'someone'
      job[:reminder] = true
    }

    it "should list jobs matching :owner" do
      r = Reminder.cmd("atls", from: 'from1', to: '#some-channel')
      expect(r.size).to be(2)
      r = Reminder.cmd("atls", from: 'someone', to: 'beerbot', me: true)
      expect(r.size).to be(1)
    end

  end

  describe "persisting jobs" do

    before(:each) {
      config = BeerBot::Config.new(datadir: '/tmp', moduledir: '/tmp')
      Reminder.init(config)
      Reminder.scheduler.reject!{true}
      Reminder.scheduler.push(job=Reminder::Job.new(1,1,2,3,4,5){[to: 'to1', msg: 'msg1']})
      job[:msg] = [to: 'to1', msg: 'msg1']
      job[:reminder] = true
      Reminder.scheduler.push(job=Reminder::Job.new(2,true,7,8,9,10){[to: 'to2', msg: 'msg2']})
      job[:msg] = [to: 'to2', msg: 'msg2']
      job[:reminder] = true

      # A non-reminder job - shouldn't be saved...
      Reminder.scheduler.push(job=Reminder::Job.new(3,true,7,8,9,10){[to: 'to3', msg: 'msg3']})
      job[:msg] = [to: 'to3', msg: 'msg3']
    }

    it "can save the scheduler to a json file and reload it" do
      Reminder.save
      # Let's wipe the Scheduler...
      Reminder.scheduler.reject!{true}
      expect(Reminder.scheduler.empty?).to be(true)
      jobs = Reminder.load
      expect(Reminder.scheduler.size).to be(2)
      expect(Reminder.scheduler[0][:id]).to be(1)
      expect(Reminder.scheduler[0].run).to match_array([to: 'to1', msg: 'msg1'])
      expect(Reminder.scheduler[1][:id]).to be(2)
      expect(Reminder.scheduler[1].run).to match_array([to: 'to2', msg: 'msg2'])
    end

  end

  describe "running jobs" do
    it "should run and delete jobs flagged with :once"  # this is probably automatic
  end

end
