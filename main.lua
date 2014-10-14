
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
			func(pieces, name)
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

---------------------------------------------------------------------------

-- test the once() method, uncomment the printListeners() lines to verify it's gone after the event is dispatched once
mayor:once("bye", function()
	print("Goodbye!")
end)

--mayor:printListeners()

-- test the emit() method and the simpler event as string (instead of table with a 'name' field)
mayor:emit("bye")

--mayor:printListeners()
