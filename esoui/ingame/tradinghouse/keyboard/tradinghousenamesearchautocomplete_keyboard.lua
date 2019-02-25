ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_ENTRY_HEIGHT = 28
ZO_TRADING_HOUSE_NAME_SEARCH_MAX_ENTRIES = 22
ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_MAX_HEIGHT = ZO_TRADING_HOUSE_NAME_SEARCH_MAX_ENTRIES * ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_ENTRY_HEIGHT
ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_WIDTH = 400

ZO_TradingHouseNameSearchAutoComplete = ZO_Object:Subclass()

function ZO_TradingHouseNameSearchAutoComplete:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_TradingHouseNameSearchAutoComplete:Initialize(menuListControl, editControl)
    self:InitializeMenuList(menuListControl)
    self:AttachToEditControl(editControl)
end

local MENU_ITEM_DATA = 1
function ZO_TradingHouseNameSearchAutoComplete:InitializeMenuList(menuListControl)
    self.menuList = menuListControl
    self.lastKeyboardSelectedData = nil

    local function SetupMenuItem(itemControl, itemData)
        local nameLabel = itemControl:GetNamedChild("Name")
        nameLabel:SetText(itemData.name)
        itemControl.itemData = itemData
        itemControl.autoCompleteObject = self
    end
    ZO_ScrollList_AddDataType(self.menuList, MENU_ITEM_DATA, "ZO_TradingHouseNameSearchAutoComplete_MenuItem", ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_ENTRY_HEIGHT, SetupMenuItem)

    ZO_ScrollList_EnableSelection(self.menuList, "ZO_SelectionHighlight")

    ZO_ScrollList_IgnoreMouseDownEditFocusLoss(self.menuList)
    ZO_ScrollList_SetUseFadeGradient(self.menuList, false)
end

function ZO_TradingHouseNameSearchAutoComplete:AttachToEditControl(editControl)
    ZO_PreHookHandler(editControl, "OnEnter", function()
        if self:IsMenuOpen() then
            self:SetEditTextFromSelectedData()
            self.editControl:LoseFocus()
        end
    end)

    ZO_PreHookHandler(editControl, "OnTab", function()
        if self:IsMenuOpen() then
            if not ZO_ScrollList_GetSelectedData(self.menuList) then
                ZO_ScrollList_TrySelectFirstData(self.menuList)
            end
            self:SetEditTextFromSelectedData()
            self.editControl:LoseFocus()
        end
    end)

    -- Because the mouse cursor can also change the currently selected item we need to track the "keyboard cursor" independently, which is represented using lastKeyboardSelectedData
    -- When performing a keyboard action, we apply the keyboard cursor immediately, then perform the action, and then save the state of the keyboard cursor for the next action.
    -- Then we can change the state of the actual selected item as much as we want and it will not affect this code path
    local function MoveKeyboardCursorUp()
        if self:IsMenuOpen() then
            ZO_ScrollList_SelectData(self.menuList, self.lastKeyboardSelectedData)

            if ZO_ScrollList_GetSelectedData(self.menuList) == nil then
                ZO_ScrollList_TrySelectLastData(self.menuList)
            else
                ZO_ScrollList_SelectPreviousData(self.menuList)
            end

            self.lastKeyboardSelectedData = ZO_ScrollList_GetSelectedData(self.menuList)
        end
    end
    ZO_PreHookHandler(editControl, "OnUpArrow", MoveKeyboardCursorUp)

    local function MoveKeyboardCursorDown()
        if self:IsMenuOpen() then
            ZO_ScrollList_SelectData(self.menuList, self.lastKeyboardSelectedData)

            if ZO_ScrollList_GetSelectedData(self.menuList) == nil then
                ZO_ScrollList_TrySelectFirstData(self.menuList)
            else
                ZO_ScrollList_SelectNextData(self.menuList)
            end

            self.lastKeyboardSelectedData = ZO_ScrollList_GetSelectedData(self.menuList)
        end
    end
    ZO_PreHookHandler(editControl, "OnDownArrow", MoveKeyboardCursorDown)

    local function HideMenu()
        self:Hide()
    end
    ZO_PreHookHandler(editControl, "OnFocusLost", HideMenu)
    ZO_PreHookHandler(editControl, "OnHide", HideMenu)
    
    self.editControl = editControl
end

function ZO_TradingHouseNameSearchAutoComplete:SetEditTextFromSelectedData()
    local selectedData = ZO_ScrollList_GetSelectedData(self.menuList)
    if selectedData then
        local exactSearchText = ZO_TradingHouseNameSearchFeature_Shared.MakeExactSearchText(selectedData.name)
        self.editControl:SetText(exactSearchText)
        --Move the cursor to the start to scroll the edit box back for long names so the player can see the start of the name instead of the end
        self.editControl:SetCursorPosition(0)
    end
end

function ZO_TradingHouseNameSearchAutoComplete:IsMenuOpen()
    return not self.menuList:IsHidden()
end

function ZO_TradingHouseNameSearchAutoComplete:Hide()
    self.menuList:SetHidden(true)
    self.menuList:SetHeight(0)
    ZO_ScrollList_ResetToTop(self.menuList)
end

function ZO_TradingHouseNameSearchAutoComplete:ShowListForNameSearch(nameMatchId, numResults)
    if numResults == 0 or not self.editControl:HasFocus() then
        self:Hide()
        return
    else
        self.menuList:SetHidden(false)
    end

    ZO_ScrollList_Clear(self.menuList)
    self.lastKeyboardSelectedData = nil
    local scrollData = ZO_ScrollList_GetDataList(self.menuList)

    for itemIndex = 1, numResults do
        local name, _ = GetMatchTradingHouseItemNamesResult(nameMatchId, itemIndex)
        local dataEntry = ZO_ScrollList_CreateDataEntry(MENU_ITEM_DATA, { name = name })
        scrollData[itemIndex] = dataEntry
    end

    ZO_ScrollList_SetHeight(self.menuList, zo_min(ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_MAX_HEIGHT, numResults * ZO_TRADING_HOUSE_NAME_SEARCH_AUTOCOMPLETE_ENTRY_HEIGHT))
    ZO_ScrollList_Commit(self.menuList)
end

function ZO_TradingHouseNameSearchAutoComplete:OnItemClicked(menuItemControl)
    ZO_ScrollList_SelectData(self.menuList, menuItemControl.itemData)
    self:SetEditTextFromSelectedData()
    self.editControl:LoseFocus()
end

function ZO_TradingHouseNameSearchAutoComplete:OnItemMouseEnter(menuItemControl)
    -- Normally, scrollLists track what you're moused over using a highlight, but instead we use a selection. This is why we aren't calling the usual ZO_ScrollList_MouseEnter functions
    ZO_ScrollList_SelectData(self.menuList, menuItemControl.itemData)
end

function ZO_TradingHouseNameSearchAutoComplete:OnItemMouseExit(menuItemControl)
    ZO_ScrollList_SelectData(self.menuList, self.lastKeyboardSelectedData)
end

-- XML Globals
function ZO_TradingHouseNameSearchAutoComplete_MenuItem_OnMouseClick(menuItemControl)
    local autoComplete = menuItemControl.autoCompleteObject
    autoComplete:OnItemClicked(menuItemControl)
end

function ZO_TradingHouseNameSearchAutoComplete_MenuItem_OnMouseEnter(menuItemControl)
    local autoComplete = menuItemControl.autoCompleteObject
    autoComplete:OnItemMouseEnter(menuItemControl)
end

function ZO_TradingHouseNameSearchAutoComplete_MenuItem_OnMouseExit(menuItemControl)
    local autoComplete = menuItemControl.autoCompleteObject
    autoComplete:OnItemMouseExit(menuItemControl)
end
