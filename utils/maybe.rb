# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

module BeerBot

  module Modules

    module Utils

      # 90% of the time you usually want to say the sort of bland
      # stuff that we all say.  Then there's that 10% where you say
      # something crazy...
      #
      # Note, you can nest maybe's.
      #
      # Nothing grates more than when the bot says the same
      # complicated thing repeatedly.
      # 
      # You'll also want to look at sentence_expand.
      #
      # [to:to,msg:maybe({90=>['yes','ok','fine'],10=>[...]})]

      def maybe thing
        case thing
        when Hash
          keys = thing.keys
          total = keys.reduce{|s,i|s+i}
          i = Kernel.rand(total)
          k = keys.reduce{|s,k|s+=k; if s>=i then break k; else s end}
          case thing[k]
          when Array
            thing[k].sample
          when String
            thing[k]
          when Hash
            maybe(thing[k])
          else
            nil
          end
        else
          nil
        end
      end

    end

  end

end
