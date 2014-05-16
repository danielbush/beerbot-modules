# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'beerbot'
require_relative '../utils/sed'

module BeerBot; module Modules; end; end

module BeerBot::Modules::Sed

  Sed = ::BeerBot::Modules::Utils::Sed

  def self.size size=nil
    if size.nil? then
      @size ||= 1
    else
      @size = size
    end
  end

  def self.data
    @data ||= Hash.new{|h,from|
      h[from] = Hash.new{|h,to|
        h[to] = []
      }
    }
  end

  def self.help arr=[]
    [
      "Do: s/pattern/replacement/ => to edit your last line",
      "Do: s/pattern/replacement/ nick => to edit your nick's last line",
      "Use a different delimiter if you're using '/': s#pattern#...#",
      "Flags: i,g  eg s/.../.../ig",
    ]
  end

  def self.hear msg,config:nil,from:nil,to:nil,me:false
    replyto = me ? from : to
    replies = []
    case
    when m=Sed.sed_regex.match(msg)
      who = from
      flags = m[:flags]

      # Ignore sed unless it is at the beginning of the line.
      if m[:before] && m[:before] =~ /\S/ then
        return nil
      end

      case m[:after]
      when /^\s*(\S+)\s*$/
        who = $1
      end

      arr = self.data[who][replyto]
      if arr.size > 0 then
        begin
          rx = Regexp.new(m[:pattern])
        rescue => e
          return replies+=[to:replyto,msg:[
              "Go back to regex school n00b -- #{e}",
              "No-can-do: #{e}",
              "No you don't: #{e}",
              "Fail. #{e}",
              "Your pattern matching skills have a lot to be desired #{from} -- #{e}",
            ].sample]
        end

        type,last = arr.last

        if flags && flags=~/g/ then
          msg = last.gsub(rx,m[:replacement])
        else
          msg = last.sub(rx,m[:replacement])
        end
        if msg == last then
          if [true,false,false].sample then
            replies += [to:replyto,msg:[
                "Your pattern matching skills have a lot to be desired #{from}",
                "Seriously, what was the point of that, nothing changed.",
                "Seriously, what was the point of that.",
                "Why bother.",
              ].sample]
          end
        else
          if who!=from then
            replies += [
              to:replyto,
              msg: case type
                   when :action
                     "What #{from} thinks #{who} was implying was that who #{msg}"
                   else
                     "What #{from} thinks #{who} meant to say was: #{msg}"
                   end
            ]
          else
            replies += [
              to:replyto,
              msg: case type
                   when :action
                     "What #{who} meant to do was: #{msg}"
                   else
                     "What #{who} meant to say was: #{msg}"
                   end
            ]
          end
        end
      else
        replies += [to:replyto,msg:[
            # TODO: in the case some cheeky sod sets who=beerbot,
            # we need to catch that here...
            #"Not entirely sure #{who} said something #{from}",
            "You srs?",
            "I'm afraid I can't do that #{from}",
          ].sample]
      end

    # Everything else is something we overhear and record...

    else
      arr = self.data[from][replyto]
      arr.push([:msg,msg])
      if arr.size > self.size then
        arr.shift(arr.size-self.size)
      end
    end

    if replies.empty? then
      nil
    else
      replies
    end

  end

  def self.action action,config:nil,from:nil,to:nil,me:false
    replyto = me ? from : to
    arr = self.data[from][replyto]
    arr.push([:action,action])
    if arr.size > self.size then
      arr.shift(arr.size-self.size)
    end
  end

end
