GAMEPAD_SELECTOR_STRIDE = 3
GAMEPAD_SELECTOR_IGNORE_POSITION = -1

--
-- Character Creation Generic Selector
--

ZO_CharacterCreateSelector_Gamepad = ZO_Object:Subclass()

function ZO_CharacterCreateSelector_Gamepad:New(control)
    local object = ZO_Object.New(self)
    object:Initialize(control)
    return object
end

function ZO_CharacterCreateSelector_Gamepad:Initialize(control)
    control.sliderObject = self
    self.control = control
    self.currentHighlight = 1
    self.highlightControl = CCSelectorHighlight -- TODO: This is a concrete control from gamepad character select
    self.selectedControl = CreateControlFromVirtual(control:GetName() .. "Selected", control, "ZO_CharacterCreateSelectorSelected_Gamepad")

    self.stride = GAMEPAD_SELECTOR_STRIDE
end

function ZO_CharacterCreateSelector_Gamepad:FocusButton(enabled)
    local control = self:GetCurrentButton()
    if not control then
        return
    end

    local highlight = self.highlightControl

    if enabled then
        highlight:SetParent(control)
        highlight:SetAnchor(CENTER, control, CENTER, 0, 0)
        highlight:SetScale(1.3)
        highlight:SetHidden(false)

        self.focused = true
    else
        highlight:SetHidden(true)
        self.focused = false
    end

    self:UpdateButtons()
end

function ZO_CharacterCreateSelector_Gamepad:SetHighlightIndex(index)
    self.currentHighlight = index
end

function ZO_CharacterCreateSelector_Gamepad:GetFocusIndex()
    return self.control.sliderObject.info.index
end

function ZO_CharacterCreateSelector_Gamepad:GetSelectedIndex()
    return self.selectedPosition
end

function ZO_CharacterCreateSelector_Gamepad:UpdateButtons()
    local selectionName = self.control:GetNamedChild("SelectionName")
    local selectedControl = self.selectedControl
    local bannerText = nil
    for i, info in ipairs(self:GetSelectionInfo()) do
        if info.position == GAMEPAD_SELECTOR_IGNORE_POSITION then
            -- Ignore
        elseif info.selectorButton:GetState() == BSTATE_PRESSED then
            -- If the button is selected
            bannerText = bannerText or self:GetBannerText(info.selectorButton)

            selectedControl:SetParent(info.selectorButton)
            selectedControl:SetAnchor(CENTER, control, CENTER, 0, 0)
            selectedControl:SetScale(1.3)
            selectedControl:SetHidden(false)
            self.selectedPosition = info.position
        elseif info.position == self.currentHighlight and self.focused then
            -- If we have the button highlighted (in focus)
            bannerText = self:GetBannerText(info.selectorButton)
        else
            -- Unselected and unhighlighted
        end
    end

    selectionName:SetText(bannerText)
end

function ZO_CharacterCreateSelector_Gamepad:EnableFocus(enabled)
    local name = self.control:GetNamedChild("Name")
    local selectionName = self.control:GetNamedChild("SelectionName")
    if name then
        if enabled then
            name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
            name:SetFont("ZoFontGamepad42")
            selectionName:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
        else
            name:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
            name:SetFont("ZoFontGamepad34")
            selectionName:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
        end
    end

    self:FocusButton(enabled)
end

function ZO_CharacterCreateSelector_Gamepad:OnPrimaryButtonPressed()
    local control = self:GetCurrentButton()
    ZO_CharacterCreate_Gamepad_OnSelectorPressed(control)
end

function ZO_CharacterCreateSelector_Gamepad:GetButton(position)
    if position == GAMEPAD_SELECTOR_IGNORE_POSITION then
        return nil
    end

    for i, info in ipairs(self:GetSelectionInfo()) do
        if info.position == position then
            return info.selectorButton
        end
    end
    return nil
end

function ZO_CharacterCreateSelector_Gamepad:GetCurrentButton()
    return self:GetButton(self.currentHighlight)
end

function ZO_CharacterCreateSelector_Gamepad:MoveNext()
    local count =  #self:GetSelectionInfo() - self.currentHighlight;
    local newHighlight = self.currentHighlight

    while count > 0 do
        newHighlight = math.min(newHighlight + 1, #self:GetSelectionInfo())

        if self.currentHighlight % self.stride ~= 0 and self:IsButtonValid(newHighlight) then
            self:FocusButton(false)
            self.currentHighlight = newHighlight
            self:FocusButton(true)
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            break
        end
        count = count - 1
    end
end

function ZO_CharacterCreateSelector_Gamepad:MovePrevious()
    local count = self.currentHighlight - 1
    local newHighlight = self.currentHighlight

    while count > 0 do
        newHighlight = math.max(newHighlight - 1, 1)
        
        if self.currentHighlight % self.stride ~= 1 and self:IsButtonValid(newHighlight) then
            self:FocusButton(false)
            self.currentHighlight = newHighlight
            self:FocusButton(true)
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            break
        end
        count = count - 1
    end
end

function ZO_CharacterCreateSelector_Gamepad:FindNearestValidButton(newHighlight)
    local count = #self:GetSelectionInfo()

    while count >= 0 do
        if self:IsButtonValid(newHighlight) then
            return newHighlight
        end
        newHighlight = (newHighlight + 1) % (#self:GetSelectionInfo() + 1)
        count = count - 1
    end

    return nil
end

function ZO_CharacterCreateSelector_Gamepad:IsButtonValid(buttonIndex)
    local isValid = false
    local newButton = self:GetButton(buttonIndex)
    if newButton then
        local newButtonState = newButton:GetState()
        isValid = (newButtonState ~= BSTATE_DISABLED_PRESSED) and (newButtonState ~= BSTATE_DISABLED)
    end
    return isValid
end

function ZO_CharacterCreateSelector_Gamepad:ProcessUpDownMove(move)
    local newHighlight = self.currentHighlight
    local sound = nil
    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        newHighlight = newHighlight + self.stride
        sound = SOUNDS.GAMEPAD_MENU_DOWN
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        newHighlight = newHighlight - self.stride
        sound = SOUNDS.GAMEPAD_MENU_UP
    elseif not self:IsButtonValid(newHighlight) then
        newHighlight = self:FindNearestValidButton(newHighlight)
    else
        newHighlight = nil
    end

    if newHighlight then
        if newHighlight < 1 or newHighlight > #self:GetSelectionInfo() then
            newHighlight = nil
        else
            PlaySound(sound)
        end
    end

    return newHighlight
end

function ZO_CharacterCreateSelector_Gamepad:FocusUpdate(move)
    -- Up/down movement
    local newHighlight = self:ProcessUpDownMove(move)

    if newHighlight then
        self:FocusButton(false)
        self.currentHighlight = newHighlight
        self:FocusButton(true)
        return true
    end
end

function ZO_CharacterCreateSelector_Gamepad:GetBannerText(control)
    -- To be overridden
end

function ZO_CharacterCreateSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    -- To be overridden
end

function ZO_CharacterCreateSelector_Gamepad:GetHighlightColumn()
    -- To be overridden
end

--
-- Character Creation Alliance
--

ZO_CharacterCreateAllianceSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateAllianceSelector_Gamepad:New(control)
    local object = ZO_CharacterCreateSelector_Gamepad.New(self, control)

    object.stride = GAMEPAD_SELECTOR_STRIDE
    object.showKeybind = true
end

function ZO_CharacterCreateAllianceSelector_Gamepad:GetSelectionInfo(control)
    return GAMEPAD_CHARACTER_CREATE_MANAGER.characterData:GetAllianceInfo()
end

function ZO_CharacterCreateAllianceSelector_Gamepad:GetBannerText(control)
    return zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(control.defId))
end

function ZO_CharacterCreateAllianceSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    self.currentHighlight = index
end

function ZO_CharacterCreateAllianceSelector_Gamepad:GetHighlightColumn()
    return self.currentHighlight
end

function ZO_CharacterCreateAllianceSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

-- Character Creation Race

ZO_CharacterCreateRaceSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateRaceSelector_Gamepad:New(control)
    local object = ZO_CharacterCreateSelector_Gamepad.New(self, control)

    object.stride = GAMEPAD_SELECTOR_STRIDE
    object.showKeybind = true
    control.preSelectedOffsetAdditionalPadding = -20
end

function ZO_CharacterCreateRaceSelector_Gamepad:IsValidRaceForAlliance(raceButtonPosition)
	local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local selectedAlliance = CharacterCreateGetAlliance(characterMode)

    local button = self:GetButton(raceButtonPosition)
    if not button then
        return false
    end

    local alliance = button.alliance

    return alliance == 0 or alliance == selectedAlliance or CanPlayAnyRaceAsAnyAlliance()
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetSelectionInfo(control)
    return GAMEPAD_CHARACTER_CREATE_MANAGER.characterData:GetRaceInfo()
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetBannerText(control)
	local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentGender = CharacterCreateGetGender(characterMode)

    return zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, control.defId))
end

function ZO_CharacterCreateRaceSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    local maxIndex = self.control.numButtons

    if not moveDown then
        local currentIndex = maxIndex
        while currentIndex > 0 do
            if self:GetColumnFromIndex(currentIndex) == index and self:IsValidRaceForAlliance(currentIndex) then
                self.currentHighlight = currentIndex
                return
            end
            currentIndex = currentIndex - 1
        end
    end

    self.currentHighlight = index
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetColumnFromIndex(index)
    local maxIndex = #self:GetSelectionInfo()

    -- These are the centered buttons
    if maxIndex == 4 then
        if index == 4 then
            return 2
        end
    elseif maxIndex == 10 then
        if index == 10 then
            return 2
        end
    end

    return (index - 1) % self.stride + 1
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetHighlightColumn(index)
    return self:GetColumnFromIndex(self.currentHighlight)
end

function ZO_CharacterCreateRaceSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetNearestValidRace(index, minIndex)
    local maxIndex = #self:GetSelectionInfo()
    if not self:IsValidRaceForAlliance(index) then
        index = minIndex

        while index < maxIndex and not self:IsValidRaceForAlliance(index) do
            index = index + 1
        end
    end
    return index
end

function ZO_CharacterCreateRaceSelector_Gamepad:ProcessUpDownMove(move)
    local newHighlight = self.currentHighlight

    -- Button layout is
    -- 1 2 3
    -- 4 5 6
    -- 7 8 9
    --   10

    local LAST_ROW_LEFT = 7
    local LAST_ROW_MIDDLE = 8
    local MAX_RACE = 10

    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if newHighlight == MAX_RACE then
            return nil
        elseif newHighlight >= LAST_ROW_LEFT then
            newHighlight = MAX_RACE
        else
            newHighlight = newHighlight + self.stride

            -- Make sure we move it back up to a valid button
            newHighlight = self:GetNearestValidRace(newHighlight, newHighlight - (newHighlight - 1) % self.stride)
        end
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if newHighlight == MAX_RACE then
            -- Move directly back up
            newHighlight = LAST_ROW_MIDDLE

            -- Make sure we move it back up to a valid button
            newHighlight = self:GetNearestValidRace(newHighlight, LAST_ROW_LEFT)
        else
            newHighlight = newHighlight - self.stride
        end
    else
        return nil
    end

    if self:IsValidRaceForAlliance(newHighlight) then
        if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        end

        return newHighlight
    end
    return nil
end

--
-- Character Creation Class
--

ZO_CharacterCreateClassSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateClassSelector_Gamepad:New(control)
    local object = ZO_CharacterCreateSelector_Gamepad.New(self, control)

    object.stride = GAMEPAD_SELECTOR_STRIDE
    object.showKeybind = true
end

function ZO_CharacterCreateClassSelector_Gamepad:GetSelectionInfo(control)
    return GAMEPAD_CHARACTER_CREATE_MANAGER.characterData:GetClassInfo()
end

function ZO_CharacterCreateClassSelector_Gamepad:GetBannerText(control)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentGender = CharacterCreateGetGender(characterMode)

    return zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, control.defId))
end

function ZO_CharacterCreateClassSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    self.currentHighlight = index
end

function ZO_CharacterCreateClassSelector_Gamepad:GetHighlightColumn()
    if self.currentHighlight == 4 then
        return 2
    end
    return self.currentHighlight
end

function ZO_CharacterCreateClassSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

function ZO_CharacterCreateClassSelector_Gamepad:ProcessUpDownMove(move)
    -- Button layout is
    -- 1 2 3
    --   4 
    -- So moving down from 1-3 goes to 4
    -- and moving up from 4 goes to 2
    local newHighlight = self.currentHighlight
    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if newHighlight <= 3 then
            newHighlight = 4
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        else
            newHighlight = nil
        end
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if newHighlight == 4 then
            newHighlight = 2
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        else
            newHighlight = nil
        end
    elseif not self:IsButtonValid(newHighlight) then
        newHighlight = self:FindNearestValidButton(newHighlight)
    else
        newHighlight = nil
    end

    if newHighlight then
        if newHighlight < 1 or newHighlight > #self:GetSelectionInfo() then
            newHighlight = nil
        end
    end

    return newHighlight
end