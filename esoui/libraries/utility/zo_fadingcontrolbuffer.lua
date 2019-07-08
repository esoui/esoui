FCB_PUSH_DIRECTION_DOWN = 1
FCB_PUSH_DIRECTION_UP = -1

function ZO_FadingControlBuffer_GetEntryControl(entry)
    return entry._control
end

function ZO_FadingControlBuffer_GetHeaderControl(header)
    return header._control
end

function ZO_FadingControlBuffer_GetLineControl(line)
    return line._control
end

ZO_FadingControlBuffer = ZO_Object:Subclass()

--[[ Public API ]]--
function ZO_FadingControlBuffer:New(...)
    local fadingControlBuffer = ZO_Object.New(self)
    fadingControlBuffer:Initialize(...)
    return fadingControlBuffer
end

local HOLD_TIMES = { 6000, 4000, 2000 }

local START_FULLY_OPAQUE = 1
local START_AT_BEGINNING = 2
local START_FADE_IMMEDIATELY = 3

local CONTROL_TYPE_ENTRY = 1
local CONTROL_TYPE_ITEM = 2

-- Note: maxHeight, maxDisplayedEntries, and maxLinesPerEntry can be nil, which means they will be ignored.  maxLinesPerEntry does not include the entry header, if any. 
-- maxHeight can be nil, a number, or a function. If it's nil, it will be ignored. If it's a function, it will be evaluated before being used.
function ZO_FadingControlBuffer:Initialize(control, maxDisplayedEntries, maxHeight, maxLinesPerEntry, fadeAnimationName, translateAnimationName, anchor)
    self.control = control
    self.entryPools = {}
    self.headerPools = {}
    self.linePools = {}
    self.queue = {}
    self.templates = {}
    self.activeEntries = {}
    self.maxDisplayedEntries = maxDisplayedEntries
    self.maxHeight = maxHeight
    self.maxLinesPerEntry = maxLinesPerEntry
    self.fadeAnimationName = fadeAnimationName
    self.translateAnimationName = translateAnimationName
    self.anchor = anchor or ZO_Anchor:New(TOP)
    self.currentNumDisplayedEntries = 0
    self.currentlyMovingEntries = 0
    self.currentlyFadingEntries = 0
    self.translateDuration = 500
    self.holdTimes = HOLD_TIMES
    self.fadesInImmediately = false
    self.additionalVerticalSpacing = 0
    self.pushDirection = FCB_PUSH_DIRECTION_DOWN
    self.holdDisplayingEntries = false
end

function ZO_FadingControlBuffer:SetTranslateDuration(translateDuration)
    self.translateDuration = translateDuration
end

function ZO_FadingControlBuffer:SetHoldTimes(...)
    self.holdTimes = { ... }
end

function ZO_FadingControlBuffer:SetHoldDisplayingEntries(holdEntries)
    self.holdDisplayingEntries = holdEntries

    if(not holdEntries) then
        if(self:HasQueuedEntry() and not self:HasEntries()) then
            self:DisplayNextQueuedEntry()
        end
    end
end

function ZO_FadingControlBuffer:SetAdditionalVerticalSpacing(additionalVerticalSpacing)
    self.additionalVerticalSpacing = additionalVerticalSpacing
end

function ZO_FadingControlBuffer:SetFadesInImmediately(fadesInImmediately)
    self.fadesInImmediately = fadesInImmediately
end

function ZO_FadingControlBuffer:SetPushDirection(pushDirection)
    self.pushDirection = pushDirection
end

function ZO_FadingControlBuffer:SetDisplayOlderEntriesFirst(displayOlderEntriesFirst)
    self.displayOlderEntriesFirst = displayOlderEntriesFirst
end

--[[
    'templateData' must be a table as follows:
        {setup = <function>, equalityCheck = <function>, equalitySetup = <function>, headerTemplateName = <string>, headerSetup = <function>, headerEqualityCheck = <function>})

        where:
            setup = function(control, data)
            equalityCheck = function(oldLines, newLines) -> bool [optional]
            equalitySetup = function(fadingControlBuffer, oldEntry, newEntry) [optional, but required if equalityCheck is specified]
                where:
                    fadingControlBuffer is this class object.
                    oldEntry is the currently active entry.
                    newEntry is the entry that has been deemed equal to oldEntry via the equalityCheck function.
            headerTemplateName [optional, but required if a header is present in an entry]
            headerSetup = function(control, data) [optional, but required if a header is present in an entry]
            headerEqualityCheck = function(fadingControlBuffer, oldHeader, newHeader) [optional]
--]]
function ZO_FadingControlBuffer:AddTemplate(templateName, templateData)
    self.templates[templateName] = templateData
end

function ZO_FadingControlBuffer:HasTemplate(templateName)
    return self.templates[templateName] ~= nil
end

--[[
    An 'entry' can consist of a header and one or more lines (either are optional).
    An 'item' is the term used for either a 'header' or a 'line'.

    'entry' must be a table as follows:
        {header = <table>, lines = <array of tables>}

        where:
            header contains a table that is passed through as 'data' to the headerSetup function.  [optional]
            lines contains an array of tables that are each passed through as 'data' to the setup function. [optional]
--]]
function ZO_FadingControlBuffer:AddEntry(templateName, entry)
    if self.templates[templateName] then
        local templateData = self.templates[templateName]
        entry._templateName = templateName
        if not self:HasQueuedEntry() then
            if not self:TryHandlingExistingEntry(templateName, templateData, entry) then
                if self:CanDisplayEntry(templateName, entry) then
                    self:DisplayEntry(templateName, entry)
                else
                    self:EnqueueEntry(templateName, entry)
                end
            end
        else
            self:EnqueueEntry(templateName, entry)
        end
    end
end

function ZO_FadingControlBuffer:ClearAll()
    ZO_ClearNumericallyIndexedTable(self.queue)

    while #self.activeEntries > 0 do
        local entry = self.activeEntries[#self.activeEntries]
        entry.m_fadeTimeline:Stop()

        self:ReleaseControl(entry)
    end
end

function ZO_FadingControlBuffer:HasEntries()
    return #self.activeEntries > 0
end

function ZO_FadingControlBuffer:FadeAll()
    ZO_ClearNumericallyIndexedTable(self.queue)

    for _, entry in ipairs(self.activeEntries) do
        self:UpdateFadeOutDelayAndPlayFromOffset(entry, START_FADE_IMMEDIATELY)
    end
end

--[[ Private API ]]--
function ZO_FadingControlBuffer:GetEntryIndex(entryControl)
    for i, entry in ipairs(self.activeEntries) do
        if entry == entryControl then
            return i
        end
    end
end

function ZO_FadingControlBuffer:GetLineIndex(entryControl, lineControl)
    for i, entry in ipairs(entryControl.activeLines) do
        if entry == lineControl then
            return i
        end
    end
end

function ZO_FadingControlBuffer:TryHandlingExistingEntry(templateName, templateData, entry)
    if not templateData.equalityCheck then
        return false
    end

    local handled = false
    for _, activeEntryControl in ipairs(self.activeEntries) do
        local activeEntry = activeEntryControl.entry
        if templateName == activeEntry._templateName then
            -- Are both headers equal?
            if activeEntry.header and entry.header and templateData.headerEqualityCheck and templateData.headerEqualityCheck(activeEntry.header, entry.header) then
                if entry.lines then
                    -- Are all lines equal?
                    if activeEntry.lines and templateData.equalityCheck(activeEntry.lines, entry.lines) then
                        templateData.equalitySetup(self, activeEntry, entry)
                        activeEntryControl.setupTime = GetFrameTimeMilliseconds()
                        handled = true
                    else
                        -- The headers are equal, but the lines are not equal. Add the lines to the header if there is space.
                        if self:CanDisplayEntry(templateName, entry, activeEntryControl) then
                            self:AddLinesToExistingEntry(activeEntryControl, entry.lines, templateData.displayOlderLinesFirst)
                            handled = true
                        end
                    end
                end
            -- Headers are either not equal or not present.  Are all lines equal?
            elseif activeEntry.lines and entry.lines and templateData.equalityCheck(activeEntry.lines, entry.lines) then
                templateData.equalitySetup(self, activeEntry, entry)
                handled = true
            end

            if handled then
                -- Reset the fade timer.
                activeEntryControl.m_fadeTimeline:Stop()
                self:UpdateFadeOutDelayAndPlayFromOffset(activeEntryControl, START_FULLY_OPAQUE)
                return true
            end
        end
    end

    return false
end

function ZO_FadingControlBuffer:GetEntryHoldTime(alertEntry)
    local entryIndex = self:GetEntryIndex(alertEntry)
    return self.holdTimes[entryIndex] or self.holdTimes[#self.holdTimes]
end

function ZO_FadingControlBuffer:UpdateFadeOutDelayAndPlayFromOffset(alertEntry, adjustType)
    local fadeTimeline = alertEntry.m_fadeTimeline

    local fadeInAnimation = fadeTimeline:GetAnimation(1)
    local fadeInDelay = fadeTimeline:GetAnimationOffset(fadeInAnimation)
    local initialOffset

    if adjustType == START_FULLY_OPAQUE or adjustType == START_FADE_IMMEDIATELY then
        initialOffset = fadeInAnimation:GetDuration()
    elseif adjustType == START_AT_BEGINNING then
        initialOffset = 0
    end

    local holdTime = initialOffset + fadeInDelay
    if adjustType ~= START_FADE_IMMEDIATELY then
        holdTime = holdTime + self:GetEntryHoldTime(alertEntry)
    end
    fadeTimeline:SetAnimationOffset(fadeTimeline:GetAnimation(2), holdTime)

    if(adjustType == START_FULLY_OPAQUE or adjustType == START_FADE_IMMEDIATELY) then
        -- If a playback offset of > 0 is specified we essentially want to start from the fully faded in state...
        -- That state is defined as however long the duration and delay of the initial animation
        fadeTimeline:PlayFromStart(initialOffset + fadeInDelay)
    else
        fadeTimeline:PlayFromStart()
    end
end

function ZO_FadingControlBuffer:UpdateFadeInDelay(alertEntry, fadeInDelayFactor)
    local fadeAnimation = alertEntry.m_fadeTimeline:GetFirstAnimation()
    local fadeStartDelay = self.translateDuration * fadeInDelayFactor

    alertEntry.m_fadeTimeline:SetAnimationOffset(fadeAnimation, fadeStartDelay)
end

local function ReleaseAllChildren(control)
    local childCount = control:GetNumChildren()
    for i = 1, childCount do
        local child = control:GetChild(i)
        if child.pool then -- Could evaluate to false if the child is not managed by this class.
            child.pool:ReleaseObject(child.key)
        end
    end
end

function ZO_FadingControlBuffer:ReleaseControl(alertControl)
    if alertControl.type == CONTROL_TYPE_ENTRY then
        self.currentNumDisplayedEntries = self.currentNumDisplayedEntries - 1
    end

    ReleaseAllChildren(alertControl)
    alertControl.pool:ReleaseObject(alertControl.key)

    if alertControl.type == CONTROL_TYPE_ENTRY then
        local entryIndex = self:GetEntryIndex(alertControl)
        if entryIndex then
            table.remove(self.activeEntries, entryIndex)
        end
    end

    self:TryCondenseBuffer()
    self:DisplayNextQueuedEntry()
end

function ZO_FadingControlBuffer:CalcHeightOfEntryAfterPrepending(entryControl, newLines)
    local entry = entryControl.entry

    -- Figure out how many lines we are going to end up with.
    local totalLines = #entry.lines + #newLines
    if self.maxLinesPerEntry then
        totalLines = zo_min(totalLines, self.maxLinesPerEntry)
    end
    -- Calculate the height for the given number of lines.
    local height = self:CalcHeightOfEntry(entry._templateName, entry, totalLines)

    return height
end

function ZO_FadingControlBuffer:CalcHeightOfEntry(templateName, entry, maxLines)
    local entryControl = self:AcquireEntryObject(templateName)
    local templateData = self.templates[templateName]

    local offsetY = 0
    local HEADER_ITEM = true
    if entry.header then
        offsetY = self:CalculateItemHeight(templateData.headerTemplateName, self.headerPools, entryControl, offsetY, HEADER_ITEM)
    end

    local lines = entry.lines
    if lines or maxLines then
        local linePools = self.linePools
        local numLines = maxLines or #lines
        for i = 1, numLines do
            offsetY = self:CalculateItemHeight(templateName, linePools, entryControl, offsetY)
        end
    end

    ReleaseAllChildren(entryControl)
    entryControl.pool:ReleaseObject(entryControl.key)

    return offsetY
end

function ZO_FadingControlBuffer:CalcHeightOfActiveEntries()
    local height = 0
    for i = 1, #self.activeEntries do
        height = height + self.activeEntries[i].height
    end
    return height
end

function ZO_FadingControlBuffer:CanDisplayEntry(templateName, entry, prependToEntryControl)
    local notEnoughFreeEntries = false
    if self.maxDisplayedEntries then
        notEnoughFreeEntries = self.currentNumDisplayedEntries >= self.maxDisplayedEntries
    end

    if not prependToEntryControl and notEnoughFreeEntries then
        -- If the FadingControlBuffer does NOT fade in immediately and there isn't space to add a new entry, the new entry will be queued
        if self.fadesInImmediately then
            -- If the FadingControlBuffer DOES fade in immediately but there isn't space to add a new entry, try to kick old entries off to make space
            if not self:TryRemoveLastEntry() then
                -- If space can not be made (all entries are too recent), queue the next entry
                return false
            end
        else
            return false
        end
    end

    local currentHeight = self:CalcHeightOfActiveEntries()
    local additionalHeight
    if prependToEntryControl then
        additionalHeight = self:CalcHeightOfEntryAfterPrepending(prependToEntryControl, entry.lines)
        -- Subtract the height of the control we're prepending to, since the latter will be contained in self.activeEntries.
        currentHeight = currentHeight - prependToEntryControl.height
    else
        additionalHeight = self:CalcHeightOfEntry(templateName, entry)
    end

    local totalHeight = currentHeight + additionalHeight

    local maxHeight = self.maxHeight
    if maxHeight then
        if (type(maxHeight) == "function") then
            maxHeight = maxHeight()
        end 
        if totalHeight > maxHeight then
            return false
        end
    end

    if self.fadesInImmediately then
        return not self.holdDisplayingEntries
    end

    return self.currentlyMovingEntries == 0 and self.currentlyFadingEntries == 0 and not self.holdDisplayingEntries
end

function ZO_FadingControlBuffer:HasQueuedEntry()
    return #self.queue > 0
end

function ZO_FadingControlBuffer:EnqueueEntry(templateName, entry)
    table.insert(self.queue, entry)
end

function ZO_FadingControlBuffer:DisplayNextQueuedEntry()
    while self:HasQueuedEntry() do
        local queuedEntry = self.queue[1]
        local templateName = queuedEntry._templateName
        local templateData = self.templates[templateName]

        local handled = self:TryHandlingExistingEntry(templateName, templateData, queuedEntry)
        if not handled then
            if self:CanDisplayEntry(templateName, queuedEntry) then
                self:DisplayEntry(templateName, queuedEntry)
                handled = true
            end
        end

        if handled then
            table.remove(self.queue, 1)
        end

        if not self.fadesInImmediately or not handled then
            break
        end
    end
end

local function CalculateControlHeight(control)
    local height
    if control.GetTextHeight then
        height = control:GetTextHeight()
        if (height == 0) and control.GetFontHeight then -- Could happen if label control has no text.
            height = control:GetFontHeight()
        end
    else
        height = control:GetHeight()
    end

    return height
end

do
    local function Reset(object)
        object.m_translateTimeline:Stop()
        object.m_fadeTimeline:Stop()
        object:SetAlpha(0)
        object:SetHidden(true)
        object.key = nil

        if object.activeLines then
            ZO_ClearNumericallyIndexedTable(object.activeLines)
        end

        -- This isn't strictly necessary, but it keeps things clean and avoids potentially nasty bugs.
        local entry = object.entry
        if entry then
            entry._control = nil

            if entry.header then
                entry.header._control = nil
            end

            local lines = object.entry.lines
            if lines then
                for i = 1, #lines do
                    lines[i]._control = nil
                end
            end

            object.entry = nil
        end
    end

    local function OnFadeStop(timeline, completedPlayback)
        if completedPlayback then
            local fadingControlBuffer = timeline.m_control.fadingControlBuffer
            fadingControlBuffer:ReleaseControl(timeline.m_control)
        end
    end

    local function OnTranslateStop(timeline)
        local fadingControlBuffer = timeline.m_control.fadingControlBuffer
        fadingControlBuffer.currentlyMovingEntries = fadingControlBuffer.currentlyMovingEntries - 1
    end

    local function OnFadeOutAnimationStart(animation, control)
        local fadingControlBuffer = control.fadingControlBuffer
        fadingControlBuffer.currentlyFadingEntries = fadingControlBuffer.currentlyFadingEntries + 1
    end

    local function OnFadeOutAnimationStop(animation, control)   
        local fadingControlBuffer = control.fadingControlBuffer  
        fadingControlBuffer.currentlyFadingEntries = fadingControlBuffer.currentlyFadingEntries - 1
    end

    local function OnFadeInAnimationStop(animation, control)
        if control.fadeInHold then
            control.m_fadeTimeline:Stop()
            control.fadeInHold = false
        end
    end

    local function SetupControl(control, fadeAnimationName, translateAnimationName)
        local fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(fadeAnimationName, control)
        local translateTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(translateAnimationName, control)

        fadeTimeline.m_control = control
        fadeTimeline:SetHandler("OnStop", OnFadeStop)
        fadeTimeline:GetAnimation(1):SetHandler("OnStop", OnFadeInAnimationStop)
        fadeTimeline:GetAnimation(2):SetHandler("OnPlay", OnFadeOutAnimationStart)
        fadeTimeline:GetAnimation(2):SetHandler("OnStop", OnFadeOutAnimationStop)

        translateTimeline.m_control = control
        translateTimeline:SetHandler("OnStop", OnTranslateStop)

        control.m_fadeTimeline = fadeTimeline
        control.m_translateTimeline = translateTimeline
        return control
    end

    function ZO_FadingControlBuffer:AcquireEntryObject(templateName)
        local pool = self.entryPools[templateName]
        if not pool then
            local function Factory(pool)
                local parent = self.control
                local name = parent:GetName() .. templateName .. "Entry" .. pool:GetNextControlId()
                local control = CreateControl(name, parent, CT_CONTROL)
                control:SetResizeToFitDescendents(true)
                control.pool = pool
                control.activeLines = {}
                control.type = CONTROL_TYPE_ENTRY
                return SetupControl(control, self.fadeAnimationName, self.translateAnimationName)
            end

            pool = ZO_ObjectPool:New(Factory, Reset)
            self.entryPools[templateName] = pool
        end

        local control, key = pool:AcquireObject()
        control:SetHidden(false)
        control.key = key
        control.fadingControlBuffer = self
        ZO_ClearNumericallyIndexedTable(control.activeLines)

        return control
    end

    local function AdjustAnchors(control, newRelativeTo, newOffsetY)
        for i = 0, MAX_ANCHORS - 1 do
            local isValid, point, _, relPoint, offsetX = control:GetAnchor(i)
            if isValid then
                control:SetAnchor(point, newRelativeTo, relPoint, offsetX, control.anchorOffsetY[i] + newOffsetY)
            end
        end
    end

    function ZO_FadingControlBuffer:AcquireItemObject(name, templateName, pools, parent, offsetY)
        local pool = pools[templateName]
        if not pool then
            local function Factory(pool)
                local name = templateName .. name
                local control = ZO_ObjectPool_CreateNamedControl(name, templateName, pool, pool.parent)
                control.pool = pool
                control.type = CONTROL_TYPE_ITEM

                -- Save the anchor Y offsets so we can preserve them when adjusting anchors later.
                control.anchorOffsetY = {nil, nil} -- Pre-allocate space for two anchors.
                for i = 0, MAX_ANCHORS - 1 do
                    local isValid, _, _, _, _, offsetY = control:GetAnchor(i)
                    if isValid then
                        control.anchorOffsetY[i] = offsetY
                    end
                end

                return SetupControl(control, self.fadeAnimationName, self.translateAnimationName)
            end

            pool = ZO_ObjectPool:New(Factory, Reset)
            pools[templateName] = pool
        end

        -- We set the parent before acquiring the object so we can reuse the same factory function across multiple parents.
        -- To keep the item control name simple, it must always be created as a child of an entry control.
        pool.parent = parent
        local control, key = pool:AcquireObject()
        control:SetParent(parent)
        control:SetHidden(false)
        control.key = key
        control.fadingControlBuffer = self

        return control
    end

    function ZO_FadingControlBuffer:CalculateItemHeight(templateName, pools, parent, offsetY, isHeader)
        local control = self:AcquireItemObject(isHeader and "Header" or "Line", templateName, pools, parent, offsetY)
        local height = CalculateControlHeight(control)
        return (offsetY + height)
    end
    
    local HEADER_INDEX = 1
    local PRESERVE_FADE = true
    function ZO_FadingControlBuffer:SetupItem(hasHeader, item, templateName, setupFn, pools, parent, offsetY, isHeader, shouldAppend)
        if item then
            local control = self:AcquireItemObject(isHeader and "Header" or "Line", templateName, pools, parent, offsetY)
            setupFn(control, item)

            local height = CalculateControlHeight(control)
            offsetY = offsetY + height

            item._control = control
            control.height = height
            control.targetBottomY = height
            control.fadeInHold = true
            control:SetAlpha(0)

            local insertionIndex
            if shouldAppend then
                -- append after existing lines
                table.insert(parent.activeLines, control)
            elseif isHeader or not hasHeader then
                -- prepend to header location
                table.insert(parent.activeLines, HEADER_INDEX, control)
            else
                -- insert after header, before existing lines
                table.insert(parent.activeLines, HEADER_INDEX + 1, control)
            end

            AdjustAnchors(control, parent, 0)
            self:MoveEntriesOrLines(parent.activeLines, PRESERVE_FADE)

            local fadeInDelayFactor = .25
            self:UpdateFadeInDelay(control, fadeInDelayFactor)
            self:UpdateFadeOutDelayAndPlayFromOffset(control, START_AT_BEGINNING)
        end

        return offsetY
    end
end

function ZO_FadingControlBuffer:AddLinesToExistingEntry(entryControl, newLines, shouldAppend)
    local entry = entryControl.entry
    local currentLines = entry.lines
    local offsetY = 0

    -- Release lines until we are within our line limit.
    if self.maxLinesPerEntry then
        local numCurrentLines = #currentLines
        local totalLines = numCurrentLines + #newLines

        if totalLines > self.maxLinesPerEntry then
            local numLinesToRemove = zo_min(totalLines - self.maxLinesPerEntry, numCurrentLines)

            -- if appending, remove from the front. If prepending, remove from the back
            local startIndex = shouldAppend and numLinesToRemove or numCurrentLines
            for i = startIndex, startIndex - numLinesToRemove + 1, -1 do
                local line = table.remove(currentLines, i)
                local lineControl = line._control
                offsetY = offsetY - CalculateControlHeight(lineControl)

                local lineIndex = self:GetLineIndex(entryControl, lineControl)
                table.remove(entryControl.activeLines, lineIndex)

                lineControl.fadeInHold = false
                self:UpdateFadeOutDelayAndPlayFromOffset(lineControl, START_FADE_IMMEDIATELY)
            end
        end
    end

    local templateName = entry._templateName
    local templateData = self.templates[templateName]

    local NOT_HEADER = false
    local hasHeader = (entry.header ~= nil)
    local linePools = self.linePools
    if shouldAppend then
        for _, line in ZO_NumericallyIndexedTableIterator(newLines) do
            table.insert(currentLines, line)
            offsetY = self:SetupItem(hasHeader, line, templateName, templateData.setup, linePools, entryControl, offsetY, NOT_HEADER, shouldAppend)
        end
    else
        for _, line in ZO_NumericallyIndexedTableReverseIterator(newLines) do
            table.insert(currentLines, 1, line)
            offsetY = self:SetupItem(hasHeader, line, templateName, templateData.setup, linePools, entryControl, offsetY, NOT_HEADER, shouldAppend)
        end
    end

    entryControl.height = entryControl.height + offsetY
    entryControl.targetBottomY = entryControl.targetBottomY + offsetY
    entryControl.setupTime = GetFrameTimeMilliseconds()

    self:MoveEntriesOrLines(self.activeEntries)
end

do
    local MIN_DISPLAY_TIME_MS = 500

    -- Push the oldest entry off the screen to make room for the new one, even if the old one hasn't timed out
    function ZO_FadingControlBuffer:TryRemoveLastEntry()
        local entries = self.activeEntries
        local currentTime = GetFrameTimeMilliseconds()

        local lastEntryControl = entries[#entries]

        local timeDisplayed = currentTime - lastEntryControl.setupTime
        if timeDisplayed < MIN_DISPLAY_TIME_MS then
            return false
        end

        table.remove(entries, #entries)

        lastEntryControl.fadeInHold = false
        self:UpdateFadeOutDelayAndPlayFromOffset(lastEntryControl, START_FADE_IMMEDIATELY)

        return true
    end
end

function ZO_FadingControlBuffer:DisplayEntry(templateName, entry)
    local entryControl = self:AcquireEntryObject(templateName)
    local templateData = self.templates[templateName]

    -- Call the setup function for the header and each of the lines.
    local offsetY = 0
    local HEADER_ITEM = true
    offsetY = self:SetupItem(HEADER_ITEM, entry.header, templateData.headerTemplateName, templateData.headerSetup, self.headerPools, entryControl, offsetY, HEADER_ITEM)
    local lines = entry.lines
    if lines then
        local NOT_HEADER = false
        local shouldAppend = templateData.displayOlderLinesFirst
        local hasHeader = (entry.header ~= nil)
        local linePools = self.linePools
        local iterator = shouldAppend and ZO_NumericallyIndexedTableIterator or ZO_NumericallyIndexedTableReverseIterator
        for _, line in iterator(lines) do
            offsetY = self:SetupItem(hasHeader, line, templateName, templateData.setup, linePools, entryControl, offsetY, NOT_HEADER, shouldAppend)
        end
    end

    entry._control = entryControl
    entryControl.entry = entry
    entryControl.height = offsetY + self.additionalVerticalSpacing
    entryControl.targetBottomY = entryControl.height
    entryControl.setupTime = GetFrameTimeMilliseconds()

    self.anchor:Set(entryControl)

    entryControl:SetAlpha(0)

    local needsMove = self.activeEntries[1] ~= nil
    if self.displayOlderEntriesFirst then
        -- append new entries to end of list
        table.insert(self.activeEntries, entryControl)
    else
        -- prepend new entries to beginning of list, and move rest of list over
        table.insert(self.activeEntries, 1, entryControl)
    end
    self.currentNumDisplayedEntries = self.currentNumDisplayedEntries + 1

    if needsMove then
        self:MoveEntriesOrLines(self.activeEntries)
    end

    local fadeInDelayFactor = 0
    if self.fadesInImmediately then
        fadeInDelayFactor = .25
    elseif needsMove then
        fadeInDelayFactor = .9
    end
    self:UpdateFadeInDelay(entryControl, fadeInDelayFactor)
    self:UpdateFadeOutDelayAndPlayFromOffset(entryControl, START_AT_BEGINNING)
end

function ZO_FadingControlBuffer:MoveEntriesOrLines(entriesOrLines, preserveFade)
    local targetBottomY = 0

    for i = 1, #entriesOrLines do
        local control = entriesOrLines[i]
        local topY = control.targetBottomY - control.height

        if targetBottomY > topY then
            targetBottomY = self:MoveEntriesOrLinesCalculations(control, targetBottomY, topY, preserveFade)
        else
            targetBottomY = zo_max(targetBottomY, control.targetBottomY)
        end
    end
end

local PRESERVE_FADE = true

function ZO_FadingControlBuffer:TryCondenseBuffer()
    local entriesOrLines = self.activeEntries
    local targetBottomY = 0

    for _, control in ipairs(self.activeEntries) do
        local topY = control.targetBottomY - control.height

        if targetBottomY < topY + self.additionalVerticalSpacing then
             targetBottomY = self:MoveEntriesOrLinesCalculations(control, targetBottomY, topY, PRESERVE_FADE)
        else
            targetBottomY = zo_max(targetBottomY, control.targetBottomY)
        end
    end
end

function ZO_FadingControlBuffer:MoveEntriesOrLinesCalculations(control, targetBottomY, topY, preserveFade)
    local neededY = targetBottomY - topY
    local heightAdjustment = neededY

    targetBottomY = control.targetBottomY + neededY
    control.targetBottomY = targetBottomY

    local translateAnimation = control.m_translateTimeline:GetFirstAnimation()
    if translateAnimation:IsPlaying() then
        local _, existingHeightDelta = translateAnimation:GetTranslateDeltas()
        local easingFunction = translateAnimation:GetEasingFunction()
        local progress = easingFunction and easingFunction(control.m_translateTimeline:GetProgress()) or control.m_translateTimeline:GetProgress()
        heightAdjustment = heightAdjustment + existingHeightDelta * (1.0 - progress) * self.pushDirection
        control.m_translateTimeline:Stop()
    end

    translateAnimation:SetTranslateDeltas(0, heightAdjustment * self.pushDirection)
    translateAnimation:SetDuration(self.translateDuration)
    control.m_translateTimeline:PlayFromStart()
    self.currentlyMovingEntries = self.currentlyMovingEntries + 1

    if not self.fadesInImmediately and not preserveFade then
        control.m_fadeTimeline:Stop()
        control:SetAlpha(1)

        self:UpdateFadeOutDelayAndPlayFromOffset(control, START_FULLY_OPAQUE)
    end

    return targetBottomY
end