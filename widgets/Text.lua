
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

local function AddMethodRedirections(self, controller)
    -- There may be more functions needed here. Please file an issue on GitHub if so.
	self.setText = function(self, text)
		self.text:setText(text)
        self.__text = text
    end

	self.setTTF = function(self, ttf)
		self.text:setTTF(ttf)
        self.__font = ttf
	end

	self.setRGB = function(self, r, g, b)
		self.text:setRGB(r, g, b)
        self.__rgb = {r, g, b}
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
		return self.text:getTextWidth() / UIF.__primitiveResolutionScalar
	end

    self.setAlpha = function(self, value)
        self.text:setAlpha(value)
        self.__alpha = value
    end

    UIU.SetupAbstractions(self, controller, {
        -- The below are abstractions of the above
        Text = {
            get = function(self, controller)
                return self.__text or ""
            end,
            set = function(self, controller, value)
                self:setText(value)
            end
        },
        Color = {
            get = function(self, controller)
                return self.__rgb or {1, 1, 1}
            end,
            set = function(self, controller, value)
                local color = value

                -- Theme colour
                if type(value) == 'string' then
                    local color = UIT.Colors[value]
                    if not color then
                        Engine.ComError(Enum.errorCode.ERROR_UI, "Attempt to set string color on element '"..self.id.."'. '"..value.."' not found in the theme.")
                        return
                    end
                end

                self:setRGB(value[1], value[2], value[3])
            end
        },
        Font = {
            get = function(self, controller)
                return self.__font or "fonts/default.ttf"
            end,
            set = function(self, controller, value)
                local font = value

                -- Checks for the presence of a file extension, otherwise a theme font is assumed.
                if not value.find(value, "%.[^%.]+$") then
                    font = UIT.Fonts[value]
                    if not font then
                        Engine.ComError(Enum.errorCode.ERROR_UI, "Attempt to set invalid font on element '"..self.id.."'. '"..value.."' not found in UIT.Fonts.")
                        return
                    end
                end

                self:setTTF(font)
            end
        },
        Alpha = {
            get = function(self, controller)
                return self.__alpha or 1
            end,
            set = function(self, controller, value)
                self:setAlpha(value)
            end
        }
    })

    self.SubscribeText = function(self, data, localize)
        localize = localize or true
        if localize then
            -- Mutates anyway, not strictly necessary to reassign
            data = UIU.LocaleSub(data)
        end
        self:SubscribeProp("Text", data)
    end
end

UIF.DefineElement("Text", function(self, menu, controller)
	local resolutionScalar = UIF.__primitiveResolutionScalar or 1

	-- Wrapper which is downscaled to allow for high resolution text
	self.wrapper = LUI.UIElement.new()
	self.wrapper:setUseStencil(false)
	self.wrapper:setScale(1 / resolutionScalar)

	-- Update the bounds of the high resolution wrapper every time the root's dimensions change.
	LUI.OverrideFunction_CallOriginalFirst(self, "setLeftRight", function(element, anchorL, anchorR, startPos, endPos)
        -- Sometimes comes through as booleans, sometimes as numbers - this enforces consistency.
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
        -- Sometimes comes through as booleans, sometimes as numbers - this enforces consistency.
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
    AddMethodRedirections(self, controller)

    self.__interceptor = ""
	
	self.wrapper:addElement(self.text)
	self:AddDependent(self.wrapper)
end, nil, nil)