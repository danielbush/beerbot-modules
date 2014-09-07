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

  def self.hear msg, config:nil, from:nil, to:nil, me:false

    replyto = me ? from : to
    replies = []

    m = Sed.sed_regex.match(msg)
    ignore = false

    if !m then
      ignore = true
    elsif m[:before] && m[:before] =~ /\S/ then
      # Ignore unless sed command is at the beginning of the line.
      ignore = true
    end

    # Everything else is something we overhear and record...

    if ignore then
      arr = self.data[from][replyto]
      arr.push([:msg, msg])
      if arr.size > self.size then
        arr.shift(arr.size - self.size)
      end
      return nil
    end

    # Now let's try to sub...

    who = from
    flags = m[:flags]

    # Check if 'from' is subbing someone else:

    case m[:after]
    when /^\s*(\S+)\s*$/
      who = $1
    end

    # Get history...

    arr = self.data[who][replyto]
    if arr.size == 0 then
      replies += [to: replyto, msg: [
                    "You srs?",
                    "I'm afraid I can't do that #{from}",
                  ].sample]
      return replies
    end
    type, last = arr.last

    # Is the regex sensible?

    begin
      rx = Regexp.new(m[:pattern])
    rescue => e
      return replies += [to: replyto, msg: [
                         "Go back to regex school n00b -- #{e}",
                         "No-can-do: #{e}",
                         "No you don't: #{e}",
                         "Fail. #{e}",
                         "Your pattern matching skills have a lot to be desired #{from} -- #{e}",
                       ].sample]
    end

    # Perform the substitution:

    if flags && flags=~/g/ then
      msg = last.gsub(rx, m[:replacement])
    else
      msg = last.sub(rx, m[:replacement])
    end

    if msg == last then
      replies += [to: replyto, msg: [
                    "Your pattern matching skills have a lot to be desired #{from}",
                    "Seriously, what was the point of that, nothing changed.",
                    "Seriously, what was the point of that.",
                    "Why bother.",
                  ].sample]
    else
      if who != from then
        replies += [
          to: replyto,
          msg: case type
               when :action
                 "What #{from} thinks #{who} was implying was that #{who} #{msg}"
               else
                 "What #{from} thinks #{who} meant to say was: #{msg}"
               end
        ]
      else
        replies += [
          to: replyto,
          msg: case type
               when :action
                 "What #{who} meant to do was: #{msg}"
               else
                 "What #{who} meant to say was: #{msg}"
               end
        ]
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
