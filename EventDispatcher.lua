
-- EventDispatcher.lua
--
-- Provides custom event broadcaster/listener mechanism to regular Lua objects.
--
-- Created by: Dave Yang / Quantumwave Interactive Inc.
--
-- Version: 1.1.3
--
-- Basic usage:
--		local EvtD = require "EventDispatcher"
--		local listener = {
--			eventName = function(event)
--				print(event.name)
--			end
--		}
--		local broadcaster = EvtD()
--		broadcaster:addEventListener( "eventName", listener )
--		broadcaster:hasEventListener( "eventName", listener )
--		broadcaster:dispatchEvent( { name="eventName" } )
--		broadcaster:removeEventListener( "eventName", listener )
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

---------------------------------------------------------------------------

-- Dispatch event (a table, must have a 'name' key), with optional extra parameters.
-- Return dispatched status (true/false).
function EventDispatcher:dispatchEvent(event, ...)
	if event==nil or event.name==nil or type(event.name)~="string" or #event.name==0 then return false end

	local a = self._listeners
	if a==nil then return false end

	local dispatched = false
	for i,o in next,a do
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

---------------------------------------------------------------------------

-- Remove listener with eventName event from the event dispatcher.
-- Return removal status (true/false).
function EventDispatcher:removeEventListener(eventName, listener)
	local found,pos = self:hasEventListener(eventName, listener)
	if found then
		table.remove(self._listeners, pos)
	end
	return found
end

---------------------------------------------------------------------------

-- create syntactic sugar to automatically call init()
setmetatable(EventDispatcher, { __call = function(_, ...) return EventDispatcher:init(...) end })

return EventDispatcher
