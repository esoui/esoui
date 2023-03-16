local ZO_TradingHouseNameSearchAutoComplete_Gamepad = ZO_GamepadTradingHouse_ItemList:Subclass()

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:New(...)
    return ZO_GamepadTradingHouse_ItemList.New(self, ...)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:Initialize(control)
    ZO_GamepadTradingHouse_ItemList.Initialize(self, control)

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:AddFragmentsToSubscene(self:GetSubscene())
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:InitializeEvents()
    ZO_GamepadTradingHouse_ItemList.InitializeEvents(self)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor = 
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_TRADING_HOUSE_AUTOCOMPLETE_SELECT),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                local targetData = self.itemList:GetTargetData()
                local nameSearchFeature = GAMEPAD_TRADING_HOUSE_BROWSE:GetNameSearchFeature()
                local searchText = ZO_TradingHouseNameSearchFeature_Shared.MakeExactSearchText(targetData.name)
                nameSearchFeature:SetSearchText(searchText)
                TRADING_HOUSE_GAMEPAD:LeaveNameSearchAutoComplete()
            end,
            visible = function()
                local targetData = self.itemList:GetTargetData()
                return targetData ~= nil
            end,
        }
    }

    local function LeaveNameSearchAutoComplete()
        TRADING_HOUSE_GAMEPAD:LeaveNameSearchAutoComplete()
    end
    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, LeaveNameSearchAutoComplete)

    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.itemList)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:RefreshList()
    self.itemList:Clear()

    local nameMatchId = GAMEPAD_TRADING_HOUSE_BROWSE:GetNameSearchFeature():GetCompletedItemNameMatchId()
    if nameMatchId then
        local numResults = GetNumMatchTradingHouseItemNamesResults(nameMatchId)
        if internalassert(numResults, "match results not available for given nameMatchId") then
            for resultIndex = 1, numResults do
                local name, _ = GetMatchTradingHouseItemNamesResult(nameMatchId, resultIndex)
                local entryData =
                {
                    name = name,
                    narrationText = function()
                        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(name)
                    end,
                }
                self.itemList:AddEntry("ZO_GamepadGuildStoreNameMatchEntryTemplate", entryData)
            end
        end
    end

    self.itemList:Commit()
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:RefreshVisible()
    self.itemList:RefreshVisible()
end

-- Overriden functions
function ZO_TradingHouseNameSearchAutoComplete_Gamepad:GetHeaderReplacementInfo()
    return true, GetString(SI_GAMEPAD_TRADING_HOUSE_AUTOCOMPLETE_TITLE)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:InitializeList()
    ZO_GamepadTradingHouse_ItemList.InitializeList(self)

    local function OnTargetChanged(...)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
    
    self.itemList:SetOnTargetDataChangedCallback(OnTargetChanged)
    self.itemList:SetAlignToScreenCenter(true)

    local function SetupNameMatchEntry(control, data, selected, reselectingDuringRebuild, enabled, active)
        control.label:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))
        control.label:SetColor(ZO_GamepadMenuEntryTemplate_GetLabelColor(selected, not enabled):UnpackRGBA())
        control.label:SetText(data.name)
    end

    self.itemList:AddDataTemplate("ZO_GamepadGuildStoreNameMatchEntryTemplate", SetupNameMatchEntry)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:OnShowing()
    self:RefreshList()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

function ZO_TradingHouseNameSearchAutoComplete_Gamepad:UpdateKeybind()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
end

-- Globals

function ZO_TradingHouseNameSearchAutoComplete_Gamepad_OnInitialize(control)
    GAMEPAD_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE = ZO_TradingHouseNameSearchAutoComplete_Gamepad:New(control)
end
