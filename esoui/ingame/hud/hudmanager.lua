--TODO Custom HUD: Determine if we want to move this somewhere else
ZO_HUD_EDITOR_OPTION_TYPES =
{
    BOOLEAN = 1,
    MULTI_SELECT_DROPDOWN = 2,
    ENUM = 3,
}

ZO_HUD_EDITOR_ELEMENT_DRAW_LEVELS =
{
    DEFAULT = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    --SELECTED should always be the highest value, and should not be used outside of the editor code itself
    SELECTED = 4,
}

-----------------------------
-- ZO_HUDManager_Element
-----------------------------

ZO_HUDManager_Element = ZO_InitializingCallbackObject:Subclass()

function ZO_HUDManager_Element:Initialize(control, displayName, config, options)
    self.config = config or {}
    local defaultAnchor = self.config.defaultAnchor
    if not defaultAnchor then
        local primaryAnchorIsValid, primaryAnchorPoint, relativeTo, relativeAnchorPoint, offsetX, offsetY = control:GetAnchor(0)
        --The control must have a primary anchor
        assert(primaryAnchorIsValid)
        defaultAnchor = ZO_Anchor:New(primaryAnchorPoint, relativeTo, relativeAnchorPoint, offsetX, offsetY)
    end

    --The control must NOT have a secondary anchor
    local secondaryAnchorIsValid = control:GetAnchor(1)
    assert(not secondaryAnchorIsValid)

    self.control = control
    self.displayName = displayName
    self.options = options or {}
    self.saveKey = control:GetName()

    local primaryAnchorPoint, relativeTo, _, offsetX, offsetY = defaultAnchor:Get()
    self.defaultAnchor = defaultAnchor
    self.workingAnchor = ZO_Anchor:New(primaryAnchorPoint, GuiRoot, primaryAnchorPoint)
    self.savedAnchor = ZO_Anchor:New(primaryAnchorPoint, GuiRoot, primaryAnchorPoint)
    self.currentAnchor = self.defaultAnchor
    self.primaryAnchorPoint = primaryAnchorPoint
    self.defaultRelativeTo = relativeTo
    self.defaultOffsetX = offsetX
    self.defaultOffsetY = offsetY
end

function ZO_HUDManager_Element:GetControl()
    return self.control
end

function ZO_HUDManager_Element:GetDisplayName()
    return ZO_Eval(self.displayName)
end

function ZO_HUDManager_Element:GetSaveKey()
    return self.saveKey
end

function ZO_HUDManager_Element:IsValid()
    return ZO_EvalDefaultTrue(self.config.isValid, self)
end

function ZO_HUDManager_Element:GetDrawLevel()
    return self.config.overrideDrawLevel or ZO_HUD_EDITOR_ELEMENT_DRAW_LEVELS.DEFAULT
end

function ZO_HUDManager_Element:GetCurrentAnchor()
    return self.currentAnchor
end

function ZO_HUDManager_Element:GetWorkingAnchor()
    return self.workingAnchor
end

function ZO_HUDManager_Element:GetSavedAnchor()
    --TODO Custom HUD: Remove this check once we build the gamepad editor
    if ZO_IsConsoleOrGameCoreUI() then
        return self.defaultAnchor
    end

    local offsetX, offsetY = HUD_MANAGER:GetSavedAnchorOffsets(self)
    if offsetX then
        self.savedAnchor:SetOffsets(offsetX, offsetY)
        return self.savedAnchor
    end
    return self.defaultAnchor
end

function ZO_HUDManager_Element:IsUsingDefaultAnchor()
    return self.currentAnchor == self.defaultAnchor
end

function ZO_HUDManager_Element:GetHUDRefElement()
    return self.control.hudElementRef
end

function ZO_HUDManager_Element:GetConvertedRefControlAnchorInfo()
    --Converts the current rect for the control into a position relative to GuiRoot using its primary anchor point
    --For example, a TOPRIGHT primary anchor will give offsets from GuiRoot's TOPRIGHT
    local hudElementRef = self.control.hudElementRef
    local refOffsetX, refOffsetY = ZO_GetControlPointOffsetFromGuiRoot(hudElementRef, self.primaryAnchorPoint)
    local refWidth, refHeight = hudElementRef:GetDimensions()
    return self.primaryAnchorPoint, refOffsetX, refOffsetY, refWidth, refHeight
end

do
    --Given the desired offset from the displayed element box, determine the offsets that are needed to be applied to the actual control
    local function DefaultRefOffsetToPrimaryOffsetFunc(control, refOffsetX, refOffsetY)
        local _, primaryAnchorPoint = control:GetAnchor(0)
        local hudElementRef = control.hudElementRef
        local primaryAnchorControlCenterX, primaryAnchorControlCenterY = control:GetCenter()
        local refCenterX, refCenterY = hudElementRef:GetCenter()
        
        local primaryOffsetX
        if primaryAnchorPoint == TOPLEFT or primaryAnchorPoint == LEFT or primaryAnchorPoint == BOTTOMLEFT then
            primaryOffsetX = refOffsetX + control:GetLeft() - hudElementRef:GetLeft()
        elseif primaryAnchorPoint == TOP or primaryAnchorPoint == CENTER or primaryAnchorPoint == BOTTOM then
            primaryOffsetX = refOffsetX + (primaryAnchorControlCenterX - refCenterX)
        else
            primaryOffsetX = refOffsetX + control:GetRight() - hudElementRef:GetRight()
        end

        local primaryOffsetY
        if primaryAnchorPoint == TOPLEFT or primaryAnchorPoint == TOP or primaryAnchorPoint == TOPRIGHT then
            primaryOffsetY = refOffsetY + control:GetTop() - hudElementRef:GetTop()
        elseif primaryAnchorPoint == LEFT or primaryAnchorPoint == CENTER or primaryAnchorPoint == RIGHT then
            primaryOffsetY = refOffsetY + primaryAnchorControlCenterY - refCenterY
        else
            primaryOffsetY = refOffsetY + control:GetBottom() - hudElementRef:GetBottom()
        end

        return primaryOffsetX, primaryOffsetY
    end

    function ZO_HUDManager_Element:ApplyOffset(refOffsetX, refOffsetY, autoSave)
        local refOffsetToPrimaryOffsetFunc = self.config.RefOffsetToPrimaryOffsetFunc or DefaultRefOffsetToPrimaryOffsetFunc
        local primaryOffsetX, primaryOffsetY = refOffsetToPrimaryOffsetFunc(self.control, refOffsetX, refOffsetY)
        self.workingAnchor:SetOffsets(primaryOffsetX, primaryOffsetY)
        self.workingAnchor:Set(self.control)
        self.currentAnchor = self.workingAnchor
        -- TODO Custom HUD: Don't default to true when we have profiles
        if autoSave ~= false then
            self:SaveOffsets()
        end
    end
end

function ZO_HUDManager_Element:SaveOffsets()
    local currentAnchor = self:GetCurrentAnchor()
    local savedAnchor = self:GetSavedAnchor()
    if currentAnchor ~= savedAnchor then
        if currentAnchor == self.defaultAnchor then
            HUD_MANAGER:SaveAnchorOffsets(self)
            self.currentAnchor = self.defaultAnchor
        else
            HUD_MANAGER:SaveAnchorOffsets(self, currentAnchor:GetOffsets())
            -- Re-process what we consider to be the "saved anchor"
            self.currentAnchor = self:GetSavedAnchor()
        end
    end
end

function ZO_HUDManager_Element:ResetToDefaultAnchor(autoSave)
    self.defaultAnchor:Set(self.control)
    self.currentAnchor = self.defaultAnchor

    -- TODO Custom HUD: Don't default to true when we have profiles
    if autoSave ~= false then
        self:SaveOffsets()
    end

    local rebuild = false
    for _, option in ipairs(self.options) do
        if option.resetToDefaultAnchorCallback and option.resetToDefaultAnchorCallback(self) then
            rebuild = true
        end
    end

    if rebuild then
        HUD_MANAGER:RebuildAllElements()
    end
end

function ZO_HUDManager_Element:RevertOffsetModifications()
    local savedAnchor = self:GetSavedAnchor()
    savedAnchor:Set(self.control)
    self.currentAnchor = savedAnchor
end

function ZO_HUDManager_Element:GetCustomOptions()
    return self.options
end

function ZO_HUDManager_Element:GetCustomOption(key)
    for _, option in ipairs(self.options) do
        if option.key == key then
            return option
        end
    end
    return nil
end

function ZO_HUDManager_Element:SetCustomOptionValue(key, subKey, value, suppressCallbacks)
    local option = self:GetCustomOption(key)
    if option then
        local oldValue = self:GetCustomOptionValue(key, subKey)
        if oldValue ~= value then
            if not option.dontSave then
                local valueToSave = value
                if subKey and type(option.defaultValue) == "table" then
                    if valueToSave == option.defaultValue[subKey] then
                        valueToSave = nil
                    end
                elseif valueToSave == ZO_Eval(option.defaultValue) then
                    valueToSave = nil
                end

                HUD_MANAGER:SaveCustomOptionValue(self, key, subKey, valueToSave)
            end

            if not suppressCallbacks then
                option.callback(self, subKey, oldValue, value)
            end
        end
    end
end

function ZO_HUDManager_Element:GetCustomOptionValue(key, subKey)
    local option = self:GetCustomOption(key)
    if option and ZO_EvalDefaultTrue(option.isValid, self) then
        local savedValue = HUD_MANAGER:GetSavedCustomOptionValue(self, key, subKey)
        if savedValue == nil then
            local defaultValue = option.defaultValue
            if subKey and type(defaultValue) == "table" then
                savedValue = defaultValue[subKey]
            else
                savedValue = ZO_Eval(defaultValue)
            end
        end
        return savedValue
    end
    return nil
end

ZO_HUDManager_Element:MUST_IMPLEMENT("IsKeyboard")
ZO_HUDManager_Element:MUST_IMPLEMENT("IsGamepad")

---------------------------------
-- ZO_HUDManager_KeyboardElement
---------------------------------

ZO_HUDManager_KeyboardElement = ZO_HUDManager_Element:Subclass()

function ZO_HUDManager_KeyboardElement:IsKeyboard()
    return true
end

function ZO_HUDManager_KeyboardElement:IsGamepad()
    return false
end

---------------------------------
-- ZO_HUDManager_GamepadElement
---------------------------------

ZO_HUDManager_GamepadElement = ZO_HUDManager_Element:Subclass()

function ZO_HUDManager_GamepadElement:IsKeyboard()
    return false
end

function ZO_HUDManager_GamepadElement:IsGamepad()
    return true
end

-------------------
-- ZO_HUDManager
-------------------

local PRIMARY_PROFILE_INDEX = 1

ZO_HUDManager =  ZO_InitializingCallbackObject:Subclass()

function ZO_HUDManager:Initialize()
    self:SetupSavedVars()

    self.keyboardElements = {}
    self.gamepadElements = {}
end

function ZO_HUDManager:SetupSavedVars()
    local function OnAddOnsLoaded(_, name)
        self:FireCallbacks("PreLoadSettings")

        local DEFAULTS =
        {
            profiles =
            {
                {
                    keyboardElements = {},
                    gamepadElements = {},
                },
            },
        }
        self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 1, "ZO_HUDManager", DEFAULTS)
        self:PropagateSettings()
        self:FireCallbacks("SavedVarsReady")

        EVENT_MANAGER:RegisterForEvent("ZO_HUDManager", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function() self:PropagateSettings() end)
        EVENT_MANAGER:RegisterForEvent("ZO_HUDManager", EVENT_SCREEN_RESIZED, function() self:PropagateSettings() end)
    end
    EVENT_MANAGER:RegisterForEvent("ZO_HUDManager", EVENT_ADD_ONS_LOADED, OnAddOnsLoaded)
end

function ZO_HUDManager:RegisterKeyboardElement(control, displayName, config, options)
    local element = ZO_HUDManager_KeyboardElement:New(control, displayName, config, options)
    self.keyboardElements[control] = element
    return element
end

function ZO_HUDManager:RegisterGamepadElement(control, displayName, config, options)
    local element = ZO_HUDManager_GamepadElement:New(control, displayName, config, options)
    self.gamepadElements[control] = element
    return element
end

function ZO_HUDManager:KeyboardElementIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.keyboardElements, filterFunctions)
end

function ZO_HUDManager:GamepadElementIterator(filterFunctions)
    return ZO_FilteredNonContiguousTableIterator(self.gamepadElements, filterFunctions)
end

function ZO_HUDManager:GetKeyboardElementForControl(control)
    for _, element in pairs(self.keyboardElements) do
        if element.control == control then
            return element
        end
    end
    return nil
end

function ZO_HUDManager:GetGamepadElementForControl(control)
    for _, element in pairs(self.gamepadElements) do
        if element.control == control then
            return element
        end
    end
end

function ZO_HUDManager:PropagateSettings()
    if IsInGamepadPreferredMode() then
        for _, element in self:GamepadElementIterator() do
            element:RevertOffsetModifications()
        end
    else
        for _, element in self:KeyboardElementIterator() do
            element:RevertOffsetModifications()
        end
    end
    self:FireCallbacks("PropagateSettings")
end

function ZO_HUDManager:RebuildAllElements()
    self:FireCallbacks("RebuildAllElements")
end

function ZO_HUDManager:GetSavedProfile(profileIndex)
    if self.savedVars then
        return self.savedVars.profiles[profileIndex]
    end
    return nil
end

function ZO_HUDManager:GetSavedAnchorOffsets(element)
    local profile = self:GetSavedProfile(PRIMARY_PROFILE_INDEX)
    if profile then
        local savedElementsTable = element:IsKeyboard() and profile.keyboardElements or profile.gamepadElements
        local saveKey = element:GetSaveKey()
        local savedElementInfo = savedElementsTable[saveKey]
        if savedElementInfo and savedElementInfo.offsetX and savedElementInfo.offsetY then
            local guiRootWidth, guiRootHeight = GuiRoot:GetDimensions()
            --Saved vars are normalized, so apply the size of GuiRoot to the offsets
            local offsetPercentX, offsetPercentY = savedElementInfo.offsetX, savedElementInfo.offsetY
            return guiRootWidth * offsetPercentX, guiRootHeight * offsetPercentY
        end
    end
    return nil, nil
end

function ZO_HUDManager:SaveAnchorOffsets(element, offsetX, offsetY)
    local profile = self:GetSavedProfile(PRIMARY_PROFILE_INDEX)
    assert(profile)
    local savedElementsTable = element:IsKeyboard() and profile.keyboardElements or profile.gamepadElements
    local saveKey = element:GetSaveKey()
    local savedElementInfo = savedElementsTable[saveKey]
    if offsetX then
        if not savedElementInfo then
            savedElementInfo = {}
            savedElementsTable[saveKey] = savedElementInfo
        end
        local guiRootWidth, guiRootHeight = GuiRoot:GetDimensions()
        --Normalize the offsets to account for screen size changing
        local PRECISION = 0.00001
        savedElementInfo.offsetX = zo_roundToNearest(offsetX / guiRootWidth, PRECISION)
        savedElementInfo.offsetY = zo_roundToNearest(offsetY / guiRootHeight, PRECISION)
    elseif savedElementInfo then
        savedElementInfo.offsetX = nil
        savedElementInfo.offsetY = nil
        if ZO_IsTableEmpty(savedElementInfo) then
            savedElementsTable[saveKey] = nil
        end
    end

    self:FireCallbacks("OffsetsChanged", element)
end

function ZO_HUDManager:GetSavedCustomOptionValue(element, optionKey, optionSubKey)
    local profile = self:GetSavedProfile(PRIMARY_PROFILE_INDEX)
    if profile then
        local savedElementsTable = element:IsKeyboard() and profile.keyboardElements or profile.gamepadElements
        local saveKey = element:GetSaveKey()
        local savedElementInfo = savedElementsTable[saveKey]
        if savedElementInfo then
            local savedValue = savedElementInfo[optionKey]
            if savedValue and optionSubKey then
                savedValue = savedValue[optionSubKey]
            end
            return savedValue
        end
    end
    return nil
end

function ZO_HUDManager:SaveCustomOptionValue(element, optionKey, optionSubKey, value)
    local profile = self:GetSavedProfile(PRIMARY_PROFILE_INDEX)
    assert(profile)
    local savedElementsTable = element:IsKeyboard() and profile.keyboardElements or profile.gamepadElements
    local saveKey = element:GetSaveKey()
    local savedElementInfo = savedElementsTable[saveKey]
    if value ~= nil then
        if not savedElementInfo then
            savedElementInfo = {}
            savedElementsTable[saveKey] = savedElementInfo
        end

        if optionSubKey then
            local savedKeyValue = savedElementInfo[optionKey]
            if not savedKeyValue then
                savedKeyValue = {}
                savedElementInfo[optionKey] = savedKeyValue
            end
            savedKeyValue[optionSubKey] = value
        else
            savedElementInfo[optionKey] = value
        end
    elseif savedElementInfo then
        local savedKeyValue = savedElementInfo[optionKey]
        if savedKeyValue ~= nil then
            if optionSubKey then
                savedKeyValue[optionSubKey] = nil
                if ZO_IsTableEmpty(savedKeyValue) then
                    savedElementInfo[optionKey] = nil
                end
            else
                savedElementInfo[optionKey] = nil
            end
        end

        if ZO_IsTableEmpty(savedElementInfo) then
            savedElementsTable[saveKey] = nil
        end
    end
end

function ZO_HUDManager:OnEditorShowing()
    self.nonDefaultElementsOnEditorShown = self:GetNonDefaultElements()
end

function ZO_HUDManager:OnEditorHiding()
    assert(self.nonDefaultElementsOnEditorShown, "OnEditorHiding called without a corresponding OnEditorShowing")

    local nonDefaultElements = self:GetNonDefaultElements()
    if not ZO_AreEqualSets(nonDefaultElements, self.nonDefaultElementsOnEditorShown) then
        local numNonDefault = NonContiguousCount(nonDefaultElements)
        local delta = numNonDefault - NonContiguousCount(self.nonDefaultElementsOnEditorShown)
        LogHUDEditorSession(numNonDefault, delta)
    end
    self.nonDefaultElementsOnEditorShown = nil
end

function ZO_HUDManager:GetNonDefaultElements(getGamepad)
    if getGamepad == nil then
        getGamepad = IsInGamepadPreferredMode()
    end

    local elements = {}
    local iterator = getGamepad and self.GamepadElementIterator or self.KeyboardElementIterator
    for _, elementData in iterator(self) do
        if not elementData:IsUsingDefaultAnchor() then
            elements[elementData] = true
        end
    end
    return elements
end

HUD_MANAGER = ZO_HUDManager:New()