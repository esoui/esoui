IGNORE_DATA = 1
IGNORE_LIST_ENTRY_SORT_KEYS =
{
    ["displayName"] = { },
}

ZO_IgnoreList = ZO_SocialManager:Subclass()

local EVENT_NAMESPACE = "IgnoreList"

function ZO_IgnoreList:New()
    local manager = ZO_SocialManager.New(self)
    ZO_IgnoreList.Initialize(manager)
    return manager
end

function ZO_IgnoreList:Initialize()

    self.noteEditedFunction = function(displayName, newNote)
        for i = 1, GetNumIgnored() do
            local curDisplayName, note = GetIgnoredInfo(i)
            if(displayName == curDisplayName) then
                SetIgnoreNote(i, newNote)
                break
            end
        end
    end

    self:BuildMasterList()

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_SOCIAL_DATA_LOADED, function() self:OnSocialDataLoaded() end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_IGNORE_ADDED, function(_, displayName) self:OnIgnoreAdded(displayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_IGNORE_REMOVED, function(_, displayName) self:OnIgnoreRemoved(displayName) end)
    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_IGNORE_NOTE_UPDATED, function(_, displayName, note) self:OnIgnoreNoteUpdated(displayName, note) end)
end

function ZO_IgnoreList:SetupEntry(control, data, selected)
    control.displayName = data.displayName

    GetControl(control, "DisplayName"):SetText(ZO_FormatUserFacingDisplayName(data.displayName))

    local note = GetControl(control, "Note")
    if note then
        note:SetHidden(data.note == "")
    end
end

function ZO_IgnoreList:BuildMasterList()
    ZO_ClearNumericallyIndexedTable(self.masterList)
    local numIgnored = GetNumIgnored()
    for i = 1, numIgnored do
        local displayName, note = GetIgnoredInfo(i)
        local ignoreListEntry = {
            displayName = displayName,
            note = note,
            type = SOCIAL_NAME_SEARCH,
            ignoreIndex = i,
        }
        self.masterList[i] = ignoreListEntry
    end
end

function ZO_IgnoreList:GetNoteEditedFunction()
    return self.noteEditedFunction
end

--Events
------------

function ZO_IgnoreList:OnSocialDataLoaded() 
    self:RefreshData()
end

function ZO_IgnoreList:OnIgnoreAdded(displayName) 
    self:RefreshData()
end

function ZO_IgnoreList:OnIgnoreRemoved(displayName)
    self:RefreshData()
end

function ZO_IgnoreList:OnIgnoreNoteUpdated(displayName, note) 
    self:RefreshData()
end

-- A singleton will be used by both keyboard and gamepad screens
IGNORE_LIST_MANAGER = ZO_IgnoreList:New()