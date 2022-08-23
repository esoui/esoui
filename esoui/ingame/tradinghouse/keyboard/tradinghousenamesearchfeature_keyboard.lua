-----------------
-- Name search --
-----------------
ZO_TradingHouseNameSearchFeature_Keyboard = ZO_TradingHouseNameSearchFeature_Shared:Subclass()

function ZO_TradingHouseNameSearchFeature_Keyboard:New(...)
    return ZO_TradingHouseNameSearchFeature_Shared.New(self, ...)
end

-- Override
function ZO_TradingHouseNameSearchFeature_Keyboard:GetSearchText()
    return self.nameSearchEdit:GetText()
end

-- Override
function ZO_TradingHouseNameSearchFeature_Keyboard:SetSearchText(newSearchText)
    self.nameSearchEdit:SetText(newSearchText)
    self.nameSearchEdit:SetCursorPosition(0)
end

function ZO_TradingHouseNameSearchFeature_Keyboard:AttachToControl(itemNameSearchControl, itemNameSearchAutoCompleteControl)
    self.nameSearchEdit = itemNameSearchControl:GetNamedChild("Box")
    self.nameSearchEdit:SetHandler("OnTextChanged", function()
        self:OnNameSearchEditTextChanged()
    end)
    self.nameSearchEdit:RegisterForEvent(EVENT_MATCH_TRADING_HOUSE_ITEM_NAMES_COMPLETE, function(_, ...)
        self:OnNameMatchComplete(...)
    end)
    self.nameSearchClearButton = itemNameSearchControl:GetNamedChild("Clear")
    self.nameSearchClearButton:SetEnabled(false)
    self.nameSearchClearButton:SetHandler("OnClicked", function()
        self:OnNameSearchClearButtonClicked()
    end)

    self.nameSearchAutoComplete = ZO_TradingHouseNameSearchAutoComplete:New(itemNameSearchAutoCompleteControl, self.nameSearchEdit)

    TRADING_HOUSE_SEARCH:RegisterCallback("OnSearchCriteriaChanged", function()
        if not IsInGamepadPreferredMode() then
            self:MarkFiltersDirty()
        end
    end)
end

function ZO_TradingHouseNameSearchFeature_Keyboard:OnNameSearchEditTextChanged()
    self.searchText = self.nameSearchEdit:GetText()

    if not self:IsSearchTextLongEnough() then
        self.nameSearchAutoComplete:Hide()
    end

    self.nameSearchClearButton:SetEnabled(self.searchText ~= "")

    TRADING_HOUSE_SEARCH:HandleSearchCriteriaChanged(self)
end

function ZO_TradingHouseNameSearchFeature_Keyboard:OnNameSearchClearButtonClicked()
    self.nameSearchEdit:SetText("")
end

function ZO_TradingHouseNameSearchFeature_Keyboard:OnNameMatchComplete(nameMatchId, numResults, backgroundDurationMS)
    ZO_TradingHouseNameSearchFeature_Shared.OnNameMatchComplete(self, nameMatchId, numResults)
    if nameMatchId == self.completedItemNameMatchId then
        self.nameSearchAutoComplete:ShowListForNameSearch(nameMatchId, numResults)
    end
end
