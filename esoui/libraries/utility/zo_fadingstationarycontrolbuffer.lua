ZO_FadingStationaryControlBuffer = ZO_Object:Subclass()

local START_FULLY_OPAQUE = 1
local START_AT_BEGINNING = 2
local START_FADE_IMMEDIATELY = 3

local CONTROL_TYPE_ENTRY = 1
local CONTROL_TYPE_ITEM = 2

local FLUSH_UPDATE_TIME_MS = 200
local FADING_ENTRY_OFFSET_TIME_MS = 67
local DEFAULT_MAX_DISPLAYED_ENTRIES = 4

--[[ Public API ]]--
function ZO_FadingStationaryControlBuffer:New(...)
    local fadingStationaryControlBuffer = ZO_Object.New(self)
    fadingStationaryControlBuffer:Initialize(...)
    return fadingStationaryControlBuffer
end

function ZO_FadingStationaryControlBuffer:Initialize(control, maxDisplayedEntries, fadeAnimationName, iconAnimationName, containerAnimationName, anchor, controllerType)
    self.control = control
    self.entryPools = {}
    self.headerPools = {}
    self.linePools = {}
    self.queue = {}
    self.templates = {}
    self.activeEntries = {}
    self.queuedTimedEntries = {}
    self.maxDisplayedEntries = maxDisplayedEntries or DEFAULT_MAX_DISPLAYED_ENTRIES
    self.maxLinesPerEntry = nil
    self.fadeAnimationName = fadeAnimationName
    self.iconAnimationName = iconAnimationName
    self.anchor = anchor or ZO_Anchor:New(TOP)
    self.currentNumDisplayedEntries = 0
    self.currentlyFadingEntries = 0
    self.queuedBatches = {}
    self.currentEntries = {}
    self.nextTimeToFlushMS = 0
    self.doesContainsEntries = false
    self.containerShowTimeMs = 5000
    self.containerStartTimeMs = 0
    self.emptyDeltaTime = 0
    local offsetY = select(6, self.control:GetAnchor())
    self.resetPositionY = offsetY
    self.controllerType = controllerType
    self.additionalEntrySpacingY = 0
    self.paused = false

    self:InitializeContainerAnimations(containerAnimationName)

    EVENT_MANAGER:RegisterForUpdate(string.format("%s%s", "ZO_FadingStationaryControlBuffer", controllerType), 30, function(...) self:OnUpdateBuffer(...) end)
end

function ZO_FadingStationaryControlBuffer:OnUpdateBuffer(timeMs)
    if self.paused then
        return
    end

    if timeMs > self.nextTimeToFlushMS then
        self:FlushEntries()
        self.nextTimeToFlushMS = timeMs + FLUSH_UPDATE_TIME_MS
    end

    if self.doesContainsEntries then
        local deltaContainerTime = timeMs - self.containerStartTimeMs
        if deltaContainerTime > self.containerShowTimeMs then
            self.doesContainsEntries = false
            self.fadeTimeline:PlayFromStart()
        end
    end

    local numQueuedTimedEntries = #self.queuedTimedEntries
    for i = numQueuedTimedEntries, 1, -1 do
        if self.queuedTimedEntries[i].fadeStartDelayMs < timeMs then
            self.queuedTimedEntries[i].control.fadeIconTimeline:PlayFromStart()
            table.remove(self.queuedTimedEntries, i)
        end
    end
end

function ZO_FadingStationaryControlBuffer:Pause()
    if not self.paused then
        self.paused = true
        self.pauseTimeMS = GetFrameTimeMilliseconds()
    end
end

function ZO_FadingStationaryControlBuffer:Resume()
    if self.paused then
        self.paused = false
        local timePausedMS = GetFrameTimeMilliseconds() - self.pauseTimeMS
        self.pauseTimeMS = nil

        if self.containerStartTimeMs ~= 0 then
            self.containerStartTimeMs = self.containerStartTimeMs + timePausedMS
        end

        for i, queuedTimedEntry in ipairs(self.queuedTimedEntries) do
            queuedTimedEntry.fadeStartDelayMs = queuedTimedEntry.fadeStartDelayMs + timePausedMS
        end
    end
end

function ZO_FadingStationaryControlBuffer:AddEntry(templateName, entry)
    if self.templates[templateName] then
        entry.templateName = templateName
        table.insert(self.queue, entry)
    end
end

function ZO_FadingStationaryControlBuffer:SetContainerShowTime(time)
    self.containerShowTimeMs = time
end

function ZO_FadingStationaryControlBuffer:AddTemplate(templateName, templateData)
    assert(templateData.equalityCheck)
    self.templates[templateName] = templateData
end

function ZO_FadingStationaryControlBuffer:SetAdditionalEntrySpacingY(additionalSpacingY)
    self.additionalEntrySpacingY = additionalSpacingY
end

--[[ Private API ]]--
    
function ZO_FadingStationaryControlBuffer:GetActiveEntryIndex(entryControl)
    for i, entry in ipairs(self.activeEntries) do
        if entry == entryControl then
            return i
        end
    end
end

do
    local function OnContainerFadeStop(timeline)
        --fadeout anim is complete, go back to the ready state
        local isValid, point, relTo, relPoint = timeline.control:GetAnchor()
        timeline.control:SetAnchor(point, relTo, relPoint, 0, timeline.controlBuffer.resetPositionY)
        timeline.controlBuffer:ReleaseAllControls()
        timeline.controlBuffer:RefreshBatchAfterRelease()
    end

    function ZO_FadingStationaryControlBuffer:InitializeContainerAnimations(containerAnimationName)

        local control = self.control
        self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(containerAnimationName, control)

        self.fadeTimeline.controlBuffer = self

        self.fadeTimeline:Stop()

        self.fadeTimeline.control = control
        self.fadeTimeline:SetHandler("OnStop", OnContainerFadeStop)

        control.fadeTimeline = self.fadeTimeline
    end
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

function ZO_FadingStationaryControlBuffer:ReleaseAllControls()
    while #self.activeEntries > 0 do
        self:ReleaseControl(self.activeEntries[1])
    end
end

function ZO_FadingStationaryControlBuffer:RefreshBatchAfterRelease()
    if self.currentNumDisplayedEntries == 0 then
        self.lastAnchoredEntry = nil
        self:DisplayBatches()
    end
end

function ZO_FadingStationaryControlBuffer:RefreshBatchAfterFading()
    -- incase we are displaying a large batch of items and collect an extra one while the animation is playing
    -- we want to wait for the current animation to finish before moving onto the next set
    -- which we call here
    if  self.currentlyFadingEntries <= 0 then
        self:DisplayBatches()
    end
end

function ZO_FadingStationaryControlBuffer:ReleaseControl(alertControl)
    if alertControl.type == CONTROL_TYPE_ENTRY then
        self.currentNumDisplayedEntries = self.currentNumDisplayedEntries - 1
    end

    ReleaseAllChildren(alertControl)
    alertControl.pool:ReleaseObject(alertControl.key)

    if alertControl.type == CONTROL_TYPE_ENTRY then
        local entryIndex = self:GetActiveEntryIndex(alertControl)
        if entryIndex then
            table.remove(self.activeEntries, entryIndex)
        end
    end
end

function ZO_FadingStationaryControlBuffer:TryConcatWithExistingEntry(templateName, entry, tableLocation)
    local templateData = self.templates[templateName]

    local tableLocation = tableLocation or self.activeEntries
    local handled = false
    for _, activeEntryControl in ipairs(tableLocation) do
        local activeEntry = activeEntryControl.entry
        if templateName == activeEntry.templateName then
            -- Are both headers equal?
            if activeEntry.header and entry.header and templateData.headerEqualityCheck and templateData.headerEqualityCheck(activeEntry.header, entry.header) then
                if entry.lines then
                    -- Are all lines equal?
                    if activeEntry.lines and templateData.equalityCheck(activeEntry.lines, entry.lines) then
                        templateData.equalitySetup(self, activeEntry, entry)
                        activeEntryControl.setupTime = GetFrameTimeMilliseconds()
                        handled = true
                    end
                end
            -- Headers are either not equal or not present.  Are all lines equal?
            elseif activeEntry.lines and entry.lines and templateData.equalityCheck(activeEntry.lines, entry.lines) then
                templateData.equalitySetup(self, activeEntry, entry)
                handled = true
            end

            if handled then
                break
            end
        end
    end

    return handled
end

function ZO_FadingStationaryControlBuffer:CanDisplayMore()
    if self.fadeTimeline:IsPlaying() then
        return false
    end

    if self.doesContainsEntries and self.currentlyFadingEntries > 0 then
        return false
    end
    
    return self:CanDisplayEntry()
end

-- supplimental check for adding entries from a batch
-- we already know they are ok to go, but now we need to make sure we don't over add items
function ZO_FadingStationaryControlBuffer:CanDisplayEntry()
    return self.currentNumDisplayedEntries < self.maxDisplayedEntries
end

function ZO_FadingStationaryControlBuffer:FadeAll()
    ZO_ClearNumericallyIndexedTable(self.queue)
end

do
    local function Reset(object)
        if object.fadeLabelAndBgTimeline then
            object.fadeLabelAndBgTimeline:Stop()
        end
        if object.fadeIconTimeline then
            object.fadeIconTimeline:Stop()
        end
        object:SetHidden(true)
        object.key = nil

        if object.activeLines then
            ZO_ClearNumericallyIndexedTable(object.activeLines)
        end

        -- This isn't strictly necessary, but it keeps things clean and avoids potentially nasty bugs.
         local entry = object.entry 
         if entry then 
             entry.control = nil 
    
             if entry.header then 
                 entry.header.control = nil 
             end 
    
             local lines = object.entry.lines 
             if lines then 
                 for _, line in ipairs(lines) do
                    line.control = nil
                 end
             end
    
             object.entry = nil  
         end
    end

    local function OnLabelFadeStop(timeline, completedPlayback)
        if completedPlayback then
            local fadingControlBuffer = timeline.control.fadingControlBuffer
            fadingControlBuffer.currentlyFadingEntries = fadingControlBuffer.currentlyFadingEntries - 1
            fadingControlBuffer:RefreshBatchAfterFading() 
        end
    end

    local function OnIconFadeStop(timeline, completedPlayback)
        if completedPlayback then
            local fadingControlBuffer = timeline.control.fadingControlBuffer
            timeline.control.fadeLabelAndBgTimeline:PlayFromStart()
        end
    end

    local function InitializeItemControl(control, fadeAnimationName, iconAnimationName)
        control.icon = control:GetNamedChild("Icon")
        control.label = control:GetNamedChild("Label")
        control.bg = control:GetNamedChild("Bg")

        local fadeLabelAndBgTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(fadeAnimationName)
        fadeLabelAndBgTimeline:GetAnimation(1):SetAnimatedControl(control.bg)
        fadeLabelAndBgTimeline:GetAnimation(2):SetAnimatedControl(control.label)
        local fadeIconTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual(iconAnimationName, control.icon)

        fadeLabelAndBgTimeline.control = control
        fadeIconTimeline.control = control
        fadeLabelAndBgTimeline:SetHandler("OnStop", OnLabelFadeStop)
        fadeIconTimeline:SetHandler("OnStop", OnIconFadeStop)

        control.fadeLabelAndBgTimeline = fadeLabelAndBgTimeline
        control.fadeIconTimeline = fadeIconTimeline

        fadeIconTimeline:Stop()
        fadeLabelAndBgTimeline:Stop()

        return control
    end

    function ZO_FadingStationaryControlBuffer:AcquireEntryObject(templateName)
        local pool = self.entryPools[templateName]
        if not pool then
            local function Factory(pool)
                local parent = self.control
                local name = string.format("%s%s%s%d", parent:GetName(), templateName, self.controllerType, pool:GetNextControlId())
                local control = CreateControl(name, parent, CT_CONTROL)
                control:SetResizeToFitDescendents(true)
                control.pool = pool
                control.activeLines = {}
                control.type = CONTROL_TYPE_ENTRY
                return control
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

    function ZO_FadingStationaryControlBuffer:AcquireItemObject(name, templateName, pools, parent, offsetY)
        local pool = pools[templateName]
        if not pool then
            local function Factory(pool)
                local name = string.format("%s%s%s", templateName, name, self.controllerType)
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

                return InitializeItemControl(control, self.fadeAnimationName, self.iconAnimationName)
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

    local HEADER_INDEX = 1
    local PRESERVE_FADE = true
    function ZO_FadingStationaryControlBuffer:SetupItem(hasHeader, item, templateName, setupFn, pools, parent, offsetY, isHeader)
        if item then
            local control = self:AcquireItemObject(isHeader and "Header" or "Line", templateName, pools, parent, offsetY)
            setupFn(control, item)

            item.control = control
            control.fadeInHold = true

            local insertionIndex = HEADER_INDEX + 1
            if isHeader or not hasHeader then
                insertionIndex = HEADER_INDEX
            end

            table.insert(parent.activeLines, insertionIndex, control)
        end

        return offsetY
    end
end

function ZO_FadingStationaryControlBuffer:UpdateFadeInDelay(entryControl, fadeInDelayFactor)
    table.insert(self.queuedTimedEntries, {
                                            control = entryControl, 
                                            fadeStartDelayMs = fadeInDelayFactor + GetFrameTimeMilliseconds()
                                          }
                ) 
end

function ZO_FadingStationaryControlBuffer:DisplayEntry(templateName, entry, entryNumber, hasCurrentEntries)
    local entryControl = self:AcquireEntryObject(templateName)
    local templateData = self.templates[templateName]

    -- Call the setup function for the header and each of the lines.
    local offsetY = 0
    local HEADER_ITEM = true
    offsetY = self:SetupItem(HEADER_ITEM, entry.header, templateData.headerTemplateName, templateData.headerSetup, self.headerPools, entryControl, offsetY, HEADER_ITEM)
    local lines = entry.lines
    if lines then
        local hasHeader = (entry.header ~= nil)
        local linePools = self.linePools
        for i = #lines, 1, -1 do
            offsetY = self:SetupItem(hasHeader, lines[i], templateName, templateData.setup, linePools, entryControl, offsetY)
        end
    end

    entry.control = entryControl
    entryControl.entry = entry
    entryControl.setupTimeMS = GetFrameTimeMilliseconds()

    self.anchor:Set(entryControl)

    if hasCurrentEntries then
        if entryNumber == 0 then
            entryControl:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, 0, 0)
            self.bottomEntry:SetAnchor(BOTTOMRIGHT, entryControl, TOPRIGHT, 0, self.additionalEntrySpacingY)
        else
            entryControl:SetAnchor(BOTTOMRIGHT, self.lastAnchoredEntry, TOPRIGHT, 0, self.additionalEntrySpacingY)
            self.bottomEntry:SetAnchor(BOTTOMRIGHT, entryControl, TOPRIGHT, 0, self.additionalEntrySpacingY)
        end
    else
        if not self.lastAnchoredEntry then
            entryControl:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, 0, 0)
        else
            entryControl:SetAnchor(BOTTOMRIGHT, self.lastAnchoredEntry, TOPRIGHT, 0, self.additionalEntrySpacingY)
        end
    end

    table.insert(self.activeEntries, 1, entryControl)
    self.currentNumDisplayedEntries = self.currentNumDisplayedEntries + 1
    self.currentlyFadingEntries = self.currentlyFadingEntries + 1
    local subControl = entryControl:GetChild(1)
    local FADE_IN_DELAY_FACTOR = entryNumber * FADING_ENTRY_OFFSET_TIME_MS
    self:UpdateFadeInDelay(subControl, FADE_IN_DELAY_FACTOR)
    subControl.label:SetAlpha(0)
    subControl.bg:SetAlpha(0)
    subControl.icon:SetAlpha(0)
    subControl.icon:SetScale(2)
    
    self.lastAnchoredEntry = entryControl

    return entryControl
end

function ZO_FadingStationaryControlBuffer:FlushEntries()
    local hadEntries = false
    local newBatch = {}
    while #self.queue > 0 do
        local queuedEntry = self.queue[1]
        local templateName = queuedEntry.templateName
        local persistent = queuedEntry.isPersistent

        local persistHandled = false
        if persistent then
            persistHandled = self:TryConcatWithExistingEntry(templateName, queuedEntry, self.activeEntries)
        end

        if not persistHandled then
            local handled = self:TryConcatWithExistingEntry(templateName, queuedEntry, newBatch)
            if not handled then
                self:AddToBatch(templateName, queuedEntry, newBatch)
                handled = true
                hadEntries = true
            end
        else
            self.containerStartTimeMs = GetFrameTimeMilliseconds()
        end

        table.remove(self.queue, 1)
    end

    if hadEntries then
        newBatch.iterator = #newBatch
        table.insert(self.queuedBatches, newBatch)
        self:DisplayBatches()
    end

end

function ZO_FadingStationaryControlBuffer:AddToBatch(templateName, queuedEntry, batch)
    local batchData = { 
                        batch = batch,
                        templateName = templateName,
                        entry = queuedEntry, 
                       }

    table.insert(batch, 1, batchData)
end

function ZO_FadingStationaryControlBuffer:DisplayBatches()
    local noMoreEntries = false
    local displayItems = 0
    local hasCurrentEntries = self.currentNumDisplayedEntries > 0
    local latestBottomEntry = nil
    while self:CanDisplayMore() do
        local currentBatch = self.queuedBatches[1]
        if currentBatch == nil then
            break
        end
        for i = currentBatch.iterator, 1, -1 do
            if self:CanDisplayEntry() then
                local control = self:DisplayEntry(currentBatch[i].templateName, currentBatch[i].entry, displayItems, hasCurrentEntries)
                if displayItems == 0 then
                    latestBottomEntry = control
                end
                displayItems = displayItems + 1
            else
                noMoreEntries = true
                currentBatch.iterator = i
                break
            end
        end

        if noMoreEntries then
            break
        else
            table.remove(self.queuedBatches, 1)
            currentBatch = nil
        end
    end

    if displayItems > 0 then
        if latestBottomEntry then
            self.bottomEntry = latestBottomEntry
        end
        self.control:SetAlpha(1)
        self.containerStartTimeMs = GetFrameTimeMilliseconds()
        self.doesContainsEntries = true
    end
end