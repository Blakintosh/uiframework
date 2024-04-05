# UI Framework
![UI Framework Logo](https://gscode.net/images/uif.png)

A new paradigm for building UI in Call of Duty: Black Ops III.

UI Framework is currently in an alpha stage and may contain problems. Further documentation coming soon.

## Features

### Reduced boiler-plating
Cut back on unnecessary, repeated code when instantiating menus and widgets.

**Before**
```lua
CoD.Foo = InheritFrom(LUI.UIElement)
CoD.Foo.new = function(menu, controller)
	local self = LUI.UIElement.new()
	self:setClass(CoD.Foo)
	self:setUseStencil(false)
	self.soundSet = "default"
	self.id = "Foo"

	if PreLoadFunc then
		PreLoadFunc(self, controller, menu)
	end

	-- elements...

	LUI.OverrideFunction_CallOriginalSecond( self, "close", function ( element )
		-- ...
	end)

	if PostLoadFunc then
		PostLoadFunc(self, controller, menu)
	end

	return self
end
```
Create element using: `CoD.Foo.new`

**After**
```lua
UIF.DefineElement("Foo", function(self, menu, controller)
	-- elements...
end, PreLoadFunc, PostLoadFunc)
```
Create element using: `UIE.Foo.new`

#### Enhanced element feature-set
The `UIE.DefineElement` and `UIE.DefineMenu` functions add further functionality accessible to your creation code.

Dependents (`AddDependent`) are automatically called to close when the parent is closed, without you having to add this override function yourself.

**Before**
```lua
self.elementFoo = -- ...
self:addElement(self.elementFoo)

LUI.OverrideFunction_CallOriginalSecond( self, "close", function ( element )
	self.elementFoo:close()
end)
```

**After**
```lua
self.elementFoo = -- ...
self:AddDependent(self.elementFoo)
```

### Clips, States and Sequences

### Clips and States
Simplify the definition of clips and states.

**Before**
```lua
self.clipsPerState = {
	DefaultState = {
		DefaultClip = function()
			-- ...
		end,
		Foo = function()
			-- ...
		end
	},
	Bar = {
		DefaultClip = function()
			-- ...
		end
	}
}

self:mergeStateConditions({
	stateName = "Bar",
	condition = Condition
})
```

**After**
```lua
self:AddState("DefaultState", {"DefaultClip", "Foo"})
self:AddState("Bar", {"DefaultClip"})
```

#### Sequences
Instead of writing convoluted clip code, specify your elements' transitions using Sequences.

**Before**
```lua
DefaultClip = function()
	self:setupElementClipCounter(1)

	self.foo:completeAnimation()
	self.foo:beginAnimation("keyframe", 200, false, false, CoD.TweenType.Linear)
	self.foo:setAlpha(0)

	self.foo:registerEventHandler("transition_complete_keyframe", function(element, event)
		if not event.interrupted then
			self.foo:beginAnimatino("keyframe", 200, false, false, CoD.TweenType.Linear)
		end
		self.foo:setAlpha(1)
		if event.interrupted then
			self.clipFinished(self.foo, {})
		else
			self.foo:registerEventHandler("transition_complete_keyframe", self.clipFinished)
		end
	end)
end
```
Just writing that example annoyed me.

**After**
```lua
self:AddSequence(self.foo, "DefaultState", "DefaultClip", {
	{
		duration = 200,
		setAlpha = 0
	},
	{
		duration = 200,
		setAlpha = 1
	}
})
```

### Improved stock widgets
Higher resolution text widgets improve text fidelity and make your UI look more polished and modern.

**Before**
```lua
self.text = LUI.UIText.new()
-- ... properties
self:addElement(self.text)
```

**After**
```lua
self.text = UIE.Text.new()
-- ... properties
self:AddDependent(self.text)
```
will increase the resolution your text elements render at from 720p to 1440p.

### and other features.

## Usage
In your zone file:
```
rawfile,ui/uif/UIFramework.lua
rawfile,ui/uif/UIFramework_Sequences.lua
rawfile,ui/uif/UIFramework_Widgets.lua
```

and some relevant place high up in your map/mod's lua:
```lua
require("ui.uif.UIFramework")
```