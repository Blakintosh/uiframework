local DECLARATION = [[
	UI Framework alpha v1.1.0 - widgets component
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

require("ui.blak.utility.DebugUtils")

local function SetBoundsToParent(self, parent, resolutionScalar)
	-- Resize the wrapper to the parent's size, accounting for scaling.
	local width, height = parent:getLocalSize()

	local boundW = width / 2
	local boundH = height / 2

	self:setLeftRight(false, false, -boundW * resolutionScalar, boundW * resolutionScalar)
	self:setTopBottom(false, false, -boundH * resolutionScalar, boundH * resolutionScalar)
end

local function SetTextAnchorsToParent(self, parent, resolutionScalar)
	-- Get the parent's bounds and anchors.
	local width, height = parent:getLocalSize()
	local anchorL, anchorR, startPos, endPos = parent.__anchorL, parent.__anchorR, parent.__startPosLR, parent.__endPosLR
	local anchorT, anchorB, startPos2, endPos2 = parent.__anchorT, parent.__anchorB, parent.__startPosTB, parent.__endPosTB

	if anchorL ~= nil then
        -- If the text is centered, then we need to set the bounds to the center of the wrapper.
	    if anchorL == 0 and anchorR == 0 then
            self:setLeftRight(false, false, -(width / 2) * resolutionScalar, (width / 2) * resolutionScalar)
        -- If the text is anchored to the left or right, then we need to set the bounds to the left or right of the wrapper.
        elseif anchorL ~= 1 or anchorR ~= 1 then
            if anchorL == 1 then
                self:setLeftRight(true, false, 0, width * resolutionScalar)
            else
                self:setLeftRight(false, true, -width * resolutionScalar, 0)
            end
        else
            Engine.ComError(Enum.errorCode.ERROR_UI, "Double or fractional anchoring is not supported by UIE.Text.")
        end
    end

    if anchorT ~= nil then
        -- If the text is centered, then we need to set the bounds to the center of the wrapper.
        if anchorT == 0 and anchorB == 0 then
            self:setTopBottom(false, false, -(height / 2) * resolutionScalar, (height / 2) * resolutionScalar)
        elseif anchorT ~= 1 or anchorB ~= 1 then
        -- If the text is anchored to the top or bottom, then we need to set the bounds to the top or bottom of the wrapper.
            if anchorT == 1 then
                self:setTopBottom(true, false, 0, height * resolutionScalar)
            else
                self:setTopBottom(false, true, -height * resolutionScalar, 0)
            end
        else
            Engine.ComError(Enum.errorCode.ERROR_UI, "Double or fractional anchoring is not supported by UIE.Text.")
        end
    end
end

UIF.DefineElement("Text", function(self, menu, controller)
	local resolutionScalar = UIF.__textResolutionScalar or 0.5

	-- Wrapper which is downscaled to allow for high resolution text
	self.wrapper = LUI.UIElement.new()
	self.wrapper:setUseStencil(false)
	self.wrapper:setScale(1 / resolutionScalar)

	-- Update the bounds of the high resolution wrapper every time the root's dimensions change.
	LUI.OverrideFunction_CallOriginalFirst(self, "setLeftRight", function(element, anchorL, anchorR, startPos, endPos)
        if type(anchorL) == "boolean" then
            anchorL = anchorL and 1 or 0
        end
        if type(anchorR) == "boolean" then
            anchorR = anchorR and 1 or 0
        end
        element.__anchorL = anchorL
        element.__anchorR = anchorR
        element.__startPosLR = startPos
        element.__endPosLR = endPos

		SetBoundsToParent(self.wrapper, element, resolutionScalar)
		SetTextAnchorsToParent(self.text, element, resolutionScalar)
	end)
	LUI.OverrideFunction_CallOriginalFirst(self, "setTopBottom", function(element, anchorT, anchorB, startPos, endPos)
        if type(anchorT) == "boolean" then
            anchorT = anchorT and 1 or 0
        end
        if type(anchorB) == "boolean" then
            anchorB = anchorB and 1 or 0
        end
        element.__anchorT = anchorT
        element.__anchorB = anchorB
        element.__startPosTB = startPos
        element.__endPosTB = endPos

		SetBoundsToParent(self.wrapper, element, resolutionScalar)
		SetTextAnchorsToParent(self.text, element, resolutionScalar)
	end)

	self.text = LUI.UIText.new()

    self.__interceptor = ""

	-- There may be more functions needed here
	self.setText = function(self, text)
		self.text:setText(text)
    end

	self.setTTF = function(self, ttf)
		self.text:setTTF(ttf)
	end

	self.setMaterial = function(self, material)
		self.text:setMaterial(material)
	end

	self.setRFTMaterial = function(self, material)
		self.text:setRFTMaterial(material)
	end

	self.setShaderVector = function(self, vector, x, y, z, w)
		self.text:setShaderVector(vector, x, y, z, w)
	end

	self.setAlignment = function(self, alignment)
		self.text:setAlignment(alignment)
	end

	self.getTextWidth = function(self)
		return self.text:getTextWidth() / UIF.__textResolutionScalar
	end
	
	self.wrapper:addElement(self.text)
	self:AddDependent(self.wrapper)
end, nil, nil)