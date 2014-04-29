# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'BeerBot'

module BeerBot; module Modules; end; end

# This module responds to messages that end with 2 or more question
# marks eg ??, ??? etc.
#
# If we're lucky, it may make the bot sound vaguely human :D

module BeerBot::Modules::Dice

  REGEX = /^\s*(?<num>\d+)?d(?<dice>\d+)\b/

  def self.detect str
    m = REGEX.match(str)
    if m then
      [ m[:num].nil? ? 1 : m[:num].to_i,m[:dice].to_i]
    end
  end

  # Route messages like "beerbot: why ... " etc
  #
  # Assumes: msg has "beerbot: " stripped out via the dispatcher.

  def self.cmd msg,from:nil,to:nil,me:false,world:nil
    replyto = me ? from : to
    m=self.detect(msg)
    return nil unless m
    num,dice = m

    if num == 0 then
      if dice == 0 then
        replies = [to:replyto,msg:[
            "the result is undefined #{from}",
          ].sample]
        return BeerBot::BotMsg.actionify(replies)
      else
        replies = [to:replyto,msg:[
            "* rolls zero dice...",
            "what is the sound of zero dice being rolled?",
          ].sample]
        return BeerBot::BotMsg.actionify(replies)
      end
    elsif num > 10 then
      replies = [to:replyto,msg:[
          "Too many dice!!!",
          "I can't dice-bomb the channel #{from}",
        ].sample]
      return BeerBot::BotMsg.actionify(replies)
    end
    if dice == 0 then
      replies = [to:replyto,msg:[
          "* ponders the notion of a zero-sided die...",
          "that is profound #{from}",
        ].sample]
      return BeerBot::BotMsg.actionify(replies)
    elsif dice > 10**10 && num > 1 then
      replies = [to:replyto,msg:[
          "Nope, not doing it",
        ].sample]
      return BeerBot::BotMsg.actionify(replies)
    end

    result = num.times.inject([]) {|s,_| s << Kernel.rand(dice)+1 }.join(' ')
    replies = [
      to:replyto,
      msg:"* rolls the #{num==0 ? 'die' : 'dice'} ... #{result}"
    ]
    BeerBot::BotMsg.actionify(replies)
  end

  def self.help arr=[]
    [
      ",2d6 = means roll 6 sided die twice etc",
    ]
  end

end
