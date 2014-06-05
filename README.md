# BeerBot modules.

Greetings friend.  You have found your way to the beerbot botmodule project.

BeerBot can be found at: https://github.com/danielbush/BeerBot .
You'll need that if you want to go too much further into all matters beerbot.

BeerBot can also be installed as a gem ```gem install beerbot```.
Which might be a whole lot easier come to think of it.

Once you've got beerbot, you'll be wanting to do something with him.

That's where we come in...

## Version stuff...

Before we get there, this is a note to say that the current version of beerbot
these modules works with is 0.2.x .
Specifically at the time I'm committing this sentence to git, it is 0.2.0.pre.1.
So don't try using this particular version with 0.1.

## Setting up BeerBot modules on a new BeerBot installation

* set up BeerBot as per the README on https://github.com/danielbush/BeerBot
* configure beerbot's ```moduledir``` to point to a clone of this project
* configure beerbot's ```modules``` array to pick which modules you want to use; names should be proper-case and match one or more of the directories in ```moduledir``` - the directories in this project.
* configure beerbot's ```datadir``` to point to an empty directory somewhere
  * and make sure the beerbot config is configured for this also
  * modules will store their data here ordinarily
* run ```bundle install```
  * this should install the gems your bot modules will need
  * it'll probably install beerbot as well at a specific version (see testing below); you can try to run this or run a version cloned from git
* Check that your modules work against the version of beerbot you're using; beware, this is a fine art at the moment, as a lot has happened in beerbot land in recent times
  * see Testing below

Some further thoughts about organising your particular flavour of BeerBot...
* the ```master-0.x``` branch points to the default installation that will most likely work with beerbot 0.x.y .  No guarantees... at the moment.
* you can maybe branch off these and use a similar numbering scheme

## Creating a botmodule

Well, checkout the existing ones :D

We even included the Hodor module, which you should NOT use out there
in the wild. See the TUTORIAL.

## About some of the bot modules...

So there will be at leat 2 modules in here.
```Facts``` module and the other is the ```Oracle``` module.

In your conf, you're gonna want something like this:
- ```moduledir: 'path/to/beerbot/modules'```
- ```modules: ['Oracle','Facts']```


The ```Facts``` module is by far the more complicated of the two and
provides a way for people to add one or more facts for a given term or
keyword. At this point, maybe just look at the specs or use beerbot's
```,help``` command to check this out.

The ```Oracle``` module shows you how to use the ```JsonDataFile```.
This nifty piece of kit should automatically reload itself everytime
you update the json file, allowing you to keep beerbot hip and current
without even missing a beat.

Incidentally, you will see how ```datadir``` is accessed in the
```Oracle``` module.  It uses ```BeerBot::Config#module_data```.

There's also a ```Beer``` module that I haven't included here. In fact
both the ```Facts``` module and the ```Beer``` module were somewhat
inspired by functionality resident in #emac's fsbot on freenode.

## Quick reference...

So, your bot module is an object of some sort that should respond to
any or all of the following methods:

```
  #cmd msg,from:f,to:t,me:false,config:c,
```
* commands issued to the bot
* these are messages that the bot assumes are being
  directed at it in particular

```
  #hear msg,from:f,to:t,config:c,me:false
```
* messages that the bot hears
* the distinction with #cmd is determined by the dispatcher in the
  beerbot code; the default dispatcher looks for a command prefix
  at the beginning of a message eg ",do something!", to determine
  whether #cmd or #hear is used.

```
  #event type,from:f,to:t,config:c,me:false
```
* type is a symbol representing a generic event type
* eg :join => somebody joining a channel the bot is on

```
  #help arr
```
* where: topic,*subtopics = arr
* see Facts module for an example

```
  #init config
```
* only called once, at startup
* config is instance of BeerBot::Config

```
  #config config
```
* called at startup and possibly whenever
  config is updated on the fly, not that we're
  doing that atm...

### Return value

Beerbot stores bot modules it uses in an array and tries each one
in turn.

If your module returns ```nil``` or ```false```, beerbot will move on
to the next module. If you return a botmsg, this will be used to
return a response.

So, if you are processing ```#event```, be sure to return nil to
allow other modules to likewise process ```#event``` (unless
you don't want them to).

If you returned true or something that isn't a botmsg but truthy, the
bot won't say anything, but will stop processing any more modules.

#### Array format responses

You have another option.

Return:
```ruby
  [true,thing]
  # or
  [false,thing]
```
where ```thing``` should be a botmsg.

If ```true```, you suppress subsequent modules from being allowed to respond.
If ```false```, your response in ```thing``` will be processed and beerbot
will continue on to the next module.

## Testing

Your botmodules should probably use rspec.

BeerBot modules may call:

```ruby
  require 'beerbot'
```

If the version of beerbot in the gemfile is ok, then hopefully you can do:
```
  rspec Facts/spec
```
... replace Facts with whichever module you're testing.

If the version of beerbot in the gem is no longer cutting it then
you'll need to use version checked out from github.

In that case...
```
  rspec -Ipath/to/beerbot/lib Facts/spec
```

## Recommendations

* Write your code without any reference to beerbot (if it's complicated).
* Then hook it in using the event handlers in your beerbot module.
* Inject stuff.  Most things in beerbot are injectable including
  beerbot's configuration.  Your test-writing, rspec-loving alter-ego
  will love you.

