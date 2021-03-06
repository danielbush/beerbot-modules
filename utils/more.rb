# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Modules

    module Utils

      # Split array in
      def self.splitArray arr,n=1
        [
          arr[0..(n-1)] || [],
          arr[n..-1] || []
        ]
      end

      # A hash of arrays.
      #
      # IMPORTANT: ensure when you use this that it takes an array.
      #
      # h = More.new(2)
      # h[:key] = [1,2,3,4,5]
      # h.more(:key) => [1,2]
      # h.more?(:key) => true
      # h[:key] => [3,4,5]
      #
      # MOTIVATION
      # More-filter botmsg's using :to as the key.

      class More < Hash
        def initialize size=4
          super() {|h,k| h[k] = []}
          @moresize = size
        end
        def size
          @moresize
        end
        def size= n
          @moresize = n
        end

        # This should hopefully prevent most attempts at setting a
        # non-array.

        def []= k,v
          unless v.kind_of?(Array) then
            raise "More: Value not an array."
          end
          super
        end

        def more? key
          self[key].any?
        end

        def more key
          return [] if self[key].empty?
          a,b = Utils.splitArray(self[key],@moresize)
          self[key] = b
          a
        end

      end
    end

  end
end
