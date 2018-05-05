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
    self.selectionName = control:GetNamedChild("SelectionName")
    self.highlightControl = CreateControlFromVirtual("$(parent)Highlight", control, "ZO_CharacterCreateSelectorHighlight_Gamepad")
    self.selectedControl = CreateControlFromVirtual("$(parent)Selected", control, "ZO_CharacterCreateSelectorSelected_Gamepad")
    self.showKeybind = true
    self.stride = GAMEPAD_SELECTOR_STRIDE
    self.focusEnabled = false
    self.currentHighlight = GAMEPAD_SELECTOR_IGNORE_POSITION -- we start off with no highlight because we have no controls to highlight yet
    self.lastHighlight = 1
end

function ZO_CharacterCreateSelector_Gamepad:SetHighlight(index)
    self.currentHighlight = index

    local control = self:GetCurrentButton()
    self.buttonHighlighted = control ~= nil

    local highlight = self.highlightControl
    if self.buttonHighlighted then
        highlight:SetParent(control)
        highlight:SetAnchor(CENTER, control, CENTER, 0, 0)

        local bannerText = self:GetBannerText(control)
        self.selectionName:SetText(bannerText)
    end

    highlight:SetHidden(not self.buttonHighlighted)

    local buttonInfo = self:GetButtonInfo(index)
    self:OnButtonHighlighted(buttonInfo)
end

function ZO_CharacterCreateSelector_Gamepad:GetFocusIndex()
    return self.control.sliderObject.info.index
end

function ZO_CharacterCreateSelector_Gamepad:GetSelectedIndex()
    return self.selectedPosition
end

function ZO_CharacterCreateSelector_Gamepad:UpdateButtons()
    local selectedControl = self.selectedControl
    local bannerText = nil
    for i, info in ipairs(self:GetSelectionInfo()) do
        if info.position == GAMEPAD_SELECTOR_IGNORE_POSITION then
            -- Ignore
        elseif info.selectorButton:GetState() == BSTATE_PRESSED then
            -- If the button is selected
            if bannerText == nil then
                bannerText = self:GetBannerText(info.selectorButton)
            end

            selectedControl:SetParent(info.selectorButton)
            selectedControl:SetAnchor(CENTER, control, CENTER, 0, 0)
            selectedControl:SetHidden(false)
            self.selectedPosition = info.position
        elseif info.position == self.currentHighlight and self.buttonHighlighted then
            -- If we have the button highlighted (in focus)
            bannerText = self:GetBannerText(info.selectorButton)
        else
            -- Unselected and unhighlighted
        end
    end

    self.selectionName:SetText(bannerText)
end

function ZO_CharacterCreateSelector_Gamepad:EnableFocus(enabled)
    local nameControl = self.control:GetNamedChild("Name")
    if nameControl then
        local fontColor
        local nameFont
        if enabled then
            fontColor = ZO_SELECTED_TEXT
            nameFont = "ZoFontGamepad42"
        else
            fontColor = ZO_DISABLED_TEXT
            nameFont = "ZoFontGamepad34"
        end

        nameControl:SetColor(fontColor:UnpackRGB())
        nameControl:SetFont(nameFont)
        self.selectionName:SetColor(fontColor:UnpackRGB())
    end

    self.focusEnabled = enabled

    if enabled then
        -- if we are enabling then we need to make sure the highlight is initialized/reenabled
        local highlightIndex = self.currentHighlight
        if highlightIndex == GAMEPAD_SELECTOR_IGNORE_POSITION then
            highlightIndex = self.lastHighlight
        end
        self:SetHighlight(highlightIndex)
    else
        -- if we are disabling then we need to make sure the highlight is disabled
        -- and we need to set our selection text to the text of the selected control instead of the highlight
        self.buttonHighlighted = false
        local buttonInfo = self:GetButtonInfo(self.selectedPosition)
        local bannerText = self:GetBannerText(buttonInfo.selectorButton)
        self.selectionName:SetText(bannerText)
        self.lastHighlight = self.currentHighlight
        self:SetHighlight(GAMEPAD_SELECTOR_IGNORE_POSITION)
    end
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

function ZO_CharacterCreateSelector_Gamepad:GetButtonInfo(position)
    if position == GAMEPAD_SELECTOR_IGNORE_POSITION then
        return nil
    end

    for i, info in ipairs(self:GetSelectionInfo()) do
        if info.position == position then
            return info
        end
    end
    return nil
end

function ZO_CharacterCreateSelector_Gamepad:MoveNext()
    local count =  #self:GetSelectionInfo() - self.currentHighlight;
    local newHighlight = self.currentHighlight

    while count > 0 do
        newHighlight = math.min(newHighlight + 1, #self:GetSelectionInfo())

        if self.currentHighlight % self.stride ~= 0 and self:IsValidButtonAtIndex(newHighlight) then
            self:SetHighlight(newHighlight)
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
        
        if self.currentHighlight % self.stride ~= 1 and self:IsValidButtonAtIndex(newHighlight) then
            self:SetHighlight(newHighlight)
            PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED)
            break
        end
        count = count - 1
    end
end

function ZO_CharacterCreateSelector_Gamepad:GetNearestValidIndex(index, minIndex, maxIndex)
    if not self:IsValidButtonAtIndex(index) then
        index = maxIndex

        while index > minIndex and not self:IsValidButtonAtIndex(index) do
            index = index - 1
        end
    end
    return index
end

function ZO_CharacterCreateSelector_Gamepad:IsValidButtonAtIndex(buttonIndex)
    local button = self:GetButton(buttonIndex)
    return button ~= nil
end

function ZO_CharacterCreateSelector_Gamepad:ProcessUpDownMove(move)
    local currentHighlight = self.currentHighlight
    local newHighlight = currentHighlight

    -- Button layout is similar to
    -- 1 2 3
    -- or
    -- 1 2 3
    --   4
    -- or
    -- 1 2 3
    -- 4 5

    local maxHighlightIndex = self:GetMaxHighlightIndex()
    local lastRowLeftIndex = zo_ceil(maxHighlightIndex / self.stride) * self.stride - self.stride + 1

    if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
        -- Moving Down
        if currentHighlight >= lastRowLeftIndex then
            -- If we are in the bottom row, there's no moving down
            return nil
        else
            -- Move straight down, but make sure we move down to a valid button
            local targetHighlight = currentHighlight + self.stride
            local leftmostHighlight = targetHighlight - (targetHighlight - 1) % self.stride
            local rightmostHighlight = targetHighlight
            newHighlight = self:GetNearestValidIndex(targetHighlight, leftmostHighlight, rightmostHighlight, move)
        end
    elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        -- Moving Up
        if currentHighlight <= self.stride then
            -- If we are in the top row, there's no moving up
            return nil
        else
            -- Move straight up
            newHighlight = currentHighlight - self.stride
            if currentHighlight == maxHighlightIndex and maxHighlightIndex % self.stride == 1 then
                -- If the button is being centered in the final rows
                -- straight up needs to be offset to the right to match the same column
                newHighlight = newHighlight + zo_floor(self.stride / 2)
            end
        end
    else
        return nil
    end

    if self:IsValidButtonAtIndex(newHighlight) then
        if move == MOVEMENT_CONTROLLER_MOVE_NEXT then
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        elseif move == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        end

        return newHighlight
    end

    return nil
end

function ZO_CharacterCreateSelector_Gamepad:FocusUpdate(move)
    -- Up/down movement
    local newHighlight = self:ProcessUpDownMove(move)

    if newHighlight then
        self:SetHighlight(newHighlight)
        return true
    end

    return false
end

function ZO_CharacterCreateSelector_Gamepad:GetColumnFromIndex(index)
    local maxIndex = self:GetMaxHighlightIndex()
    -- If we have a set of buttons, such that there will be one button on the last row
    -- it will be centered in the middle instead of being all the way on the left
    if maxIndex % self.stride == 1 then
        if index == maxIndex then
            local centerColumnIndex = zo_ceil(self.stride / 2)
            return centerColumnIndex
        end
    end

    return (index - 1) % self.stride + 1
end

function ZO_CharacterCreateSelector_Gamepad:GetHighlightColumn()
    return self:GetColumnFromIndex(self.currentHighlight)
end

function ZO_CharacterCreateSelector_Gamepad:GetMaxHighlightIndex()
    return #self:GetSelectionInfo()
end

function ZO_CharacterCreateSelector_Gamepad:GetBannerText(control)
    -- To be overridden
end

function ZO_CharacterCreateSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    -- To be overridden
end

function ZO_CharacterCreateSelector_Gamepad:GetInformationTooltipStrings(buttonInfo)
    -- Optional override
    local title = ""
    local description = ""
    return title, description
end

function ZO_CharacterCreateSelector_Gamepad:OnButtonHighlighted(buttonInfo)
    if buttonInfo then
        local title, description = self:GetInformationTooltipStrings(buttonInfo)
        if title ~= "" or description ~= "" then
            GAMEPAD_CHARACTER_CREATE_MANAGER:ShowInformationTooltip(title, description)
            return
        end
    end

    GAMEPAD_CHARACTER_CREATE_MANAGER:HideInformationTooltip()
end

--
-- Character Creation Alliance
--

ZO_CharacterCreateAllianceSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateAllianceSelector_Gamepad:New(control)
    return ZO_CharacterCreateSelector_Gamepad.New(self, control)
end

function ZO_CharacterCreateAllianceSelector_Gamepad:GetSelectionInfo(control)
    return GAMEPAD_CHARACTER_CREATE_MANAGER.characterData:GetAllianceInfo()
end

function ZO_CharacterCreateAllianceSelector_Gamepad:GetBannerText(control)
    return zo_strformat(SI_ALLIANCE_NAME, GetAllianceName(control.defId))
end

function ZO_CharacterCreateAllianceSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    self:SetHighlight(index)
end

function ZO_CharacterCreateAllianceSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

--
-- Character Creation Race
--

ZO_CharacterCreateRaceSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateRaceSelector_Gamepad:New(...)
    return ZO_CharacterCreateSelector_Gamepad.New(self, ...)
end

function ZO_CharacterCreateRaceSelector_Gamepad:Initialize(control)
    ZO_CharacterCreateSelector_Gamepad.Initialize(self, control)

    control.preSelectedOffsetAdditionalPadding = -20
end

function ZO_CharacterCreateRaceSelector_Gamepad:IsValidButtonAtIndex(buttonIndex)
    if ZO_CharacterCreateSelector_Gamepad.IsValidButtonAtIndex(self, buttonIndex) then
        local button = self:GetButton(buttonIndex)
        return self:IsValidRaceForAlliance(button.alliance)
    else
        return false
    end
end

function ZO_CharacterCreateRaceSelector_Gamepad:IsValidRaceForAlliance(alliance)
    if alliance == 0 then
        -- If there is no alliance restriction, then it's fine
        return true
    end

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local selectedAlliance = CharacterCreateGetAlliance(characterMode)

    return alliance == selectedAlliance or CanPlayAnyRaceAsAnyAlliance()
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetSelectionInfo(control)
    return GAMEPAD_CHARACTER_CREATE_MANAGER.characterData:GetRaceInfo()
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetBannerText(control)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentGender = CharacterCreateGetGender(characterMode)

    return zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, control.defId))
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetMaxHighlightIndex()
    return self.control.numButtons
end

function ZO_CharacterCreateRaceSelector_Gamepad:SetHighlightIndexByColumn(index, moveDown)
    if not moveDown then
        local currentIndex = self:GetMaxHighlightIndex()
        while currentIndex > 0 do
            if self:GetColumnFromIndex(currentIndex) == index and self:IsValidButtonAtIndex(currentIndex) then
                self:SetHighlight(currentIndex)
                return
            end
            currentIndex = currentIndex - 1
        end
    end

    self:SetHighlight(index)
end

function ZO_CharacterCreateRaceSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

function ZO_CharacterCreateRaceSelector_Gamepad:GetInformationTooltipStrings(buttonInfo)
    local title = ""
    local description = ""

    if buttonInfo then
        if not buttonInfo.isSelectable then
            local control = buttonInfo.selectorButton
            local restrictionReason, restrictingCollectible = GetRaceRestrictionReason(control.defId)
            description = ZO_CHARACTERCREATE_MANAGER.GetOptionRestrictionString(restrictionReason, restrictingCollectible)
            if description ~= "" then
                if restrictingCollectible ~= 0 and IsCollectiblePurchasable(restrictingCollectible) then
                    description = string.format("%s\n\n%s", description, GetString(SI_CHARACTER_CREATE_RESTRICTION_COLLECTIBLE_PURCHASABLE))
                end

                title = self:GetBannerText(control)
            end
        end
    end

    return title, description
end

--
-- Character Creation Class
--

ZO_CharacterCreateClassSelector_Gamepad = ZO_CharacterCreateSelector_Gamepad:Subclass()

function ZO_CharacterCreateClassSelector_Gamepad:New(...)
    return ZO_CharacterCreateSelector_Gamepad.New(self, ...)
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
    self:SetHighlight(index)
end

function ZO_CharacterCreateClassSelector_Gamepad:EnableFocus(enabled)
    if enabled then
        GAMEPAD_CHARACTER_CREATE_MANAGER:ShowLoreInfo(GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS)
    else
        GAMEPAD_CHARACTER_CREATE_MANAGER:HideLoreInfo()
    end

    ZO_CharacterCreateSelector_Gamepad.EnableFocus(self, enabled)
end

function ZO_CharacterCreateClassSelector_Gamepad:GetInformationTooltipStrings(buttonInfo)
    local title = ""
    local description = ""

    if buttonInfo then
        if not buttonInfo.isSelectable then
            local control = buttonInfo.selectorButton
            local restrictionReason, restrictingCollectible = GetClassRestrictionReason(control.defId)
            description = ZO_CHARACTERCREATE_MANAGER.GetOptionRestrictionString(restrictionReason, restrictingCollectible)
            if description ~= "" then
                if restrictingCollectible ~= 0 and IsCollectiblePurchasable(restrictingCollectible) then
                    description = string.format("%s\n\n%s", description, GetString(SI_CHARACTER_CREATE_RESTRICTION_COLLECTIBLE_PURCHASABLE))
                end

                title = self:GetBannerText(control)
            end
        end
    end

    return title, description
end
