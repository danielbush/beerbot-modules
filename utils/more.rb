

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
      # h.more(:key) => returns the next 'size' things
      # h[:key] => now has 'size'-less things in it
      # h.more?(:key) => true if not self[key].empty?

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
