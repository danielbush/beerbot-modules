# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'beerbot'

module BeerBot; module Modules; end; end

module BeerBot::Modules::Tracker

  def self.data
    @data ||= Hash.new{|h,nick|
      h[nick] = {
        :quit => nil,
        :channels => Hash.new{|h,chan|
          h[chan] = {
            :lines => [],
            :last_line_data => nil,
            :part => nil,
            :join => nil,
          }
        }
      }
    }
  end

  # Pretty much reset everything when user is joining...

  def self.join nick,chan,join_time
    self.data[nick][:channels][chan][:join] = join_time
    self.data[nick][:channels][chan][:part] = nil
    self.data[nick][:channels][chan][:lines] = []
    self.data[nick][:channels][chan][:last_line_date] = nil
    self.data[nick][:quit] = nil
  end

  # Process irc/chat events related to users joining, parting or quitting.
  #
  # TODO: this is passive; actively asking the server is more complicated
  # because we're agnostic to protocol eg irc and we need to "know" about
  # something that can ask for us.

  def self.event type,**kargs
    case type
    when :chanlist
      chan = kargs[:channel]
      nicks = kargs[:users]
      t = Time.now
      nicks.each{|nick|
        self.join(nick,chan,t)
      }
    when :join
      nick = kargs[:nick]
      chan = kargs[:channel]
      self.join(nick,chan,Time.now)
    when :part
      nick = kargs[:nick]
      chan = kargs[:channel]
      self.data[nick][:channels][chan][:part] = Time.now
      self.data[nick][:quit] = nil
    when :quit
      nick = kargs[:nick]
      msg = kargs[:msg]
      self.data[nick][:quit] = Time.now
    when :nick
      old = kargs[:old]
      newnick = kargs[:nick]
      if self.data.has_key?(newnick) then
        # Possibly they're nick'ing back to old nick.
      else
        self.data[newnick][:alias] = self.data[old]
      end
    else
    end
    nil
  end

  def self.cmd msg,me:me,from:nil,to:nil,config:nil
    replyto = me ? from : to
    case msg
    when /^seen\s+(\S+)\s*$/
      nick = $1
      unless self.data.has_key?(nick) then
        [
          to:replyto,
          msg:"Don't know where #{nick} is #{from}."
        ]
      else
        if self.data[nick][:alias] then
          data = self.data[nick][:alias]
        else
          data = self.data[nick]
        end
        if data[:quit] then
          [
            to:replyto,
            msg:"#{nick} was last seen quitting at #{data[:quit]}."
          ]
        else
          if not me then
            chan = to
          else
            chan = data[:channels].first
          end
          if not chan then
            [
              to:replyto,
              msg:"well... I don't recall #{nick} leaving, but I'm not sure how to get him atm..."
            ]
          else
            case nick
            when from
              [
                to:replyto,
                msg:[
                  "It appears you are enquiring after yourself",
                  "Ask yourself",
                ].sample
              ]
            when config['nick']
              [
                to:replyto,
                msg:[
                  "Very funny.",
                  "hah hm.",
                ].sample
              ]
            else
              chandata = data[:channels][chan]
              if chandata[:part] then
                [
                  to:replyto,
                  msg:"#{nick} was last seen leaving at #{chandata[:part]}"
                ]
              else
                [
                  to:replyto,
                  msg:[
                    "I think #{nick} is around.",
                    "I think #{nick} is here.",
                    "#{nick}! #{from} is asking after you!",
                  ].sample
                ]
              end
            end
          end
        end
      end
    end
  end

end
