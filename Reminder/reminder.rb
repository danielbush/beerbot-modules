# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'beerbot'
require_relative '../utils/more'
require 'json'


module BeerBot; module Modules; end; end

module BeerBot::Modules::Reminder

  CUtils    = BeerBot::Scheduler::CronR::Utils
  Job       = BeerBot::Scheduler::CronR::CronJob
  Utils     = ::BeerBot::Modules::Utils
  More      = Utils::More      

  def self.scheduler
    @scheduler
  end

  def self.help arr=[]
    [
      "Do: ,at minute hour dom month dow <message>",
      "    one-off reminder",
      "Do: ,cron minute hour dom month dow <message>",
      "    repeating reminder",
      "If you run this in a channel, the channel will own and get the reminder",
      "If you message the bot directly, you will own and get the reminder",
      ",atrm <id>  =  deletes a job",
      ",atls       =  lists jobs",
    ]
  end

  def self.init config
    @scheduler = BeerBot::Scheduler.instance
    @config = config
    @more = More.new(5)
    # Load what we saved last time:
    self.load
  end

  def self.cmd msg, from:nil, to:nil, me:false, config:nil
    replyto = me ? from : to
    parsed = self.parse_args(msg)
    unless parsed then
      return nil
    end
    cmd, *params = parsed

    case cmd

    when 'atmore', 'cronmore'
      if @more.more?(replyto) then
        @more.more(replyto)
      else
        nil
      end

    when 'atls', 'cronls'
      jobs = @scheduler.select {|job|
        job[:reminder] &&
        job[:owner] == replyto
      }.map {|job|
        {to: replyto, msg: "#{job[:id]} (#{job[:owner]}) #{job[:msg]}"}
      }
      @more[replyto] = jobs
      @more.more(replyto)

    when 'at', 'cron'
      msg, cronr_params = params
      msg = [to: replyto, msg: msg]
      job = Job.new(self.new_id, *cronr_params) {
        msg
      }
      # Set ownership, which will determine who can delete.
      # If !me, then 'to' is a channel, and anyone on channel can delete
      job[:owner] = replyto
      job[:once] = true if cmd == 'at'
      job[:msg] = msg  # so we can persist
      job[:reminder] = true
      @scheduler.push(job)
      self.save
      [to: replyto, msg: "Created job #{job[:id]}, #{from}"]

    when 'atrm', 'cronrm'
      id,_ = params
      job = @scheduler.find{|job| job[:id] == id }
      if job then
        # Check ownership
        if job.has_key?(:owner) && (job[:owner] != replyto) then
          [to: replyto, msg: "I'm afraid you don't have permission, #{from}"]
        else
          @scheduler.reject!{|job| job[:id] == id }
          [to: replyto, msg: "Deleted job #{id}, #{from}"]
        end
      else
        [to: replyto, msg: "Can't find job #{id}, #{from}"]
      end

    end

  #rescue => e
    #[to: replyto, msg: e.message]

  end

  def self.hear msg, config:nil, from:nil, to:nil, me:false
  end

  def self.action action, config:nil, from:nil, to:nil, me:false
  end

  def self.savepath
    File.join(@config.module_data('Reminder'), 'savefile.json')
  end

  # Persist to a file store.
  def self.save
    File.write(self.savepath, @scheduler.to_json)
  end

  # Load from file store.

  def self.load
    jobs = JSON.load(File.read(self.savepath))
    puts "Loading reminders from #{self.savepath}, #{jobs.size} reminders found"
    @scheduler.reject!{true}
    jobs.each {|j|
      # Eek... convert keys to syms again
      msg = j['msg'].map {|h| {to: h['to'], msg: h['msg']}}
      job = Job.new(j['id'], j['minute'], j['hour'], j['day'], j['month'], j['dow']) {
        msg
      }
      job[:reminder] = true
      job[:owner] = j['owner']
      job[:once] = j['once']
      job[:msg] = msg
      @scheduler.push(job)
    }
    jobs
  rescue => e
    nil
  end

  # Generate a new unique id.

  def self.new_id
    max = @scheduler
      .select {|job| job[:reminder] }
      .map {|job| job[:id] }
      .max
    (max ? max : 0) + 1
  end

  # Parse the bit after the "," (command prefix).
  #
  # @return Array ["at"|"cron", msg, [CronR parameters]]
  #
  # Raises exception!
  # If 'str' doesn't start with 'at' or 'cmd', then return nil
  # (ignore).
  #
  # We want to use CronR.
  # CronR uses just booleans, Fixnums or arrays of Fixnums.
  # true  => cron: *
  # i     => cron: a
  # [...] => cron: a,b,c OR a-b,c-d or */a or a-b/k 
  # 

  def self.parse_args str
    cmd, *args = str.split(/\s+/, 7)
    case cmd
    when "atls", "cronls", "atmore", "cronmore"
      [cmd]

    when "atrm", "cronrm"
      id,_ = args
      id = id.to_i
      [cmd, id]

    when "at", "cron"
      min, hour, dom, month, dow, msg = args
      # This guarantees we got 5 cron params + message:
      if msg.nil? then
        raise "Couldn't detect a message"
      end
      # Parse remainder as cron parameters for use with CronR:
      # This could throw an error.
      params = [min, hour, dom, month, dow].map {|m|
        CUtils.parse_param(m)
      }
      [cmd, msg, params]

    end
  end


end
