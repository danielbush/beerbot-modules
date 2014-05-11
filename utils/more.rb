# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'beerbot'

module BeerBot

  module Modules

    module Utils

      # A hash that buffers things by some key.
      #
      # If 'things' exceeds a set number, then these are stored in an
      # array against the key.
      #
      # For irc and other messaging the key should probably
      # be key :to of one or more botmsg's.
      # @see BotMsgMore

      class More < Hash

        attr_accessor :size

        def initialize
          super
          # Default value is empty array.
          self.default_proc = lambda {|h,k|
            h[k] = []
          }
        end

        def size
          @size ||= 5  # lines
        end

        # Fetch array of items from buffer for key 'key'.
        #
        # 'key' should probably be a person or channel you are messaging.
        #
        # Should return an array of items (eg of botmsg hashes).

        def more key
          arr = self[key]
          self[key] = arr.slice(self.size,arr.size) || []
          return arr.slice(0,self.size-1)
        end

        # Filter an array of items allowing only
        # the first 'n' of these.
        #
        # The remainder are stored in this hash and can
        # be accessed via 'key' using 'self.more'.

        def filter arr,key
          if arr.size <= self.size then
            self[key] = [] # reset buffer
            return arr
          end
          self[key] = arr.slice(self.size,size)
          return arr.slice(0,self.size)
        end

      end

    end

    # More-based filter that can be applied to botmsg's.
    #
    # #filter expects a botmsg and returns an array, either of botmsg's
    # or emtpy.

    class BotMsgMore < ::BeerBot::Modules::Utils::More
      def filter botmsg
        arr = BeerBot::BotMsg.to_a(botmsg)
        # At this point if arr isn't a valid bot msg we'll get [].
        replies = []
        by_to = Hash.new{|h,k| h[k]=[]}

        arr.inject(by_to){|h,v| h[v[:to]].push(v); h}
        by_to.each_pair{|to,a|
          replies += super(a,to)
          if replies.size < a.size then
            replies += [msg:"Type: more",to:to]
          end
        }
        return replies
      end
    end

  end

end
