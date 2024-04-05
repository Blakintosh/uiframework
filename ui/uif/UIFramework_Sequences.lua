local DECLARATION = [[
	UI Framework alpha v1.0.0 - sequences component
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

local UIS = {}

UIS.Tween = {}
UIS.TweenGraphs = {}

-- In out sine
UIS.TweenGraphs.inOutSine = function(x)
    return -(( math.cos(math.pi * x) - 1) / 2)
end
-- Linear (default)
UIS.TweenGraphs.linear = function(x)
    return x
end
-- Quintic graphs
UIS.TweenGraphs.outQuint = function(x)
    return (1 - (1 - x)^5)
end
-- Cubic graphs
UIS.TweenGraphs.inCubic = function(x)
    return x^3
end
-- Quadratic graphs
UIS.TweenGraphs.inOutQuad = function(x)
    if x < 0.5 then
        return (2 * x * x)
    else
        return (1 - (-2 * x + 2)^2 / 2)
    end
end
UIS.TweenGraphs.inQuad = function(x)
    return x*x
end
UIS.TweenGraphs.outQuad = function(x)
    return (1 - (1 - x) * (1 - x))
end
-- Bounce graphs
UIS.TweenGraphs.outBounce = function(x)
    if x < 1 / 2.75 then
        return (7.5625 * x * x)
    elseif x < 2 / 2.75 then
        x = x - (1.5 / 2.75)
        return (7.5625 * x * x + 0.75)
    elseif x < 2.5 / 2.75 then
        x = x - (2.25 / 2.75)
        return (7.5625 * x * x + 0.9375)
    else
        x = x - (2.625 / 2.75)
        return (7.5625 * x * x + 0.984375)
    end
end

local function NextInterpolationStep(self, startClock, timeElapsed, duration, tween, tweenUpdateCallback)
    local dur = 25 -- 40 hz. Higher refresh rates can worsen time discrepancy issues
    local amendedDur = dur

    local currentStepClock = Engine.CurrentGameTime()
    local timeStep = (currentStepClock - startClock)
    local outOfSync = (timeStep - timeElapsed)
    local iterationsToDo = math.floor(outOfSync / dur) + 1
    if iterationsToDo < 6 and iterationsToDo > 1 then
        amendedDur = dur * iterationsToDo
    end

    self:beginAnimation("keyframe", dur, false, false, CoD.TweenType.Linear)

    timeElapsed = timeElapsed + amendedDur

    if timeElapsed > duration then
        timeElapsed = duration
    end

    local progression = (timeElapsed / duration)
    
    local tv = tween(progression)

    tweenUpdateCallback(tv)

    self:registerEventHandler("transition_complete_keyframe", function(widget, event)
        if not event.interrupted then
            if timeElapsed >= duration then
                widget:processEvent({
                    name = "tween_complete"
                })
                return
            else
                NextInterpolationStep(widget, startClock, timeElapsed, duration, tween, tweenUpdateCallback)
                return
            end
        else
            widget:processEvent({
                name = "tween_complete",
                interrupted = true,
                progress = tv
            })
            return
        end
    end)
end

UIS.Tween.interpolate = function(self, duration, tween, tweenUpdateCallback)
    tweenUpdateCallback(0)

    local startClock = Engine.CurrentGameTime()
    NextInterpolationStep(self, startClock, 0, duration, tween, tweenUpdateCallback)
end

local function FindInitialValuesForProperty(lastSequence, property)
    for k, v in pairs(lastSequence) do
        if k == property then
            return v
        end
    end
end

UIS.GetTweenedProgress = function(progress, startv, endv)
    return (startv + ((endv - startv) * progress))
end

UIS.AnimateNextSegment = function(parent, self, event, sequenceData, lastSequence, sequenceTable, index, repeatCount, extraData)
    if event.interrupted or not sequenceTable[index] then
        sequenceData.clipsRemaining = sequenceData.clipsRemaining - 1

        if sequenceData.clipsRemaining == 0 and extraData.looping then
            parent.nextClip = extraData.clip or "DefaultClip"
        end

        parent.clipFinished(self, {})
        return
    end

    local sequence = sequenceTable[index]
	local duration = sequence.duration
	if type(duration) == "function" then
		duration = duration()
	end

    if sequence.repeat_start == true then
        UIS.AnimateNextSegment(parent, self, {}, sequenceData, lastSequence, sequenceTable, index + 1, sequence.repeat_count, extraData)
    elseif sequence.repeat_end == true then
        repeatCount = repeatCount - 1
        local goingTo = index
        if repeatCount > 0 then
            for i = index, 1, -1 do
                if sequenceTable[i].repeat_start == true then
                    goingTo = i
                    break
                end
            end
        end
        UIS.AnimateNextSegment(parent, self, {}, sequenceData, lastSequence, sequenceTable, goingTo + 1, repeatCount, extraData)
    else
        if duration > 0 then
            local tweenType = UIS.TweenGraphs.linear
            if sequence.interpolation then
                tweenType = sequence.interpolation
            end

            UIS.Tween.interpolate(self, duration, tweenType, function(progress)
                -- Iterate through the sequence table to interpolate to desired values
                for k,value in pairs(sequence) do
                    if k ~= "interpolation" and k ~= "duration" and k ~= "exec" and type(value) ~= "function" then
                        -- find the value this property had before this sequence started
                        local lastValue = FindInitialValuesForProperty(lastSequence, k)
                        -- we don't want to interpolate anything except numbers (and numbers in tables...)
                        if type(value) == "number" then
                            -- exec this property function, with the tweened progress
                            local newVal = UIS.GetTweenedProgress(progress, lastValue, value)
                            self[k](self, newVal)
                        elseif type(value) == "table" then
                            local progressTable = {}
                            -- iterate thru the table and get progress by sending it to a working table
                            for key,val in ipairs(lastValue) do
                                -- apparently I can't just copy the table as it's passed by reference, so let's do this?
                                if type(val) == "number" then
                                    progressTable[key] = UIS.GetTweenedProgress(progress, lastValue[key], value[key])
                                else
                                    progressTable[key] = value[key]
                                end
                            end
                            self[k](self, unpack(progressTable))
                        end
                    end
                end
            end)
            for k,value in pairs(sequence) do
                if k == "exec" then
                    value()
                elseif type(value) == "function" and k ~= "interpolation" and k ~= "duration" then
                    self[k](self, value())
                end
            end
        else
            for k,value in pairs(sequence) do
                if k ~= "interpolation" and k ~= "duration" and k ~= "exec" then
                    if type(value) == "function" then
                        self[k](self, value())
                    elseif type(value) ~= "table" then
                        self[k](self, value)
                    else
                        self[k](self, unpack(value))
                    end
                elseif k == "exec" then
                    value()
                end
            end
        end

        if duration > 0 then
            self:registerEventHandler("tween_complete", function(self, event)
                UIS.AnimateNextSegment(parent, self, event, sequenceData, sequence, sequenceTable, index + 1, repeatCount, extraData)
            end)
        else
            UIS.AnimateNextSegment(parent, self, {}, sequenceData, sequence, sequenceTable, index + 1, repeatCount, extraData)
        end
    end
end

UIS.AnimateSequence = function(self, state, clip, extraData)
    if not self.__sequences or not self.__sequences[state] or not self.__sequences[state][clip] then
        return
    end

    extraData = extraData or {}

    local SequenceData = {
        clipsTotal = #self.__sequences[state][clip],
        clipsRemaining = #self.__sequences[state][clip]
    }

    self:setupElementClipCounter(SequenceData.clipsTotal)
    
    -- Iterate through all ELEMENTS
    for k,v in ipairs(self.__sequences[state][clip]) do
        v.widget:completeAnimation()

        local sequence = v.sequences[1]
		local duration = sequence.duration
		if type(duration) == "function" then
			duration = duration()
		end
        if sequence.repeat_start == true then
            UIS.AnimateNextSegment(self, v.widget, {}, SequenceData, {}, v.sequences, 2, sequence.repeat_count, extraData)
        else
            if duration > 0 then
                error("Bad Sequence code. Script needs a 0 duration initial clip to get start values.")
            end

            for k,value in pairs(sequence) do
                if k ~= "interpolation" and k ~= "duration" and k ~= "exec" then
                    if type(value) == "function" then
                        v.widget[k](v.widget, value())
                    elseif type(value) ~= "table" then
                        v.widget[k](v.widget, value)
                    elseif type(value) == "table" then
                        v.widget[k](v.widget, unpack(value))
                    end
                elseif k == "exec" then
                    value()
                end
            end

            if duration > 0 then
                error("Bad Sequence Code.")
                v.widget:registerEventHandler("tween_complete", function(widget, event)
                    UIS.AnimateNextSegment(self, v.widget, event, SequenceData, sequence, v.sequences, 2, 0, extraData)
                end)
            else
                UIS.AnimateNextSegment(self, v.widget, {}, SequenceData, sequence, v.sequences, 2, 0, extraData)
            end
        end
    end
end

return UIS