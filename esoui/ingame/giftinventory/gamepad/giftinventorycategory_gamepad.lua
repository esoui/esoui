ZO_GiftInventoryCategory_Gamepad = ZO_Object.MultiSubclass(ZO_GamepadVerticalParametricScrollList, ZO_SocialOptionsDialogGamepad)

function ZO_GiftInventoryCategory_Gamepad:New(...)
    return ZO_GamepadVerticalParametricScrollList.New(self, ...)
end

function ZO_GiftInventoryCategory_Gamepad:Initialize(control)
    ZO_GamepadVerticalParametricScrollList.Initialize(self, control)
    ZO_SocialOptionsDialogGamepad.Initialize(self)

    -- the gift states that this list shows
    self.listSupportedGiftStates = {}
    self.giftStateToEntryTemplate = {}

    GIFT_INVENTORY_MANAGER:RegisterCallback("GiftListsChanged", function(changedLists)
        --find the most extreme change that a state list we are based on experienced
        local highestChangeType = GIFT_INVENTORY_MANAGER:GetHighestChangeType(changedLists, unpack(self.listSupportedGiftStates))
        if highestChangeType == ZO_GIFT_LIST_CHANGE_TYPE_LIST then
            self:RefreshList()
        elseif highestChangeType == ZO_GIFT_LIST_CHANGE_TYPE_SEEN then
            self:RefreshVisible()
        end
    end)

    self.shouldShowTooltip = false
    self.isDirty = true

    local function OnEffectivelyShown()
        if self.isDirty then
            self:RefreshList()
        end
    end
    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)

     local function OnEffectivelyHidden()
        local targetData = self:GetTargetData()
        if targetData then
            local gift = targetData.gift
            if gift:CanMarkViewedFromList() then
                gift:View()
            end
        end
    end
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_OPTIONS_MENU),
            keybind = "UI_SHORTCUT_TERTIARY",
            enabled = function()
                return self:HasAnyShownOptions()
            end,
            callback = function()
                return self:ShowOptionsDialog()
            end,
        },
    }

    self:SetOnSelectedDataChangedCallback(function() self:UpdateTooltip() end)

    self:SetOnTargetDataChangedCallback(function(_, newTargetData, oldTargetData)
        if newTargetData then
            local gift = newTargetData.gift
            self:SetupOptions({displayName = gift:GetPlayerName()})
        else
            self:SetupOptions(nil)
        end

        if oldTargetData then
            local gift = oldTargetData.gift
            if gift:CanMarkViewedFromList() then
                gift:View()
            end
        end
    end)
end

function ZO_GiftInventoryCategory_Gamepad:BuildOptionsList()
    local groupingId = self:AddOptionTemplateGroup(ZO_SocialOptionsDialogGamepad.GetDefaultHeader)

    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildGamerCardOption, IsConsoleUI)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildWhisperOption)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildAddFriendOption, ZO_SocialOptionsDialogGamepad.ShouldAddFriendOption)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildSendMailOption, ZO_SocialOptionsDialogGamepad.ShouldAddSendMailOption)
    self:AddOptionTemplate(groupingId, ZO_SocialOptionsDialogGamepad.BuildIgnoreOption, ZO_SocialOptionsDialogGamepad.SelectedDataIsNotPlayer)
end

function ZO_GiftInventoryCategory_Gamepad:AddSupportedGiftState(giftState, entryTemplate, setupFunction)
    table.insert(self.listSupportedGiftStates, giftState)

    local entryDataSetupFunction = setupFunction or ZO_SharedGamepadEntry_OnSetup

    self.giftStateToEntryTemplate[giftState] = entryTemplate
    self:AddDataTemplate(entryTemplate, entryDataSetupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction)
    self:AddDataTemplateWithHeader(entryTemplate, entryDataSetupFunction, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadMenuEntryHeaderTemplate")
end

function ZO_GiftInventoryCategory_Gamepad.GiftWithNoteSetupFunction(control, data, selected, selectedDuringRebuild, enabled, activated)
    data:SetNew(not data.gift:HasBeenSeen())
    local hasEmptyNote = data.gift:GetNote() == ""
    control:GetNamedChild("NoteTexture"):SetHidden(hasEmptyNote)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
end

-- This is used instead of ZO_ParametricScrollList:SetSortFunction since that will sort
-- the entry data after we add them to the list, which can mess up the headers
function ZO_GiftInventoryCategory_Gamepad:SetGiftSortFunction(sortFunction)
    self.giftSortFunction = sortFunction
end

function ZO_GiftInventoryCategory_Gamepad:RefreshList()
    if self.control:IsHidden() then
        self.isDirty = true
        return
    end
    self.isDirty = false

    local entries = {}

    for _, giftState in ipairs(self.listSupportedGiftStates) do
        local giftList = GIFT_INVENTORY_MANAGER:GetGiftList(giftState)
        for _, gift in ipairs(giftList) do
            local entryData = self:CreateGiftEntryData(gift)
            table.insert(entries, entryData)
        end
    end

    if self.giftSortFunction then
        table.sort(entries, self.giftSortFunction)
    end

    self:Clear()

    local currentCategoryHeader = nil
    for _, entry in ipairs(entries) do
        local giftState = entry.gift:GetState()
        local entryTemplate = self.giftStateToEntryTemplate[giftState]
        local entryHeader = entry.suggestedHeader
        if entryHeader ~= currentCategoryHeader then
            currentCategoryHeader = entryHeader
            entry:SetHeader(entryHeader)
            self:AddEntryWithHeader(entryTemplate, entry)
        else
            self:AddEntry(entryTemplate, entry)
        end
    end

    self:Commit()
end

function ZO_GiftInventoryCategory_Gamepad:GetKeybinds()
   return self.keybindStripDescriptor
end

function ZO_GiftInventoryCategory_Gamepad:ShowTooltip()
    self.shouldShowTooltip = true
    self:UpdateTooltip()
end

function ZO_GiftInventoryCategory_Gamepad:HideTooltip()
    self.shouldShowTooltip = false
    self:UpdateTooltip()
end

function ZO_GiftInventoryCategory_Gamepad:UpdateTooltip()
    -- optional override
end

function ZO_GiftInventoryCategory_Gamepad:CreateGiftEntryData(gift)
   --Override
    internalassert(false)
end
