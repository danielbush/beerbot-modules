# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.


module BeerBot

  module Modules

    module Utils

      module Sed

        # Regex that looks for a sed command eg
        # "s/pattern/replacement/flags" in a string.
        #
        # This regex doesn't handle backslash escapes, so if pattern or
        # replacement contain '/' use another delimiter eg s#...#...# etc.
        # 
        # Non alphanumeric delimiters are allowed.
        #
        # Returns: nil or a MatchData instance with symbol keys:
        #  :sed (the whole sed command), :sep (the separator), :pattern,
        #  :replacement, :flags
        #
        # If you want to combine this regex, call
        #   sed_regex.source => <string>

        def self.sed_regex
          %r{
        ^(?<before>.*)
        \b
        (?<sed>
          s
          (?<sep>[^A-z0-9\s])
          (?<pattern>(?!\g<sep>)*.*)
          \k<sep>
          (?<replacement>(?!\g<sep>)*.*)
          \k<sep>
          (?<flags>[A-z]*)
        )
        (?<after>.*)$
      }x
        end

      end

    end

  end

end
