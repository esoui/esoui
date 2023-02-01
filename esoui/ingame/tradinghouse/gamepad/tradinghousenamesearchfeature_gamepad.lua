-----------------
-- Name Search --
-----------------
ZO_TradingHouseNameSearchFeature_Gamepad = ZO_TradingHouseNameSearchFeature_Shared:Subclass()

function ZO_TradingHouseNameSearchFeature_Gamepad:New(...)
    return ZO_TradingHouseNameSearchFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseNameSearchFeature_Gamepad:Initialize()
    self.searchText = ""
    EVENT_MANAGER:RegisterForEvent("TradingHouseNameSearchFeature_Gamepad", EVENT_MATCH_TRADING_HOUSE_ITEM_NAMES_COMPLETE, function(_, ...)
        self:OnNameMatchComplete(...)
    end)
    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchCriteriaChanged", function()
        if IsInGamepadPreferredMode() then
            self:MarkFiltersDirty()
        end
    end)
end

-- Override
function ZO_TradingHouseNameSearchFeature_Gamepad:GetSearchText()
    return self.searchText
end

-- Override
function ZO_TradingHouseNameSearchFeature_Gamepad:SetSearchText(searchText)
    self.searchText = searchText

    if not self:IsSearchTextLongEnough() then
        self.lastCompletedMatchNumResults = nil
    end

    TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
end

function ZO_TradingHouseNameSearchFeature_Gamepad:SetupNameSearchField(control, data, selected, reselectingDuringRebuild, enabled, active)
    control.highlight:SetHidden(not selected)

    data.editBoxControl = control.editBoxControl
    control.editBoxControl.textChangedCallback = function(editBoxControl)
        local searchText = editBoxControl:GetText()
        if searchText ~= self.searchText then
            self:SetSearchText(searchText)
            if not self:IsSearchTextLongEnough() then
                GAMEPAD_TRADING_HOUSE_BROWSE:RefreshVisible()
            end
        end
    end

    control.editBoxControl.focusLostCallback = function(editBoxControl)
        if data.onFocusLostCallback then
            data.onFocusLostCallback(editBoxControl)
        end
    end
    
    control.editBoxControl:SetDefaultText(GetString(SI_TRADING_HOUSE_BROWSE_ITEM_NAME_SEARCH_EDIT_DEFAULT))
    if control.editBoxControl:GetText() ~= self.searchText then
        control.editBoxControl:SetText(self.searchText)
    end
end

function ZO_TradingHouseNameSearchFeature_Gamepad:GetOrCreateAutoCompleteEntryData()
    if not self.autocompleteEntryData then
        self.autocompleteEntryData =
        {
            isSelectableEntry = true,
            labelText = function()
                local numResults = self.lastCompletedMatchNumResults
                if numResults then
                    return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_BROWSE_OPEN_AUTOCOMPLETE, numResults)
                end
                
                return GetString(SI_GAMEPAD_TRADING_HOUSE_BROWSE_AUTOCOMPLETE_DEFAULT_TEXT)
            end,
            onSelectedCallback = function()
                -- Protect against opening autocomplete without a completed name match: Since we don't have a pending state for this
                -- label (and we don't want one given how fast name matches tend to be) this is our line of defense against showing this list before we have the data to populate it.
                if GAMEPAD_TRADING_HOUSE_BROWSE:GetNameSearchFeature():GetCompletedItemNameMatchId() then
                    TRADING_HOUSE_GAMEPAD:EnterNameSearchAutoComplete()
                end
            end,
            isEnabledCallback = function()
                local numResults = self.lastCompletedMatchNumResults
                return numResults ~= nil and numResults ~= 0
            end,
            narrationText = function(entryData, entryControl)
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(entryData.labelText())
            end,
        }
    end
    return self.autocompleteEntryData
end

function ZO_TradingHouseNameSearchFeature_Gamepad:AddEntries(itemList)
    local nameSearchData = ZO_GamepadEntryData:New("GuildStoreNameSearch")
    nameSearchData.feature = self
    nameSearchData:SetHeader(self:GetDisplayName())
    nameSearchData.narrationText = ZO_GetDefaultParametricListEditBoxNarrationText
    itemList:AddEntryWithHeader("ZO_GamepadTextFieldItem", nameSearchData)

    itemList:AddEntry("ZO_GamepadGuildStoreBrowseSelectableEntryTemplate", self:GetOrCreateAutoCompleteEntryData())
end

function ZO_TradingHouseNameSearchFeature_Gamepad:OnNameMatchComplete(id, numResults, backgroundDurationMS)
    if id == self.pendingItemNameMatchId then
        -- cache off the current num results for display purposes: this helps us avoid short flickers while the name match is still running
        self.lastCompletedMatchNumResults = numResults
    else
        self.lastCompletedMatchNumResults = nil
    end

    ZO_TradingHouseNameSearchFeature_Shared.OnNameMatchComplete(self, id, numResults)
end
