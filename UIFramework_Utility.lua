require("ui.blak.utility.DebugUtils")

local UIU = {}

UIU.UpgradeWidgetFeatures = function(self)
	self.SetFont = function(self, font)
		if not UIT.Fonts[font] then
			error("Tried to set widget to font '"..font.."', but it doesn't exist.")
		end
		self:setTTF(UIT.Fonts[font])
	end

	self.SetColor = function(self, color)
		if not UIT.Colors[color] then
			error("Tried to set widget to color '"..color.."', but it doesn't exist.")
		end
		self:setRGB(unpack(UIT.Colors[color]))
	end

	self.SubscribeTo = function(self, controller, modelName, callback)
		self:subscribeToModel(Engine.GetModelForController(controller, modelName), function(model)
			local modelValue = Engine.GetModelValue(model)
			if modelValue then
				UIF.__SafeCall(function()
					callback(modelValue, model)
				end, "A model subscription callback for element '"..self.id.."' for model '"..modelName.."' failed to evaluate.")
			end
		end)
	end

	self.SubscribeForStateChange = function(self, menu, controller, modelName)
		self:subscribeToModel(Engine.GetModelForController(controller, modelName), function(model)
			menu:updateElementState(self, {
				name = "model_validation",
				menu = menu,
				modelValue = Engine.GetModelValue(model),
				modelName = modelName
			})
		end)
	end

	self.SubscribeToSelf = function(self, modelName, callback)
		self:linkToElementModel(self, modelName, true, function(model)
			local modelValue = Engine.GetModelValue(model)
			if modelValue then
				UIF.__SafeCall(function()
					callback(modelValue, model)
				end, "A self-model subscription callback for element '"..self.id.."' for model '"..modelName.."' failed to evaluate.")
			end
		end)
	end

	self.SubscribeToSelfForStateChange = function(self, menu, modelName)
		self:linkToElementModel(self, modelName, true, function(model)
			menu:updateElementState(self, {
				name = "model_validation",
				menu = menu,
				modelValue = Engine.GetModelValue(model),
				modelName = modelName
			})
		end)
	end

	self.SubscribeToWidget = function(self, target, modelName, callback)
		self:linkToElementModel(target, modelName, true, function(model)
			local modelValue = Engine.GetModelValue(model)
			if modelValue then
				UIF.__SafeCall(function()
					callback(modelValue, model)
				end, "A targeted-model subscription callback for element '"..self.id.."' for model '"..modelName.."' on element '"..target.id.."' failed to evaluate.")
			end
		end)
	end

	self.SubscribeToWidgetForStateChange = function(self, target, menu, modelName)
		self:linkToElementModel(target, modelName, true, function(model)
			menu:updateElementState(self, {
				name = "model_validation",
				menu = menu,
				modelValue = Engine.GetModelValue(model),
				modelName = modelName
			})
		end)
	end
end

-- Sets up prop-based abstractions on the given element, allowing for easier manipulation of the element.
UIU.SetupAbstractions = function(self, controller, abstractions)
    self.__abstractions = abstractions

    -- Sets up getters and setters on the element
    local metaTable = {
        __index = function(t, key)
            if self.__abstractions[key] then
                if self.__abstractions[key].get and type(self.__abstractions[key].get) == "function" then
                    return self.__abstractions[key].get(self, controller)
                end
            end
            Engine.ComError(Enum.errorCode.ERROR_UI, "No getter exists for prop '"..key.."' on element '"..self.id.."'. Please check usage.")
            return nil
        end,
        __newindex = function(t, key, value)
            if self.__abstractions[key] then
                if self.__abstractions[key].set and type(self.__abstractions[key].set) == "function" then
                    self.__abstractions[key].set(self, controller, value)
                    return
                end
            end
            Engine.ComError(Enum.errorCode.ERROR_UI, "No setter exists for prop '"..key.."' on element '"..self.id.."'. Please check usage.")
        end
    }

    -- It has to be its own container, as otherwise the UIElement stops behaving properly.
    local props = {}

    setmetatable(props, metaTable)
    self.Props = props
    
    -- General-purpose model subscription abstraction. Sets the given prop to the value of the model.
    self.SubscribeProp = function(self, prop, data)
        -- If controller is explicitly provided, use that, otherwise default to the same controller as the element's instantiation.
        local controller = data.controller or controller
        
        -- For element bindings
        local target = data.target
        if data.self then
            target = self
        end

        -- When specified, means the function should be called around modelValue before setting.
        local processFn = data.processFn

        -- Common callback function for the subscriptions.
        local function CallbackFn(model)
            local modelValue = Engine.GetModelValue(model)
            
            if modelValue then
                UIF.__SafeCall(function()
                    if processFn then
                        modelValue = processFn(modelValue)
                    end

                    self.Props[prop] = modelValue
                end, "A model subscription callback on prop '"..prop.."' for element '"..self.id.."' failed to evaluate.")
            end
        end

        -- For element model bindings specifically
        -- This is used instead of doing a standard subscription as it has additional logic to handle when target:getModel() is nil.
        if target then
            local modelName = data.modelName
            if not modelName then
                Engine.ComError(Enum.errorCode.ERROR_UI, "No modelName provided for prop subscription on element '"..self.id.."'. Please check usage.")
                return
            end
            
            self:linkToElementModel(target, modelName, true, CallbackFn)
            return
        end

        -- For per-controller or global model bindings
        local model = data.model

        -- They did not pass a model directly, so resolve it based on the provided modelName.
        if not model then
            local modelName = data.modelName
            
            if modelName then
                model = UIU.__ResolveModel(controller, modelName, data.global)
            else
                Engine.ComError(Enum.errorCode.ERROR_UI, "No model or modelName provided for prop subscription on element '"..self.id.."'. Please check usage.")
                return
            end
        end
        
        self:subscribeToModel(model, CallbackFn)
    end
end

-- Adds an abstraction to an element that's already got them.
UIU.AddAbstraction = function(self, name, abstraction)
    if not self.__abstractions or not self.Props then
        Engine.ComError(Enum.errorCode.ERROR_UI, "Element '"..self.id.."' does not have abstractions set up. Please ensure that UIU.SetupAbstractions is used before adding additional abstractions.")
        return
    end
    self.__abstractions[name] = abstraction
end

-- Subscription that requires the image to be registered so it can be set.
UIU.ImSub = function(data)
    data.processFn = RegisterImage
    return data
end

-- Subscription that requires the value to be localized before being set.
UIU.LocaleSub = function(data)
    data.processFn = Engine.Localize
    return data
end

-- Fetches the relevant model based on model name and whether it's a global model.
UIU.__ResolveModel = function(controller, modelName, global)
    if not modelName then
        return nil
    end

    local modelRoot = nil
    if global then
        -- Global model
        modelRoot = Engine.GetGlobalModel()
    else
        -- Per-controller model
        modelRoot = Engine.GetModelForController(controller)
    end

    return Engine.GetModel(modelRoot, modelName)
end

return UIU