local DECLARATION = [[
	UI Framework alpha v1.0.0 - root component
	Copyright (C) 2023 blakintosh

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

if EnableGlobals then
	EnableGlobals()
end

if not UIF then
	UIF = {}
end

-- The container for elements defined using UI Framework
if not UIE then
	UIE = {}
end

if not UIS then
	UIS = require("ui.uif.UIFramework_Sequences")
end

UIF.__debug = true -- Will do something in a later version
UIF.__textResolutionScalar = 2

UIF.DefineElement = function(identifier, creationFunction, preLoadFunction, postLoadFunction)
	UIE[identifier] = InheritFrom(LUI.UIElement)

	UIE[identifier].new = function(menu, controller)
		local self = LUI.UIElement.new()
		self:setClass(UIE[identifier])
		self:setUseStencil(false)
		self.soundSet = "default"
		self.id = identifier
		self.__dependents = {}
		self.__states = {}
		self.__sequences = {}

		if preLoadFunction then
			preLoadFunction(self, controller, menu)
		end

		self.AddDependent = function(self, dependent)
			table.insert(self.__dependents, dependent)
			self:addElement(dependent)
		end

		self.AddState = function(self, stateName, clips, conditionFunction)
			local processedClips = {}

			-- Check if the clips are strings, and if so, convert to the required table format
			for _, clip in pairs(clips) do
				if type(clip) == "string" then
					table.insert(processedClips, {clip = clip, loop = false}) -- Default metadata for string clips
				else
					table.insert(processedClips, clip) -- Clip is already in table format, with metadata
				end
			end

			table.insert(self.__states, {name = stateName, clips = processedClips, condition = conditionFunction})
		end

		self.AddSequence = function(self, child, state, clip, sequences)
			if not self.__sequences[state] then
				self.__sequences[state] = {}
			end

			if not self.__sequences[state][clip] then
				self.__sequences[state][clip] = {}
			end

			table.insert(self.__sequences[state][clip], { widget = child, sequences = sequences })
		end

		creationFunction(self, menu, controller)

		self.clipsPerState = {}
		local stateConditions = {}
		local anyStateConditionsGiven = false

		for _, state in pairs(self.__states) do
			self.clipsPerState[state.name] = {}
			for _, clipData in pairs(state.clips) do
				local clip = clipData.clip
				if self.__sequences[state.name] and self.__sequences[state.name][clip] then
					self.clipsPerState[state.name][clip] = function()
						UIS.AnimateSequence(self, state.name, clip, clipData)
					end
				end
			end

			if state.condition then
				table.insert(stateConditions, {
					stateName = state.name,
					condition = state.condition
				})
				anyStateConditionsGiven = true
			end
		end

		if anyStateConditionsGiven then
			self:mergeStateConditions(stateConditions)
		end

		LUI.OverrideFunction_CallOriginalSecond( self, "close", function ( element )
			for _, dependent in pairs( element.__dependents ) do
				dependent:close()
			end
		end)

		if postLoadFunction then
			postLoadFunction(self, controller, menu)
		end

		return self
	end
end


UIF.DefineMenu = function(identifier, creationFunction, preLoadFunction, postLoadFunction)
	LUI.createMenu[identifier] = function(controller)
		local self = CoD.Menu.NewForUIEditor( identifier )
		self:setOwner(controller)
		self:setLeftRight( true, true, 0, 0 )
		self:setTopBottom( true, true, 0, 0 )
		self:playSound( "menu_open", controller )
		local buttonPromptsModelName = identifier .. ".buttonPrompts"
		self.buttonModel = Engine.CreateModel( Engine.GetModelForController( controller ), buttonPromptsModelName )
		self.soundSet = "default"
		self.__dependents = {}
		self.__states = {}
		self.__sequences = {}

		if preLoadFunction then
			preLoadFunction(self, controller)
		end

		self.AddDependent = function(self, dependent)
			table.insert(self.__dependents, dependent)
			self:addElement(dependent)
		end

		self.AddState = function(self, stateName, clips, conditionFunction)
			local processedClips = {}

			-- Check if the clips are strings, and if so, convert to the required table format
			for _, clip in pairs(clips) do
				if type(clip) == "string" then
					table.insert(processedClips, {clip = clip, looping = false}) -- Default metadata for string clips
				else
					table.insert(processedClips, clip) -- Clip is already in table format, with metadata
				end
			end

			table.insert(self.__states, {name = stateName, clips = processedClips, condition = conditionFunction})
		end

		self.AddSequence = function(self, child, state, clip, sequences)
			if not self.__sequences[state] then
				self.__sequences[state] = {}
			end

			if not self.__sequences[state][clip] then
				self.__sequences[state][clip] = {}
			end

			table.insert(self.__sequences[state][clip], { widget = child, sequences = sequences })
		end

		creationFunction(self, controller)

		self.clipsPerState = {}
		local stateConditions = {}
		local anyStateConditionsGiven = false

		for _, state in pairs(self.__states) do
			self.clipsPerState[state.name] = {}
			for _, clipData in pairs(state.clips) do
				local clip = clipData.clip
				if self.__sequences[state.name] and self.__sequences[state.name][clip] then
					self.clipsPerState[state.name][clip] = function()
						UIS.AnimateSequence(self, state.name, clip, clipData)
					end
				end
			end

			if state.condition then
				table.insert(stateConditions, {
					stateName = state.name,
					condition = state.condition
				})
				anyStateConditionsGiven = true
			end
		end

		if anyStateConditionsGiven then
			self:mergeStateConditions(stateConditions)
		end

		LUI.OverrideFunction_CallOriginalSecond( self, "close", function ( element )
			for _, dependent in pairs( element.__dependents ) do
				dependent:close()
			end
		end)

		if postLoadFunction then
			postLoadFunction(self, controller)
		end

		return self
	end
end

-- Add stock widgets
require("ui.uif.UIFramework_Widgets")