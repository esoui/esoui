local ZO_TradingHouseSearchHistory_Gamepad = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_TradingHouseSearchHistory_Gamepad:New(...)
    return ZO_GamepadTradingHouse_ItemList.New(self, ...)
end

function ZO_TradingHouseSearchHistory_Gamepad:Initialize(control)
    ZO_GamepadTradingHouse_ItemList.Initialize(self, control)

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:AddFragmentsToSubscene(self:GetSubscene())
end

function ZO_TradingHouseSearchHistory_Gamepad:InitializeEvents()
    ZO_GamepadTradingHouse_ItemList.InitializeEvents(self)

    TRADING_HOUSE_SEARCH_HISTORY_MANAGER:RegisterCallback("HistoryUpdated", function()
        if self.fragment:IsShowing() then
            self:RefreshList()
            self:UpdateDescriptionTooltip()
        end
    end)
end

function ZO_TradingHouseSearchHistory_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_TRADE_SUBMIT),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local targetData = self.itemList:GetTargetData()

                -- This entry will jump to the top, we should jump to the top too
                local DONT_ANIMATE = false
                self.itemList:SetDefaultIndexSelected(DONT_ANIMATE)

                TRADING_HOUSE_SEARCH:LoadSearchTable(targetData.searchTable)
                TRADING_HOUSE_GAMEPAD:EnterBrowseResults()
            end,
            visible = function()
                return self.itemList:GetTargetData() ~= nil
            end,
        },
        {
            name = GetString(SI_TRADING_HOUSE_DELETE_SEARCH_HISTORY_ENTRY),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            callback = function()
                local targetData = self.itemList:GetTargetData()
                TRADING_HOUSE_SEARCH_HISTORY_MANAGER:RemoveSearchTable(targetData.searchTable)
                --Re-narrate when an entry is removed
                SCREEN_NARRATION_MANAGER:QueueParametricListEntry(self.itemList)
                KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
            end,
            visible = function()
                return self.itemList:GetTargetData() ~= nil
            end,
        },
    }
    self:AddGuildChangeKeybindDescriptor(self.keybindStripDescriptor)

    local function LeaveSearchHistory()
        TRADING_HOUSE_GAMEPAD:LeaveSearchHistory()
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, LeaveSearchHistory)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_TradingHouseSearchHistory_Gamepad:RefreshList()
    self.itemList:Clear()

    for _, searchEntry in TRADING_HOUSE_SEARCH_HISTORY_MANAGER:SearchEntryIterator() do
        local searchEntryData = 
        {
            searchTable = searchEntry.searchTable,
            narrationText = function(entryData, entryControl)
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.formattedSearchTableDescription)
            end,
        }
        self.itemList:AddEntry("ZO_GamepadGuildStoreSearchHistoryEntryTemplate", searchEntryData)
    end

    self.itemList:Commit()
end

function ZO_TradingHouseSearchHistory_Gamepad:RefreshVisible()
    self.itemList:RefreshVisible()
end

-- Overriden functions
function ZO_TradingHouseSearchHistory_Gamepad:GetHeaderReplacementInfo()
    return true, GetString(SI_TRADING_HOUSE_SEARCH_HISTORY_TITLE)
end

function ZO_TradingHouseSearchHistory_Gamepad:InitializeList()
    ZO_GamepadTradingHouse_ItemList.InitializeList(self)

    local function OnTargetChanged(...)
        self:UpdateDescriptionTooltip()
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
    
    self.itemList:SetOnTargetDataChangedCallback(OnTargetChanged)
    self.itemList:SetNoItemText(GetString(SI_TRADING_HOUSE_SEARCH_HISTORY_EMPTY_TEXT))
    self.itemList:SetAlignToScreenCenter(true)

    -- Recent Search Button Template
    local function SetupHistoryEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.label:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        control.label:SetColor(ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, not enabled):UnpackRGBA())
        if not data.formattedSearchTableDescription then
            data.formattedSearchTableDescription = TRADING_HOUSE_SEARCH:GenerateSearchTableShortDescription(data.searchTable)
        end
        control.label:SetText(data.formattedSearchTableDescription)
    end

    self.itemList:AddDataTemplate("ZO_GamepadGuildStoreSearchHistoryEntryTemplate", SetupHistoryEntry)
end

function ZO_TradingHouseSearchHistory_Gamepad:OnShowing()
    self:RefreshList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseSearchHistory_Gamepad:UpdateKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseSearchHistory_Gamepad:UpdateDescriptionTooltip()
    local targetData = self.itemList:GetTargetData()
    if targetData then
        GAMEPAD_TOOLTIPS:LayoutTextBlockTooltip(GAMEPAD_RIGHT_TOOLTIP, TRADING_HOUSE_SEARCH:GenerateSearchTableDescription(targetData.searchTable))
    else
        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
    end
end

-- Globals

function ZO_TradingHouseSearchHistory_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_SEARCH_HISTORY = ZO_TradingHouseSearchHistory_Gamepad:New(control)
end
