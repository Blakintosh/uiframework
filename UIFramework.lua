local DECLARATION = [[
	UI Framework alpha v1.2.0
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

-- The container for the sequences system
if not UIS then
	UIS = require("ui.uif.UIFramework_Sequences")
end

-- The container for the utility functions
if not UIU then
    UIU = require("ui.uif.UIFramework_Utility")
end

-- The container for the theme system
if not UIT then
	UIT = {
		Fonts = {
			Default = "fonts/default.ttf"
		},
		Colors = {
			White = {1, 1, 1},
			Black = {0, 0, 0},
			Red = {1, 0, 0},
			Green = {0, 1, 0},
			Blue = {0, 0, 1},
			Yellow = {1, 1, 0},
			Cyan = {0, 1, 1},
			Magenta = {1, 0, 1},
			Orange = {1, 0.5, 0},
			Purple = {0.5, 0, 1},
			Pink = {1, 0, 0.5},
			Gray = {0.5, 0.5, 0.5},
			LightGray = {0.75, 0.75, 0.75},
			DarkGray = {0.25, 0.25, 0.25}
		}
	}
end

UIF.ImportTheme = function(theme)
	if type(theme) == "string" then
		theme = require(theme)
	end

	if theme.Fonts then
		for name, path in pairs(theme.Fonts) do
			UIT.Fonts[name] = path
		end
	end

	if theme.Colors then
		for name, color in pairs(theme.Colors) do
			UIT.Colors[name] = color
		end
	end
end

require("ui.uif.UIFramework_Theme")

UIF.__debug = true -- Will do something in a later version
UIF.__primitiveResolutionScalar = 2

UIF.__SafeCall = function(func, contextLabel)
	if UIF.__debug then
		local success, result = pcall(func)
		if not success then
			Engine.ComError(Enum.errorCode.ERROR_UI, "UIFramework __debug: something went wrong causing a UI Error.\nError context: "..contextLabel.."\nError details: "..result)
            return nil
		end
        return result
	else
		return func()
	end
end

require("ui.uif.UIFramework_Utility")

UIF.__PreCommonSetup = function(self, controller)
    self.__dependents = {}
    self.__states = {}
    self.__sequences = {}

    UIU.UpgradeWidgetFeatures(self)

    self.UpgradeFunctionalityFor = function(self, target)
        UIU.UpgradeWidgetFeatures(target)
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
end

UIF.__PostCommonSetup = function(self, controller)
    self.clipsPerState = {}
    local stateConditions = {}
    local anyStateConditionsGiven = false

    for _, state in pairs(self.__states) do
        self.clipsPerState[state.name] = {}
        for _, clipData in pairs(state.clips) do
            local clip = clipData.clip
            if self.__sequences[state.name] and self.__sequences[state.name][clip] then
                self.clipsPerState[state.name][clip] = function()
                    UIF.__SafeCall(function()
                        UIS.AnimateSequence(self, state.name, clip, clipData)
                    end, "Running sequence '"..clip.."' in state '"..state.name.."' for widget '"..self.id.."'' failed.")
                end
            end
        end

        if state.condition then
            table.insert(stateConditions, {
                stateName = state.name,
                condition = function(menu, element, event)
                    local result = UIF.__SafeCall(function()
                        return state.condition(menu, element, event)
                    end, "Running state condition check for state '"..state.name.."' on widget '"..self.id.."' failed.")

                    if result ~= nil then
                        return result
                    end
                    return false
                end
            })
            anyStateConditionsGiven = true
        end
    end

    if anyStateConditionsGiven then
        self:mergeStateConditions(stateConditions)
    end

    LUI.OverrideFunction_CallOriginalSecond( self, "close", function ( element )
        UIF.__SafeCall(function()
            for _, dependent in pairs( element.__dependents ) do
                dependent:close()
            end
        end, "Closing an instance of '"..self.id.."'' failed to evaluate.")
    end)
end

UIF.__ConstructElement = function(self, menu, controller, identifier, creationFunction, preLoadFunction, postLoadFunction)
    self:setClass(UIE[identifier])
    self:setUseStencil(false)
    self.soundSet = "default"
    self.id = identifier

    if preLoadFunction then
        UIF.__SafeCall(function()
            preLoadFunction(self, controller, menu)
        end, "The pre-load function for an instance of widget '"..identifier.."'' failed to evaluate.")
    end

    UIF.__PreCommonSetup(self, controller)

    UIF.__SafeCall(function()
        creationFunction(self, menu, controller)
    end, "Creation of the UI instance for widget '"..identifier.."'' failed to evaluate.")

    UIF.__PostCommonSetup(self, controller)

    if postLoadFunction then
        UIF.__SafeCall(function()
            postLoadFunction(self, controller, menu)
        end, "The post-load function for an instance of widget '"..identifier.."'' failed to evaluate.")
    end
end

UIF.DefineHorizontalList = function(identifier, creationFunction, preLoadFunction, postLoadFunction)
	UIE[identifier] = InheritFrom(LUI.UIElement)

	UIE[identifier].new = function(menu, controller)
		local self = LUI.UIHorizontalList.new( {
            left = 0,
            top = 0,
            right = 0,
            bottom = 0,
            leftAnchor = true,
            topAnchor = true,
            rightAnchor = true,
            bottomAnchor = true,
            spacing = 0
        } )

		UIF.__ConstructElement(self, menu, controller, identifier, creationFunction, preLoadFunction, postLoadFunction)

		return self
	end
end

UIF.DefineVerticalList = function(identifier, creationFunction, preLoadFunction, postLoadFunction)
	UIE[identifier] = InheritFrom(LUI.UIElement)

	UIE[identifier].new = function(menu, controller)
		local self = LUI.UIVerticalList.new( {
            left = 0,
            top = 0,
            right = 0,
            bottom = 0,
            leftAnchor = true,
            topAnchor = true,
            rightAnchor = true,
            bottomAnchor = true,
            spacing = 0
        } )

		UIF.__ConstructElement(self, menu, controller, identifier, creationFunction, preLoadFunction, postLoadFunction)

		return self
	end
end

UIF.DefineElement = function(identifier, creationFunction, preLoadFunction, postLoadFunction)
	UIE[identifier] = InheritFrom(LUI.UIElement)

	UIE[identifier].new = function(menu, controller)
		local self = LUI.UIElement.new()

		UIF.__ConstructElement(self, menu, controller, identifier, creationFunction, preLoadFunction, postLoadFunction)

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

		if preLoadFunction then
			UIF.__SafeCall(function()
				preLoadFunction(self, controller, menu)
			end, "The pre-load function for an instance of menu '"..identifier.."'' failed to evaluate.")
		end

		UIF.__PreCommonSetup(self, controller)

		UIF.__SafeCall(function()
			creationFunction(self, controller)
		end, "Creation of the UI instance for menu '"..identifier.."'' failed to evaluate.")

        UIF.__PostCommonSetup(self, controller)

		if postLoadFunction then
			UIF.__SafeCall(function()
				postLoadFunction(self, controller)
			end, "The post-load function for an instance of menu '"..identifier.."'' failed to evaluate.")
		end

		return self
	end
end

-- Add stock widgets
require("ui.uif.widgets._Includes")