# WoW Addon: Classic Web of Trust
This is a WoW addon that helps you track scores and notes about other players you've met during your adventures in Azeroth.

Any players you've given a 4+ score will be considered part of your "Web of Trust" (WoT).  
All the scores you've given to players will be shared with everyone in your WoT, 
so that when they meet the same player they will see the scores given by people in their WoT 
and that can help them make a choice on how to deal with the player.

## Work In Progress
This is a work in progress, it's not usable yet and I'm also rewriting the git repo history whenever I feel like xD

## Dev Setup
```
# make sure you have `luarocks` and `busted` installed

make setup-dev
```

## Testing
```bash
# to run test suite and linter:
make lint tests

# if you have `reflex` installed (https://github.com/cespare/reflex) you can use this to retry tests on file change:
make reflex-tests

# you can specify a subset of the tests to run with TESTS var, like;
make reflex-tests TESTS=tests/util/util.lua
```

## Structure
We're trying to avoid using globals as much as possible, so all components are bound to our addon global `ClassicWoT`  
and we generally pass components to other components that depend on them at initialization.  
The only `ClassicWoT.` or `ClassicWoT:` access should be for `Config` and the `*Print` methods.

For some decoupling we can use the `EventBus` to propagate events as well...
 
## Libs Names
To be able to load the libs in the tests we need to `require` them, which doesn't work when there's a `.` in in the filenames,
so we had to rename all libs (both folder and files) from `-3.0` to `-3dot0` or omit the version all together.  
We do still use the `-3.0` suffix in the code to load them through `LibStub` so inside WoW everything still works the same.
 
## Honorable mention
I used https://github.com/DomenikIrrgang/ClassicLFG as boilerplate for the eventbus and network code <3.

## Release Process
Travis builds the releases and pushes to Curseforge and WoWInterface when `UPLOADRELEASE=y` is set in env vars 
(set through travis control panel).
