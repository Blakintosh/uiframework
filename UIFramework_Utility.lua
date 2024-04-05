local DECLARATION = [[
	UI Framework alpha v1.1.0 - utilities component
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

function UpgradeWidgetFeatures(self)
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