# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot; module Modules; end; end

# Calendar module
#
# Store multiple cron-like events for a given person or channel.
# Load these into BeerBot::Scheduler.instance
#
# SYNOPSIS
#
# ,cal-list
# ,cal-ls
# ,cal-ls today
# ,cal-ls week
# ,cal-ls tomorrow
# ,cal-ls 2014
# => list calendar events for thing
# where thing is ::from if messaging bot directly, or the channel
# if command is issued over a channel
#
# You can add events to your calendar...
# ------------------------------------------------------------
# 
# ,cal-add y m d h m dow This is an event!
#
# ,cal-add 2014 1 2 15 0 *
# => add event for 2014-1-2 15:00
# ,cal-add * 1 2 15 0 *
# => add event for 2-Jan 15:00
# ,cal-add * * * 15 0 1
# => add event for every monday 15:00
#
# Note that if year!=*, the event cannot recur.
#
# ,cal-del <id>
#
# You can set reminders for events...
# ------------------------------------------------------------
#
# ,cal-reminder <id> <n> <units>
# ,cal-rem ibid
# eg
# ,cal-rem 342 1 week
# ,cal-rem 342 1 day
# ,cal-rem 342 5 minutes
#
# You can add reminders...
# ------------------------------------------------------------
# ,reminder y m d h m dow Get the milk this evening!
# ,rem ibid.

require 'BeerBot'
require 'CronR'

module BeerBot::Modules::Calendar

  JsonDataFile = ::BeerBot::Utils::JsonDataFile

  # Get the data file filepath or set it to 'filepath'.
  #
  # The default data filepath is set in BeerBot::Config module_data.

  def self.datafile filepath=nil
    if filepath then
      @filepath = filepath
      @file = nil
    else
      @filepath ||= File.join(BeerBot::Config.module_data('Calendar'),'data.json')
    end
  end

  def self.create_datafile! filepath,data=nil
    unless data then
      data = {}
    end
    JsonDataFile.create!(filepath,data)
  end

  # Access stored data.
  #
  # If 'data' is given, it can be used to set the data store and
  # override the default storage mechanism (the jsondatafile)

  def self.data data=nil

    if data then
      @filepath = '/dev/null'
      @data = data
      return @data
    end

    unless File.exists?(self.datafile) then
      self.create_datafile!(self.datafile)
    end
    @file ||= JsonDataFile.new(self.datafile)
    @file.data

  end

  def self.save
    @file.save
  end

  # TODO: load json file into scheduler....
  # TODO: how do we override this and mock it up?

  def self.init data=nil
  end

  def self.cmd msg,me:false,from:from,to:to,world:nil
    replyto = me ? from : to
    replies = []
    case msg
    # ,remind 2014 1 2 15 0 * This is a reminder!
    when /^(?:remind|rem)\s+((?:\S+\s+){6})(.*)$/
      args,msg = $1,$2
      msg = msg.strip
      args = args.strip.split(/\s+/)
      ok,calargs = self.expand_args(args)
      if ok then
        replies += [to:replyto,msg:"#{self.pretty(calargs)}"]
        replies += [to:replyto,msg:"Message is: #{msg}"]
        # Store in file
        self.data[replyto] ||= []
        self.data[replyto].push({
            msg:msg,
            author:from,
            to:replyto,
            args:calargs
          })
        id = self.data[replyto].size
        replies += [to:replyto,msg:"Your id: #{id}"]
        self.save()
        # TODO
        # Add to scheduler
      else
        replies += [
          to:replyto,
          msg:"Don't know how to handle '#{calargs}' ::from"
        ]
      end

    # ,delremind <id>
    when /^rem-del\s+(\d+)\s*$/
      id = $1.to_i
      # TODO fetch entry and remove, update file, update scheduler
    end

    return nil if replies.empty?
    unless me then
      replies = [
        to:replyto,
        msg:"Note: this reminder will be for #{replyto}, pm for personal reminders."
      ] + replies
    end

  end

  Types = [:year,:month,:day,:hour,:minute,:dow]

  # Make more human friendly output of calendar/cron args.
  #
  # Currently, we ignore args that are true, and only show ones that
  # have something interesting set.
  # 
  # 'args' should be an array of items.
  # 
  # An array of items where each item is either:
  #   integer,
  #   array of integers,
  #   range,
  #   true
  #
  # Intended to take the output from self.expand_args (the args parts
  # of the result).

  def self.pretty args
    args.zip(Types).select{|arg,type| arg!=true }.map{|arg,type|
      a = arg
      if arg == true then
        a = '*'
        ""
      else
        "#{type}=#{a}"
      end
    }.join(',')
  end

  def self.expand_args args
    if args.size != 6 then
      return [false,"Args #{args.inspect} != 6 items"]
    end
    result = args.zip(Types).inject([]){|arr,v|
      a = self.expand_arg(*v)
      return [false,v] if a.nil?
      arr << a
    }
    [true,result]
  end

  def self.expand_arg arg,type
    arg = arg.strip
    case arg
    when '*'
      true
    when /^\d+$/
      arg.to_i
    when /^(\d+,){1,}\d+$/
      arg.split(',').map{|a| a.to_i}
    when /^\*\/(\d+)$/
      s = $1.to_i
      case type
      when :minute
        (0..59).step(s).to_a
      when :hour
        (0..23).step(s).to_a
      when :month
        (1..12).step(s).to_a
      when :day
        (1..31).step(s).to_a
      when :dow
        (0..6).step(s).to_a
      else
        return nil
      end
    else
      return nil
    end
  end

  self.init

end
