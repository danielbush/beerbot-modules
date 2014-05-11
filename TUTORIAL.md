## Hodor!

Ok, enough of the dry stuff.  Let's make a bot module.

**Note:** You should know your ```moduledir```, ```datadir```
settings.

We'll just refer to these as "moduledir" and "datadir" etc.

```
  mkdir moduledir/Hodor
```

In ```moduledir/Hodor/init.rb``` put:

```ruby
  require_relative 'Hodor'
```

In ```moduledir/Hodor/Hodor.rb``` put:

```ruby
  require 'beerbot'
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
  end
```

So what does the above do?

If you say anything directly:

```
  <danb> ,hi
  <beerbot> Hodor!
  <danb> beerbot: hi
  <beerbot> Hodor!
```

If you say something on a channel not to the bot:

```
  <danb> hi
  <beerbot> Hodor?
  <danb> oh wow, that's annoying can we ban this plz??
```

Finally if you said: ```,help Hodor```, well, you can guess...

Ok, so some things to note.

```ruby
  [to:replyto,msg:"..."]
```

is sugar for:

```ruby
  [{to:replyto,msg:"..."}]
```

In fact: 

```ruby
   {to:replyto,msg:"..."}
```

will do just fine. Both forms are referred to as a ```botmsg```.
```#cmd``` and ```#hear``` can return either a single hash or an array
of such.

Now, if you were to return ```nil``` rather than a ```botmsg```, then
BeerBot will move on and look at the next bot module to see if it has
a response.

What constitutes "the next bot module" you ask?

Well, in the pry repl, look at ```@bot```.  It's an array (take a look at the source code for bot.rb in ```lib/*/```).  BeerBot will start with the first bot module in the array, and look for a response, and continue working through the array till it hits the first module to respond.

At the moment, the first module to respond with non-nil terminates
any further look ups.

### Scheduling

Now let's get really annoying. If saying "Hodor" all the time won't
get you and Beerbot banned from the channel, you can perhaps try going
the unsolicited route...

You can grab the ```CronR``` scheduler
If we define ```config``` method in our Hodor module, we'll get
the config when the bot starts up.

(We also get it passed to use on all events as karg = :config).

```ruby
  def self.config config
    @config
  end
```

Once we've got, the sky's the limit...

```ruby
  scheduler = @config.scheduler
  # Cron parameters: 5 = 'friday', 0,16 = 4pm 
  cronargs = [0,16,true,true,5]
  # Add a job...
  scheduler.suspend {|arr|
    arr << CronR::CronJob.new('timesheet',*cronargs) {
      [to:'#chan',msg:"OMG! it's like 4pm friday..."]
    }
  }
```

Note, ```@scheduler``` should be available to you in the pry repl.

### Events

We've covered messages the bot hears and messages that are interpreted
directly by the bot.  But what about other events like somebody joining
a channel or conference room?

Taking the Hodor module above we can add:

```ruby
    def self.event event,**kargs
      case event
      when :join
        unless kargs[:me] then
          [to:kargs[:channel],msg:"Hodor! #{kargs[:nick]}!"]
        end
      end
    end
```

That's not annoying!
