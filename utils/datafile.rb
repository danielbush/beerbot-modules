# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the GNU
# General Public License.  A copy of the license should be
# enclosed with this project in the file LICENSE.  If not
# see <http://www.gnu.org/licenses/>.

require 'json'

module BeerBot

  module Modules

    module Utils

      # A class that loads data from a file and allows you to access it
      # using the #data method.
      #
      # If the file is updated (after >=1 sec), #data will reload.

      class DataFile

        attr_reader :reloaded  # true if last call to #data reloaded file

        def self.create! filepath
          File.open(filepath,'w'){}
          self.new(filepath)
        end

        def initialize filepath
          @filepath = filepath
          @data = File.read(filepath)
          @mtime = File.stat(filepath).mtime
          @reloaded = false
        end

        # Load data from file.

        def data
          @reloaded = false
          return @data unless File.exists?(@filepath)
          mtime = File.stat(@filepath).mtime
          return @data if mtime == @mtime
          puts "Reloading data file #{@filepath}"
          @mtime = mtime
          @data = File.read(@filepath)
          @reloaded = true
          @data
        end

        def save thing
          File.open(@filepath,'w') {|f|
            f.write(thing)
          }
        end

      end

      # Specialised DataFile that parses json.

      class JsonDataFile < DataFile

        attr_reader :json

        def self.create! filepath,data={}
          File.open(filepath,'w') {|f| f.puts(data.to_json)}
          self.new(filepath)
        end

        def initialize filepath
          super
          @json = JSON.parse(@data)
        end

        # Load data from file and parse as json data.

        def data
          super
          begin
            if @reloaded then
              json = JSON.parse(@data)
              @json = json
            end
          rescue => e
            return @json
          end
          @json
        end

        # Save thing back to file.
        #
        # Thing is assumed to be a hash or array that we call to_json on.

        def save thing=nil
          if thing.nil? then
            thing = @json  # the thing self.data returns
          end
          super(thing.to_json)
        end

      end

    end

  end

end
