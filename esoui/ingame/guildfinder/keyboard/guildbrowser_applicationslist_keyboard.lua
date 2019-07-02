------------------
-- Guild Finder --
------------------

ZO_GuildBrowser_ApplicationsList_Keyboard = ZO_Object.MultiSubclass(ZO_GuildBrowser_Applications_Shared, ZO_GuildFinder_ApplicationsList_Keyboard)

function ZO_GuildBrowser_ApplicationsList_Keyboard:New(...)
    return ZO_GuildFinder_ApplicationsList_Keyboard.New(self, ...)
end

function ZO_GuildBrowser_ApplicationsList_Keyboard:Initialize(control)
    self.entryTemplate = "ZO_GuildBrowser_Application_Row_Keyboard"

    ZO_GuildBrowser_Applications_Shared.Initialize(self, control)
    ZO_GuildFinder_ApplicationsList_Keyboard.Initialize(self, control)

    self:SetEmptyText(GetString(SI_GUILD_BROWSER_APPLICATIONS_EMPTY_LIST_TEXT))

    self.sortFunction = function(listEntry1, listEntry2) return self:ComparePlayerApplications(listEntry1, listEntry2) end
    self.sortHeaderGroup:SelectHeaderByKey("durationS")
end

function ZO_GuildBrowser_ApplicationsList_Keyboard:BuildMasterList()
    self.currentApplications = GUILD_BROWSER_MANAGER:GetCurrentApplicationsList()
end

function ZO_GuildBrowser_ApplicationsList_Keyboard:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, data in ipairs(self.currentApplications) do
        table.insert(scrollData, ZO_ScrollList_CreateDataEntry(ZO_GUILD_FINDER_APPLICATION_ENTRY_TYPE, data))
    end
end

function ZO_GuildBrowser_ApplicationsList_Keyboard:ComparePlayerApplications(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, ZO_GUILD_BROWSER_APPLICATIONS_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_GuildBrowser_ApplicationsList_Keyboard:SetupRow(control, data)
    ZO_GuildBrowser_Applications_Shared.SetupRow(self, control, data)
end

-- XML Functions
-----------------

function ZO_GuildBrowser_ApplicationsList_Row_OnMouseEnter(control)
    GUILD_BROWSER_APPLICATIONS_KEYBOARD:GetSubcategoryManager(ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE):Row_OnMouseEnter(control)
end

function ZO_GuildBrowser_ApplicationsList_Row_OnMouseExit(control)
    GUILD_BROWSER_APPLICATIONS_KEYBOARD:GetSubcategoryManager(ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE):Row_OnMouseExit(control)
end

function ZO_GuildBrowser_ApplicationsList_Keyboard_OnInitialized(control)
    GUILD_BROWSER_APPLICATIONS_KEYBOARD:SetSubcategoryManager(ZO_GUILD_BROWSER_APPLICATIONS_SUBCATEGORY_ACTIVE, ZO_GuildBrowser_ApplicationsList_Keyboard:New(control))
end

function ZO_GuildBrowser_ApplicationsList_Row_OnRescindClick(control)
    local guildInfo = ZO_AllianceIconNameFormatter(control.dataEntry.data.alliance, control.dataEntry.data.guildName)
    ZO_Dialogs_ShowDialog("GUILD_FINDER_RESCIND_APPLICATION", control.dataEntry.data, { mainTextParams = { ZO_WHITE:Colorize(guildInfo) } })
end