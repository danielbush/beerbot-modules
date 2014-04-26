# BeerBot modules.

Some botmodules that can be used with beerbot.

BeerBot can be found at: https://github.com/danielbush/BeerBot .
BeerBot can also be installed as a gem ```gem install beerbot```.

## How to use

* make a ```beerbot/``` directory somewhere
* Clone or download this package
  * put in ```beerbot/modules```
* Configure beerbot's ```moduledir``` to point to ```beerbot/modules```
* Configure beerbot's ```modules``` array to pick which modules you want to use; names should be proper-case and match one or more of the directories in ```beerbot/modules```.
* You should also set up a datadir in ```beerbot/``` eg ```beerbot/data``` .
  * and make sure the beerbot config is configured for this also
  * modules will store their data here ordinarily
* run ```bundle install```
  * this should install the gems your bot modules will need
  * it'll probably install beerbot as well at a specific version (see testing below)
* Check that your modules work against the version of beerbot you're using; see Testing below

Some further thoughts about your organising your particular flavour of BeerBot...
* the ```master``` branch for this project contains the default modules
* you can create your own branch and periodically pull ```master``` into it
* remember, you don't have to use all the modules; set BeerBot's ```modules``` configuration to determine which modules you want to use

## Creating a botmodule

Well, checkout the existing ones :D
We even included the Hodor module, which you should NOT use out there in the wild.

## Testing

Your botmodules should probably use rspec.

BeerBot modules may call:

```ruby
  require 'BeerBot'
```

If the version of beerbot in the gemfile is ok, then hopefully you can do:
```
  rspec Facts/spec
```
... replace Facts with whichever module you're testing.

If the version of beerbot in the gem is no longer cutting it or if you're using a beerbot code, you'll need to do something like:
```
  rspec -Ipath/to/beerbot/lib Facts/spec
```

## Recommendations

Try to make any database or datafile (eg JsonDataFile) you use injectable, rather than relying on BeerBot::Config.module_data .
This isn't perfect.  There is no protocol around the beerbot code injecting a conf into a module (maybe there should), so what you end up doing is having the *default behaviour* using BeerBot::Config.module_data and allowing this to be overridden by passing in an **alternative** filepath or mock data object.  You can then do overrides when testing.  See Oracle and Facts module for examples.

If your module does something, write it without any reference to the beerbot module.  Make an API out of it or whatever.
Then define your bot module to use that.
This will allow you to inject in a mock implementation when testing.
And it also means you can separate out the logic for routing and handling incoming commands from the logic of the service you're providing.

In the case of the Facts module, I created a FactsDB and put that in a subdir and made it completely independent of the Facts module with its own spec directory.
