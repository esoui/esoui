
-----------------
-- Ignore Manager
-----------------

local ZO_KeyboardIgnoreListManager = ZO_SocialListKeyboard:Subclass()

function ZO_KeyboardIgnoreListManager:New(...)
    return ZO_SocialListKeyboard.New(self, ...)
end

function ZO_KeyboardIgnoreListManager:Initialize(control)
    ZO_SocialListKeyboard.Initialize(self, control)
    IGNORE_LIST_MANAGER:AddList(self)

    control:SetHandler("OnEffectivelyHidden", function() self:OnEffectivelyHidden() end)

    ZO_ScrollList_AddDataType(self.list, IGNORE_DATA, "ZO_IgnoreListRow", 30, function(control, data) self:SetupIgnoreEntry(control, data) end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

    self.sortFunction = function(listEntry1, listEntry2) return self:CompareIgnored(listEntry1, listEntry2) end
    self:SetEmptyText(GetString(SI_IGNORE_LIST_PANEL_NO_IGNORES_MESSAGE))
    self:SetAlternateRowBackgrounds(true)

    self.sortHeaderGroup:SelectHeaderByKey("displayName")

    IGNORE_LIST_SCENE = ZO_Scene:New("ignoreList", SCENE_MANAGER)
   
    IGNORE_LIST_SCENE:RegisterCallback("StateChange",  function(oldState, newState)
       if newState == SCENE_SHOWING then 
            self:PerformDeferredInitialization()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.staticKeybindStripDescriptor)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
       elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.staticKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
       end
    end)

    IGNORE_LIST_FRAGMENT = ZO_FadeSceneFragment:New(control)
    self:InitializeDirtyLogic(IGNORE_LIST_FRAGMENT)
end

function ZO_KeyboardIgnoreListManager:PerformDeferredInitialization()   
    if self.staticKeybindStripDescriptor ~= nil then return end
    self:RefreshData()
    self:InitializeKeybindDescriptors()
end

function ZO_KeyboardIgnoreListManager:InitializeKeybindDescriptors()
    self.staticKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,

        -- Add Ignore
        {
            name = GetString(SI_IGNORE_LIST_ADD_IGNORE),
            keybind = "UI_SHORTCUT_PRIMARY",

            callback = function()
                if(not ZO_Dialogs_IsShowing("ADD_IGNORE")) then
                    ZO_Dialogs_ShowDialog("ADD_IGNORE")
                end
            end,
        },
    }
    
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,

        -- Cancel Ignore
        {
            name = GetString(SI_IGNORE_LIST_REMOVE_IGNORE),
            keybind = "UI_SHORTCUT_NEGATIVE",
        
            callback = function()
                local data = ZO_ScrollList_GetData(self.mouseOverRow)
                RemoveIgnore(data.displayName)
            end,

            visible = function()
                if(self.mouseOverRow) then
                    return true
                end
                return false
            end
        },
    }
end

function ZO_KeyboardIgnoreListManager:FilterScrollList()
    local scrollData = ZO_ScrollList_GetDataList(self.list)
    ZO_ClearNumericallyIndexedTable(scrollData)
    
    local masterList = IGNORE_LIST_MANAGER:GetMasterList()
    for i = 1, #masterList do
        local ignoreListEntry = masterList[i]
        scrollData[i] = ZO_ScrollList_CreateDataEntry(IGNORE_DATA,  ignoreListEntry)
    end
end

function ZO_KeyboardIgnoreListManager:CompareIgnored(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, IGNORE_LIST_ENTRY_SORT_KEYS, self.currentSortOrder)
end

function ZO_KeyboardIgnoreListManager:BuildMasterList()
    -- The master list lives in the IGNORE_LIST_MANAGER and is built there
end

function ZO_KeyboardIgnoreListManager:SortScrollList()
    if(self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        table.sort(scrollData, self.sortFunction)
    end
end

function ZO_KeyboardIgnoreListManager:SetupIgnoreEntry(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    IGNORE_LIST_MANAGER:SetupEntry(control, data)
end

--Events
------------

local function GetNoteEditFunction(owner, displayName, callback)    
    return function()
        for i = 1, GetNumIgnored() do
            local curDisplayName, note = GetIgnoredInfo(i)
            if(displayName == curDisplayName) then
                ZO_Dialogs_ShowDialog("EDIT_NOTE", {displayName = displayName, note = note, changedCallback = callback})
                break
            end
        end
    end
end

function ZO_KeyboardIgnoreListManager:IgnoreListPanelRow_OnMouseUp(control, button, upInside)
    if(button == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
        ClearMenu()
        
        local data = ZO_ScrollList_GetData(control)
        if data then
            AddMenuItem(GetString(SI_SOCIAL_MENU_EDIT_NOTE), GetNoteEditFunction(self.control, data.displayName, IGNORE_LIST_MANAGER:GetNoteEditedFunction()))
            AddMenuItem(GetString(SI_IGNORE_MENU_REMOVE_IGNORE), function() RemoveIgnore(data.displayName) end)

            self:ShowMenu(control)
        end
    end
end

function ZO_KeyboardIgnoreListManager:IgnoreListPanelRowNote_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, data.note)

    self:EnterRow(control:GetParent())
end

function ZO_KeyboardIgnoreListManager:IgnoreListPanelRowNote_OnMouseExit(control)
    ClearTooltip(InformationTooltip)

    self:ExitRow(control:GetParent())
end

function ZO_KeyboardIgnoreListManager:IgnoreListPanelRowNote_OnClicked(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    if data then
        local displayName, note = GetIgnoredInfo(data.index)
        ZO_Dialogs_ShowDialog("EDIT_NOTE", {displayName = displayName, note = note, changedCallback = IGNORE_LIST_MANAGER:GetNoteEditedFunction()})
    end
end

function ZO_KeyboardIgnoreListManager:OnEffectivelyHidden()
    ZO_EditNoteDialog_Hide(self.control)
end

--Global XML Handlers
-----------------------

function ZO_IgnoreListRow_OnMouseEnter(control)
    IGNORE_LIST:Row_OnMouseEnter(control)
end

function ZO_IgnoreListRow_OnMouseExit(control)
    IGNORE_LIST:Row_OnMouseExit(control)
end

function ZO_IgnoreListRow_OnMouseUp(control, button, upInside)
    IGNORE_LIST:IgnoreListPanelRow_OnMouseUp(control, button, upInside)
end

function ZO_IgnoreListRowNote_OnMouseEnter(control)
    IGNORE_LIST:IgnoreListPanelRowNote_OnMouseEnter(control)
end

function ZO_IgnoreListRowNote_OnMouseExit(control)
    IGNORE_LIST:IgnoreListPanelRowNote_OnMouseExit(control)
end

function ZO_IgnoreListRowNote_OnClicked(control)
    IGNORE_LIST:IgnoreListPanelRowNote_OnClicked(control)
end

function ZO_IgnoreList_OnInitialized(self)
    IGNORE_LIST = ZO_KeyboardIgnoreListManager:New(self)
end
