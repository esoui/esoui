CreditsScreen_Base = ZO_Object:Subclass()

function CreditsScreen_Base:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function CreditsScreen_Base:Initialize(control)
    self.control = control
    self.pools = {}

    self.currentEntryIndex = nil
    self.numCreditsEntries = 0
    self.scrollParent = control:GetNamedChild("Scroll")

    self:ResetScrollSpeedMultiplier()

    control:SetHandler("OnUpdate", function(control, timeS) self:OnUpdate(timeS) end)
end

function CreditsScreen_Base:SetupTextControl(control, text)
    control:SetText(text)
    return control:GetTextHeight()
end

function CreditsScreen_Base:SetupLogoControl(control, textureFile, height)
    control:SetTexture(textureFile)
    return tonumber(height)
end

function CreditsScreen_Base:SetupBackgroundSwitch(control, textureFile)
    control.textureFile = textureFile
    control:SetTexture(textureFile) -- won't display anything, just loads this image so it's ready to go
    return 0 -- control is invisible, doesn't need a height
end

function CreditsScreen_Base:SetupPaddingSection(control, unused, height)
    return tonumber(height)
end

function CreditsScreen_Base:AddPool(poolType, template, setupCallback)
    self.pools[poolType] =
    {
        pool = ZO_ControlPool:New(template, self.scrollParent),
        setupCallback = setupCallback,
    }
end

function CreditsScreen_Base:AcquireControl(entryType, entryData, additionalData)
    local poolData = self.pools[entryType]
    local control, key = poolData.pool:AcquireObject()
    control.key = key
    control.entryType = entryType
    
    control:ClearAnchors()
    control:SetAnchor(TOP, self.scrollParent, BOTTOM)

    local controlHeight, onExitCallback = poolData.setupCallback(control, entryData, additionalData)
    return controlHeight, control, onExitCallback
end

function CreditsScreen_Base:ReleaseEntry(control)
    local key = control.key
    local entryType = control.entryType
    control.key = nil
    control.entryType = nil

    if entryType then
        self.pools[entryType].pool:ReleaseObject(key)
    end
end

do
    local CREDITS_SCROLL_SPEED = 75 -- UI units per second
    function CreditsScreen_Base:GetScrollSpeed()
        return CREDITS_SCROLL_SPEED * self.scrollSpeedMultiplier
    end
end

function CreditsScreen_Base:SetScrollSpeedMultiplier(speedMultiplier)
    self.scrollSpeedMultiplier = speedMultiplier
    if self.scrollSpeedMultiplier < 0 then
        self.scrollSpeedMultiplier = 0
    end
end

function CreditsScreen_Base:GetScrollSpeedMultiplier()
    return self.scrollSpeedMultiplier
end

function CreditsScreen_Base:ResetScrollSpeedMultiplier()
    self.scrollSpeedMultiplier = 1
end

do
    local finishedControls = {}

    function CreditsScreen_Base:OnUpdate(timeS)
        if self.running then
            if not self.lastUpdateTimeS then
                self.lastUpdateTimeS = timeS
            end

            local timeDifferenceS = timeS - self.lastUpdateTimeS
            self.lastUpdateTimeS = timeS

            self.phase = self.phase + timeDifferenceS * self:GetScrollSpeed()
            local phaseRung = math.floor(self.phase)

            ZO_ClearNumericallyIndexedTable(finishedControls)
            for _, control in ipairs(self.activeControls) do
                local currentDistance = (phaseRung - control.phaseRung)
                control:SetAnchor(TOP, self.scrollParent, BOTTOM, 0, -currentDistance)
                --Use -100 as a buffer so we don't see entries disappearing right on the edge
                if control:GetBottom() < -100 then
                    table.insert(finishedControls, control)
                end
            end
    
            for _, control in ipairs(finishedControls) do
                for searchIndex, searchControl in ipairs(self.activeControls) do
                    if searchControl == control then
                        table.remove(self.activeControls, searchIndex)
                        self:ReleaseEntry(control)
                    end
                end
            end

            while (self.addNextPhaseRung == nil or phaseRung >= self.addNextPhaseRung) and self.currentEntryIndex <= self.numCreditsEntries do
                self:AddNextEntry()
            end

            if self.currentEntryIndex > self.numCreditsEntries and #self.activeControls == 0 then
                self:Exit()
            end
        end
    end
end

do
    local function ClosestUIUnitsOnPixelBoundry(uiUnits)
        local globalScale = GetUIGlobalScale()
        local numPixels = uiUnits * globalScale
        numPixels = zo_round(numPixels)
        return numPixels / globalScale
    end

    function CreditsScreen_Base:AddNextEntry()
        if self.currentEntryIndex <= self.numCreditsEntries then
            local entryType, entryData, additionalData = GetGameCreditsEntry(self.currentEntryIndex)
            local controlHeight, control, onExitCallback = self:AcquireControl(entryType, entryData, additionalData)
            
            --We find the amount UI units closest to the control's height that translates to an integral pixel amount when scaled for rendering. This ensures an integral pixel spacing
            --between all controls and prevent them from rounding over the pixel boundry at different times (jitter)
            controlHeight = ClosestUIUnitsOnPixelBoundry(controlHeight)
        
            local scrollHeight = self.scrollParent:GetHeight()
            local scrollDistance = scrollHeight + controlHeight
        
            control.phaseRung = self.addNextPhaseRung or zo_ceil(self.phase)
            control.onExitCallback = onExitCallback
            table.insert(self.activeControls, control)

            self.addNextPhaseRung = control.phaseRung + controlHeight
            self.currentEntryIndex = self.currentEntryIndex + 1
        end
    end
end

function CreditsScreen_Base:BeginCredits()
    if self:IsPreferredScreen() then
        self.numCreditsEntries = GetNumGameCreditsEntries()
        self.currentEntryIndex = 1
        g_currentDrawLevel = 1
        self.running = true
        self.activeControls = {}
        self.phase = 0
    end
end

function CreditsScreen_Base:StopCredits()
    StopCredits()
    self.running = false
    self.addNextPhaseRung = nil
    for _, control in ipairs(self.activeControls) do
        self:ReleaseEntry(control)
    end
    self:ResetScrollSpeedMultiplier()
    self.lastUpdateTimeS = nil
end