require 'beerbot'

module BeerBot; module Modules; end; end

module BeerBot::Modules::Hodor
    # This is called when the bot is addressed directly...
    def self.cmd msg,**kargs
      replyto = kargs[:me] ? kargs[:from] : kargs[:to]
      [to:replyto,msg:"Hodor!"]
    end

    # This is called when the bot isn't addressed directly...
    def self.hear msg,**kargs
      replyto = kargs[:me] ? kargs[:from] : kargs[:to]
      [to:replyto,msg:"Hodor?"]
    end

    # Only need to return an array of msgs (no to's/from's):

    def self.help arr=[]
      topic,*subtopics = arr
      ['HODOR!']
    end

    def self.event event,**kargs
      case event
      when :join
        unless kargs[:me] then
          [to:kargs[:channel],msg:"Hodor #{kargs[:nick]}!"]
        end
      end
    end
end
