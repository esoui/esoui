ZO_TradingHouseSearchHistory_Keyboard = ZO_CallbackObject:Subclass()

function ZO_TradingHouseSearchHistory_Keyboard:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseSearchHistory_Keyboard:Initialize(control)
    self.control = control
    self.history = {}

    self:InitializeList()

    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT = ZO_FadeSceneFragment:New(control)
    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            SCENE_MANAGER:AddFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
        elseif newState == SCENE_FRAGMENT_HIDING then
            SCENE_MANAGER:RemoveFragment(MEDIUM_LEFT_PANEL_BG_FRAGMENT)
        end
    end)

    TRADING_HOUSE_SCENE:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:RefreshHistory()
        end
    end)

    TRADING_HOUSE_SEARCH_HISTORY_MANAGER:RegisterCallback("HistoryUpdated", function()
        if TRADING_HOUSE_SCENE:IsShowing() then
            self:RefreshHistory()
        end
    end)
end

local SEARCH_HISTORY_ROW_DATA = 1
function ZO_TradingHouseSearchHistory_Keyboard:InitializeList()
    self.list = self.control:GetNamedChild("List")
    self.noHistoryRow = self.control:GetNamedChild("NoHistoryRow")

    local function SetupHistoryRow(rowControl, rowData)
        if not rowData.formattedSearchTableDescription then
            rowData.formattedSearchTableDescription = TRADING_HOUSE_SEARCH:GenerateSearchTableShortDescription(rowData.searchTable)
        end
        rowControl:GetNamedChild("Description"):SetText(rowData.formattedSearchTableDescription)
        rowControl.rowData = rowData
    end
    ZO_ScrollList_AddDataType(self.list, SEARCH_HISTORY_ROW_DATA, "ZO_TradingHouseSearchHistoryRow_Keyboard", 60, SetupHistoryRow)

    ZO_ScrollList_EnableHighlight(self.list, "ZO_TallListHighlight")
end

function ZO_TradingHouseSearchHistory_Keyboard:RefreshHistory()
    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    for _, searchEntry in TRADING_HOUSE_SEARCH_HISTORY_MANAGER:SearchEntryIterator() do
        local historyData = {searchTable = searchEntry.searchTable, formattedSearchTableDescription = formattedString}
        local dataEntry = ZO_ScrollList_CreateDataEntry(SEARCH_HISTORY_ROW_DATA, historyData)
        table.insert(scrollData, dataEntry)
    end

    ZO_ScrollList_Commit(self.list)

    self.noHistoryRow:SetHidden(#scrollData ~= 0)
end

function ZO_TradingHouseSearchHistory_Keyboard:GetMouseOverSearchTable()
    local rowControl = ZO_ScrollList_GetMouseOverControl(self.list)
    if rowControl then
        return rowControl.rowData.searchTable
    end
    return nil
end

function ZO_TradingHouseSearchHistory_Keyboard_OnInitialized(control)
    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD = ZO_TradingHouseSearchHistory_Keyboard:New(control)
end

function ZO_TradingHouseSearchHistoryRow_Keyboard_OnMouseClick(rowControl)
    TRADING_HOUSE_SEARCH:LoadSearchTable(rowControl.rowData.searchTable)
    TRADING_HOUSE_SEARCH:DoSearch()
    -- Jump to top of list, where the current search now resides
    ZO_ScrollList_ResetToTop(TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD.list)
end

function ZO_TradingHouseSearchHistoryRow_Keyboard_OnMouseEnter(rowControl)
    ZO_ScrollList_MouseEnter(TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD.list, rowControl)

    InitializeTooltip(InformationTooltip, rowControl, TOPLEFT, 0, 0, TOPRIGHT)
    SetTooltipText(InformationTooltip, TRADING_HOUSE_SEARCH:GenerateSearchTableDescription(rowControl.rowData.searchTable))
    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD:FireCallbacks("MouseOverRowChanged")
end

function ZO_TradingHouseSearchHistoryRow_Keyboard_OnMouseExit(rowControl)
    ZO_ScrollList_MouseExit(TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD.list, rowControl)
    ClearTooltip(InformationTooltip)
    TRADING_HOUSE_SEARCH_HISTORY_KEYBOARD:FireCallbacks("MouseOverRowChanged")
end

