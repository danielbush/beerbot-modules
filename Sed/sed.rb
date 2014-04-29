# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2013,2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'BeerBot'

module BeerBot; module Modules; end; end

module BeerBot::Modules::Sed
  Utils = ::BeerBot::Utils
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

  def self.hear msg,world:nil,from:nil,to:nil,me:false
    replyto = me ? from : to
    replies = []
    case
    when m=Utils.sed_regex.match(msg)
      who = from
      flags = m[:flags]
      case m[:after]
      when /^\s*(\S+)\s*$/
        who = $1
      end
      #replies += [to:replyto,msg:"#{m.inspect}"]
      arr = self.data[who][replyto]
      if arr.size > 0 then
        begin
          rx = Regexp.new(m[:pattern])
        rescue => e
          return replies+=[to:replyto,msg:[
              "Go back to regex school n00b -- #{e}"
            ].sample]
        end
        if flags && flags=~/g/ then
          msg = arr.last.gsub(rx,m[:replacement])
        else
          msg = arr.last.sub(rx,m[:replacement])
        end
        if msg == arr.last then
          if [true,false,false].sample then
            replies += [to:replyto,msg:[
                "Go back to regex school n00b",
                "Your pattern matching skills have a lot to be desired #{from}",
                "Seriously, what was the point of that, nothing changed."
              ].sample]
          end
        else
          if who!=from then
            replies += [
              to:replyto,
              msg:"What #{from} thinks #{who} meant to say was: #{msg}"
            ]
          else
            replies += [
              to:replyto,
              msg:"What #{who} meant to say was: #{msg}"
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
    else
      # Everything else is something we overhear and record...
      arr = self.data[from][replyto]
      arr.push(msg)
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
end
