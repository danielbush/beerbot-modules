require 'date'
require 'beerbot'

module BeerBot;  module Modules; end; end

module BeerBot::Modules::Beer

  require 'beerbot'
  require_relative '../utils/datafile'
  require_relative '../utils/param_expand'
  require_relative '../utils/sentence_expand'

  Job       = BeerBot::Scheduler::CronR::CronJob

  def self.init config
    @config = config
    @filepath = File.join(@config.module_data('Beer'), 'data.json')
    begin
      @@datafile = BeerBot::Modules::Utils::JsonDataFile.new(@filepath)
    rescue => e
      puts "Can't load or parse json file: #{@filepath}"
      puts "Error: #{e}"
      exit 1
    end

    # Set up some scheduling...
    @scheduler = BeerBot::Scheduler.instance

    @scheduler.suspend {|arr|
      w = [45,14,true,true,5]
      a = [0,16,true,true,5]
      d = [true,true,true,true,true] # every minute

      arr << Job.new('timesheet', *w) {
        [to:'#sydney', msg:"*** It's approaching timesheet o'clock"]
      }

      arr << Job.new('beer-warn', *w) {
        warn = @@datafile.data['beerclock']['reminder']['warning'].sample
        chans = @@datafile.data['beerclock']['channels']
        chans.inject([]){|arr, chan| arr << {msg:warn, to:chan}}
      }

      arr << Job.new('beer-announce', *a) {
        announce = @@datafile.data['beerclock']['reminder']['announce'].sample
        chans = @@datafile.data['beerclock']['channels']
        chans.inject([]){|arr, chan| arr << {msg:announce, to:chan}}
      }

    }
  end

  def self.help arr=[]
    ['beerclock', 'beer [<nick>]']
  end

  def self.cmd msg, from:nil, to:nil, me:false, config:nil

    to = (me ? from : to)

    case msg

    when /^beerclock|^beeroclock/i

      data = @@datafile.data["beerclock"]
      nick = from
      now = DateTime.now
      diff = self.beerdate_diff(now)
      if not diff
        msg,err = BeerBot::Modules::Utils::ParamExpand.expand(data['now'].sample, nick:nick)
        return [ msg:msg, to:to ]
      end
      if rand(10) < 3 then
        arr = data['other']
      else
        arr = data['main']
      end
      a = arr.sample
      a, err = BeerBot::Modules::Utils::ParamExpand.expand(a, nick:nick)
      a, err = BeerBot::Modules::Utils::ParamExpand.expand(a, diff)
      a = [msg:a, to:to]

      b, err = BeerBot::Modules::Utils::ParamExpand.expand(
        data['supplementary'].sample,
        {nick:nick}
      )
      b = {msg:b, to:to}
      b = BeerBot::BotMsg.actionify(b)
      
      case rand(10)
      when 0,9
        if b[:action] then
          return a+[b]
        else
          c = [action:self.send_beer(nick), to:to]
          return a+[b]+c
        end
      else
        return a
      end

    when /^beer(\s+.*)?$/

      nick = $1
      if nick then
        nick.strip!
        # Recognise ourselves :)
        if config && config['nick'] then
          if config['nick'] == nick then
            nick = "himself"
          end
        end
      else
        nick = from
      end
      return [action:self.send_beer(nick),to:to]

    else
      return nil

    end
  end

  # Return string representing /me-style beer-sending action.

  def self.send_beer nick
    action = ":actions ::nick a :states :receptacles of :beers"
    msg = BeerBot::Modules::Utils::SentenceExpand.expand(action,@@datafile.data['beer'])
    msg,err = BeerBot::Modules::Utils::ParamExpand.expand(msg, nick:nick )
    msg
  end

  # Get the next beer o'clock datetime from 'now'.

  def self.beerdate now # todo: wday / time
    wday = now.wday # 0 = sunday, 5 = friday
    daystofri = 6-(wday+1).modulo(7) # 0 = saturday, 6 = friday
    d = DateTime.new(now.year,now.month,now.day,16,0,0,now.offset)
    beerdate = d+daystofri
  end

  # Return nil if we've hit beer o'clock (friday evening).
  # Otherwise return hash with component parts.

  def self.beerdate_diff now
    beerdate = self.beerdate(now)
    days = beerdate - now

    get_fraction = lambda {|r|
      _,frac = r.numerator.divmod(r.denominator)
      Rational(frac,r.denominator)
    }

    if days < 0 then
      if now.wday == 5 then
        # It's beer o'clock.
        return nil
      end
    end

    hours = get_fraction.call(days)*24
    minutes = get_fraction.call(hours)*60 
    seconds = get_fraction.call(minutes)*60 
    totaldays = days
    totalhours = days*24
    totalminutes = totalhours*60
    totalsecs = totalminutes*60
    
    {
      totaldays:totaldays.to_f.round(2),
      totalhours:totalhours.to_f.round(2),
      totalminutes:totalminutes.to_f.round(1),
      totalsecs:totalsecs.to_f.round(0),
      days:days.to_f.truncate,
      hours:hours.to_f.truncate,
      minutes:minutes.to_f.truncate,
      seconds:seconds.to_f.truncate,
    }
  end

end

