------------------
-- Guild Finder --
------------------

ZO_GUILD_FINDER_APPLICATIONS_LIST_KEYBOARD_ROW_HEIGHT = 32

ZO_GuildFinder_ApplicationsList_Keyboard = ZO_Object.MultiSubclass(ZO_GuildFinder_Panel_Shared, ZO_SortFilterList)

function ZO_GuildFinder_ApplicationsList_Keyboard:New(...)
    return ZO_SortFilterList.New(self, ...)
end

function ZO_GuildFinder_ApplicationsList_Keyboard:Initialize(control)
    ZO_GuildFinder_Panel_Shared.Initialize(self, control)
    ZO_SortFilterList.Initialize(self, control)

    local function SetupRow(control, data)
        data.iconSize = 24
        self:SetupRow(control, data)
    end

    ZO_ScrollList_AddDataType(self.list, ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, self.entryTemplate, ZO_GUILD_FINDER_APPLICATIONS_KEYBOARD_ENTRY_HEIGHT, SetupRow)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
end

function ZO_GuildFinder_ApplicationsList_Keyboard:SortScrollList()
    if self.currentSortKey ~= nil and self.currentSortOrder ~= nil then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_GuildFinder_ApplicationsList_Keyboard:Row_OnMouseEnter(control)
    ZO_SortFilterList.Row_OnMouseEnter(self, control)
    GUILD_FINDER_MANAGER:ShowApplicationTooltipOnMouseEnter(control.dataEntry.data, control)
end

function ZO_GuildFinder_ApplicationsList_Keyboard:Row_OnMouseExit(control)
    ZO_SortFilterList.Row_OnMouseExit(self, control)
    GUILD_FINDER_MANAGER:HideApplicationTooltipOnMouseExit()
end

function ZO_GuildFinder_ApplicationsList_Keyboard:OnShowing()
    self:RefreshData()
end