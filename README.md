##EventDispatcher

In Corona SDK, event listeners can only be added to the global Runtime object or to display objects. In order to broadcast messages to event listeners, the event dispatcher is limited to either one or the other. This limitation places messaging in the two scopes instead of between objects that are supposed to be talking to each other. I've seen many examples with display objects that are created solely for the purpose of dispatching events. This just doesn't feel right to me; so I'm releasing my EventDispatcher, perhaps other developers may find it useful too.

Those who came from the good old Flash 5 days may remember [FLEM](http://qwmobile.com/flash/) (FLash Event Model). It was the first listener event model for Flash and ActionScript, and was created by Branden Hall and further developed and maintained by me. I’ve adapted the basic event model mechanism found in ActionScript 2/3 to Lua. This EventDispatcher has a similar interface as the listener model in Corona SDK, with some extra features thrown in (such as optional extra parameters when dispatching events, and returning status).

EventDispatcher provides custom event broadcaster/listener mechanism to regular Lua objects, it works as regular Lua 5.1 / 5.2 code, in Corona SDK, and likely other Lua-based frameworks.

Basic usage:
```lua
local EvtD = require "EventDispatcher"

local listener = {
	eventName = function(event)
		print(event.name)
	end
}

local broadcaster = EvtD()

broadcaster:addEventListener( "eventName", listener ) -- or
broadcaster:on( "eventName", listener )

broadcaster:once( "eventName", listener )

broadcaster:hasEventListener( "eventName", listener )

broadcaster:dispatchEvent( { name="eventName" } ) -- or
broadcaster:emit( { name="eventName" } )

broadcaster:removeEventListener( "eventName", listener )

broadcaster:removeAllListeners( "eventName" ) -- or
broadcaster:removeAllListeners()

broadcaster:printListeners()
```

---
####Documentation ([read here](http://htmlpreview.github.com/?https://github.com/daveyang/EventDispatcher/blob/master/doc/index.html))
---

Sample code below demonstrates how it can be used:

```lua
-- main.lua for EventDispatcher demo

local EvtD = require "EventDispatcher"

---------------------------------------------------------------------------

-- shared function for cowboys; shows the use of event.target
local function cowboyDraw(event, ...)
	if event.subject then
		print(event.target.name .." is ".. event.name .."ing a gun and shooting a ".. event.subject)
	else
		print(event.target.name .." is ".. event.name .."ing a gun")
	end
end

---------------------------------------------------------------------------

-- table listeners

local cowboy1 = {
	name = "Cowboy1",
	draw = cowboyDraw
}

local cowboy2 = {
	name = "Cowboy2",
	draw = cowboyDraw
}

---------------------------------------------------------------------------

-- listener as table; shows the use of event.source
local iPad = {
	turnOn = function(event, ...)
		--print("iPad is turned on by ".. event.source.name .." (table)")
		print("iPad is turned on by ".. event.source.name .." (table)")
	end,

	turnOff = function(event, ...)
		print("iPad is turned off by ".. event.source.name .." (table)")
	end
}

-- listener as function
local function turnOniPad(event, ...)
	print("iPad is turned on by ".. event.source.name .." (function)")
end

---------------------------------------------------------------------------

-- basic artist draw function
local function artistDraw(event, ...)
	print(event.target.name .." is ".. event.name .."ing a picture")
end

---------------------------------------------------------------------------

-- artist1 is both a listener and a event dispatcher
local artist1 = EvtD{
	name = "Artist1",
	draw = artistDraw,

	-- responds to the 'rest' message, and sends a message to the iPad
	rest = function(event, ...)
		print(event.target.name .." is ".. event.name .."ing")

		-- event.target is artist1
		event.target:dispatchEvent({name="turnOff"})
	end
}

-- artist1 tells iPad to listen to the 'turnOff' message
artist1:addEventListener("turnOff", iPad)

---------------------------------------------------------------------------

-- artist2 is both a listener and a event dispatcher
local artist2 = EvtD{
	name = "Artist2",

	draw = function(event, ...)
		-- event.target is artist2
		event.target:dispatchEvent({name="turnOn"})

		if event.subject then
			print(event.target.name .." is ".. event.name .."ing a ".. event.subject .." on the iPad")

			-- shows the use of extra arguments
			local func, pieces, name = ...
			func(pieces,name)
		else
			print(event.target.name .." is ".. event.name .."ing on the iPad")
		end
	end,

	rest = function(event, ...)
		event.target:dispatchEvent({name="turnOff"})
		print(event.target.name .." is ".. event.name .."ing")
	end
}

-- shows the use of table and function listeners
artist2:addEventListener("turnOff", iPad)
artist2:addEventListener("turnOn", turnOniPad)

---------------------------------------------------------------------------

-- mayor is a event dispatcher who tells others what to do
local mayor = EvtD()

-- mayor shows how much gold is collected
mayor.collectGold = function(nPieces, fromName)
	print("Mayor collected ".. nPieces .." pieces of gold from ".. fromName)
end

-- mayor tells these four people to pay attention to different messages
mayor:addEventListener("draw", cowboy1)
mayor:addEventListener("draw", cowboy2)
mayor:addEventListener("draw", artist1)
mayor:addEventListener("draw", artist2)
mayor:addEventListener("rest", artist2)

-- mayor sends the 'rest' message
mayor:dispatchEvent({name="rest"})
print("Rested 1")

-- mayor tells everyone to draw
mayor:dispatchEvent({name="draw"})

-- mayor tells these people to stop listening to the 'draw' message
mayor:removeEventListener("draw", cowboy1)
mayor:removeEventListener("draw", artist1)
print("Removed")

-- mayor tells artist1 to listen to the 'rest' message
mayor:addEventListener("rest", artist1)

-- mayor tells whoever is still listening to rest
mayor:dispatchEvent({name="rest"})
print("Rested 2")

-- mayor tells whoever is still listening to draw, with a subject and extra parameters
mayor:dispatchEvent({name="draw", subject="bandit"}, mayor.collectGold, 42, "Dave")
print("Collected gold")

-- remove all listeners listening for the 'rest' message
mayor:removeAllListeners("rest")
-- this should not be heard by any mayor listener
mayor:dispatchEvent({name="rest"})

-- remove all listeners for all messages
mayor:removeAllListeners()
-- this also won't be heard because all listeners are removed
mayor:dispatchEvent({name="draw", subject="bandit"}, mayor.collectGold, 42, "Dave")

-- test the once() method, uncomment the printListeners() lines to verify it's gone after the event is dispatched once:

mayor:once( "bye", function()
	print( "Goodbye!" )
end)

--mayor:printListeners()
mayor:dispatchEvent( {name="bye"} )
--mayor:printListeners()
```
Here is the output from the code:

```
iPad is turned off by Artist2 (table)
Artist2 is resting
Rested 1
Cowboy1 is drawing a gun
Cowboy2 is drawing a gun
Artist1 is drawing a picture
iPad is turned on by Artist2 (function)
Artist2 is drawing on the iPad
Removed
iPad is turned off by Artist2 (table)
Artist2 is resting
Artist1 is resting
iPad is turned off by Artist1 (table)
Rested 2
Cowboy1 is drawing a gun and shooting a bandit
Cowboy2 is drawing a gun and shooting a bandit
Artist1 is drawing a picture
iPad is turned on by Artist2 (function)
Artist2 is drawing a bandit on the iPad
Mayor collected 42 pieces of gold from Dave
Collected gold
Goodbye!
```

EventDispatcher provides a broadcaster/listener event mechanism to regular Lua objects. Corona developers can write cleaner object-oriented messaging code that doesn’t rely on display objects or send messages from the global Runtime.

---

The MIT License (MIT)

Copyright (c) 2014 Dave Yang / Quantumwave Interactive Inc. @ qwmobile.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.