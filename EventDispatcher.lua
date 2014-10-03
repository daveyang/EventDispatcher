--[[

EventDispatcher.lua

Provides custom event broadcaster/listener mechanism to regular Lua objects.

Created by: Dave Yang / Quantumwave Interactive Inc.

http://qwmobile.com  |  http://swfoo.com/?p=632

Version: 1.2.0

Basic usage:
		local EvtD = require "EventDispatcher"

		local listener = {
			eventName = function(event)
				print(event.name)
			end
		}

		local broadcaster = EvtD()

		broadcaster:addEventListener( "eventName", listener ) -- or
		broadcaster:on( "eventName", listener )

		broadcaster:hasEventListener( "eventName", listener )

		broadcaster:dispatchEvent( { name="eventName" } ) -- or
		broadcaster:emit( { name="eventName" } )

		broadcaster:removeEventListener( "eventName", listener )

		broadcaster:removeAllListeners( "eventName" ) -- or
		broadcaster:removeAllListeners()

--

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

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--]]
---------------------------------------------------------------------------

local EventDispatcher = {}

function EventDispatcher:init(o)
	local o = o or {}
	o._listeners = {}
	self.__index = self
	return setmetatable(o, self)
end

---------------------------------------------------------------------------

-- Check if the event dispatcher has registered listener for the event eventName
-- Return boolean (true/false), and if found also return the index of listener object
function EventDispatcher:hasEventListener(eventName, listener)
	if eventName==nil or #eventName==0 or listener==nil then return false end

	local a = self._listeners
	if a==nil then return false end

	for i,o in next,a do
		if o~=nil and o.evt==eventName and o.obj==listener then
			return true, i
		end
	end
	return false
end

---------------------------------------------------------------------------

-- Add a listener for event eventName (a string).
-- Return addition status (true/false), position of listener is also returned if false; position=0 if failed
function EventDispatcher:addEventListener(eventName, listener)
	local found,pos = self:hasEventListener(eventName, listener)
	if found then return false,pos end

	local a = self._listeners
	if a==nil then return false,0 end

	a[#a+1] = { evt=eventName, obj=listener }
	return true
end

-- 'on' is an alias of 'addEventListener'
EventDispatcher.on = EventDispatcher.addEventListener

---------------------------------------------------------------------------

-- Dispatch event (a table, must have a 'name' key), with optional extra parameters.
-- Return dispatched status (true/false).
function EventDispatcher:dispatchEvent(event, ...)
	if event==nil or event.name==nil or type(event.name)~="string" or #event.name==0 then return false end

	local a = self._listeners
	if a==nil then return false end

	local dispatched = false
	for _,o in next,a do
		if o~=nil and o.obj~=nil and o.evt==event.name then
			event.target = o.obj
			event.source = self

			if type(o.obj)=="function" then
				o.obj(event, ...)
				dispatched = true
			elseif type(o.obj)=="table" then
				local f = o.obj[event.name]
				if f~= nil then
					f(event, ...)
					dispatched = true
				end
			end
		end
	end
	return dispatched
end

-- 'emit' is an alias of 'dispatchEvent'
EventDispatcher.emit = EventDispatcher.dispatchEvent

---------------------------------------------------------------------------

-- Remove listener with the eventName event from the event dispatcher.
-- Return removal status (true/false).
function EventDispatcher:removeEventListener(eventName, listener)
	local found,pos = self:hasEventListener(eventName, listener)
	if found then
		table.remove(self._listeners, pos)
	end
	return found
end

---------------------------------------------------------------------------

-- Remove all listeners with the eventName event from the event dispatcher.
-- If the optional eventName is nil, all listeners are removed from the event dispatcher.
-- Return removal status (true/false).
function EventDispatcher:removeAllListeners(eventName)
	local a = self._listeners
	if a==nil then return false end

	if eventName==nil then
		self._listeners = {}
		return true
	else
		local found = false
		local i = #a

		while i>0 do
			local o = a[i]
			if o~=nil and o.evt==eventName then
				table.remove(a, i)
				found = true
			end
			i = i - 1
		end
		return found
	end
end

---------------------------------------------------------------------------

-- create syntactic sugar to automatically call init()
setmetatable(EventDispatcher, { __call = function(_, ...) return EventDispatcher:init(...) end })

return EventDispatcher
