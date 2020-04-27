ZO_MAP_ANTIQUITY_KEYBOARD_ENTRY_HEIGHT = 60
ZO_MAP_ANTIQUITY_KEYBOARD_CATEGORY_HEIGHT = 32

local ANTIQUITY_ENTRY = 1
local ANTIQUITY_HEADER = 2

ZO_MapAntiquities_Keyboard = ZO_MapAntiquities_Shared:Subclass()

function ZO_MapAntiquities_Keyboard:New(...)
    return ZO_MapAntiquities_Shared.New(self,...)
end

function ZO_MapAntiquities_Keyboard:Initialize(control)
    ZO_MapAntiquities_Shared.Initialize(self, control, ZO_FadeSceneFragment)
    self:SetNoItemsLabelControl(control:GetNamedChild("NoItemsLabel"))
end

function ZO_MapAntiquities_Keyboard:InitializeList(control)
    self.list = control:GetNamedChild("List")

    local function SetupAntiquity(entryControl, entryData)
        local antiquityData = entryData.antiquityData
        entryControl.antiquityData = antiquityData

        if not entryControl.progressIconMetaPool then
            entryControl.progressIconMetaPool = ZO_MetaPool:New(self.progressIconControlPool)
        end

        entryControl.nameLabel:SetText(antiquityData:GetColorizedFormattedName())
        entryControl.trackedIcon:SetHidden(not entryData.isTracked)

        local numGoalsAchieved = antiquityData:GetNumGoalsAchieved()

        local previousIcon
        local totalNumGoals = antiquityData:GetTotalNumGoals()
        for goalIndex = 1, totalNumGoals do
            local iconControl = entryControl.progressIconMetaPool:AcquireObject()
            iconControl:SetParent(entryControl)

            if numGoalsAchieved >= goalIndex then
                iconControl:SetTexture("EsoUI/Art/Antiquities/digsite_complete.dds")
            else
                iconControl:SetTexture("EsoUI/Art/Antiquities/digsite_unknown.dds")
            end
            if previousIcon then
                iconControl:SetAnchor(TOPLEFT, previousIcon, TOPRIGHT, 2)
            else
                iconControl:SetAnchor(TOPLEFT, entryControl.nameLabel, BOTTOMLEFT, 0, 2)
            end
            previousIcon = iconControl
        end
    end

    local function ResetAntiquity(entryControl)
        ZO_ObjectPool_DefaultResetControl(entryControl)
        entryControl.antiquityData = nil
        entryControl.progressIconMetaPool:ReleaseAllObjects()
    end

    local NO_HIDE_CALLBACK = nil
    local NO_SELECT_SOUND = nil
    ZO_ScrollList_AddDataType(self.list, ANTIQUITY_ENTRY, "ZO_AntiquityMapEntry_Keyboard", ZO_MAP_ANTIQUITY_KEYBOARD_ENTRY_HEIGHT, SetupAntiquity, NO_HIDE_CALLBACK, NO_SELECT_SOUND, ResetAntiquity)

    local function SetupHeader(headerControl, data)
        headerControl.label:SetText(data.text)
    end

    ZO_ScrollList_AddDataType(self.list, ANTIQUITY_HEADER, "ZO_AntiquityMapHeader_Keyboard", ZO_MAP_ANTIQUITY_KEYBOARD_CATEGORY_HEIGHT, SetupHeader)

    ZO_ScrollList_EnableHighlight(self.list, "ZO_TallListHighlight")
end

function ZO_MapAntiquities_Keyboard:SetListEnabled(enabled)
    ZO_MapAntiquities_Shared.SetListEnabled(self, enabled)

    ZO_ScrollList_RefreshVisible(self.list)
end

function ZO_MapAntiquities_Keyboard:RefreshList()
    ZO_MapAntiquities_Shared.RefreshList(self)

    ZO_ScrollList_Clear(self.list)
    local scrollData = ZO_ScrollList_GetDataList(self.list)

    local antiquityEntries = self:GetSortedAntiquityEntries()

    local lastAntiquityCategory

    for i, antiquityEntry in ipairs(antiquityEntries) do
        if lastAntiquityCategory ~= antiquityEntry.antiquityCategory then
            local dataEntry = ZO_ScrollList_CreateDataEntry(ANTIQUITY_HEADER, { text = GetString(ZO_MAP_ANTIQUITY_CATEGORY_TO_HEADER_STRING[antiquityEntry.antiquityCategory]) })
            table.insert(scrollData, dataEntry)
            lastAntiquityCategory = antiquityEntry.antiquityCategory
        end

        local dataEntry = ZO_ScrollList_CreateDataEntry(ANTIQUITY_ENTRY, antiquityEntry)
        table.insert(scrollData, dataEntry)
    end

    ZO_ScrollList_Commit(self.list)
end

function ZO_MapAntiquities_Keyboard:AntiquityMapEntryClicked(control, button)
    if WORLD_MAP_MANAGER:IsInMode(MAP_MODE_DIG_SITES) then
        return
    end

    -- primary action is to track the selected antiquity and secondry is to scry
    -- If you left-click on an antiquity that isn't in progress, show the right-click
    -- context menu so it's easy to see what options there are
    local antiquityData = control.antiquityData
    local antiquityIsInProgress = antiquityData:IsInProgress()
    local antiquityIsTracked = antiquityData:IsTracked()
    if button == MOUSE_BUTTON_INDEX_LEFT and antiquityIsInProgress then
        local antiquityId = antiquityData:GetId()
        if not antiquityIsTracked then
            SetTrackedAntiquityId(antiquityId)
        end
        WORLD_MAP_MANAGER:ShowAntiquityOnMap(antiquityId)
    elseif button == MOUSE_BUTTON_INDEX_RIGHT or (button == MOUSE_BUTTON_INDEX_LEFT and not antiquityIsInProgress) then
        ClearMenu()
        local canTrackAntiquity = antiquityIsInProgress and not antiquityIsTracked
        if canTrackAntiquity then
            AddMenuItem(GetString(SI_WORLD_MAP_ANTIQUITIES_TRACK), function()
                local antiquityId = antiquityData:GetId()
                SetTrackedAntiquityId(antiquityId)
                WORLD_MAP_MANAGER:ShowAntiquityOnMap(antiquityId)
            end)
        end

        if antiquityData:CanScry() then
            AddMenuItem(GetString(SI_ANTIQUITY_SCRY), function()
                SCENE_MANAGER:ShowBaseScene()
                ScryForAntiquity(antiquityData:GetId())
            end)
        end

        if antiquityIsInProgress then
            AddMenuItem(GetString(SI_ANTIQUITY_ABANDON), function()
                ZO_Dialogs_ShowDialog("CONFIRM_ABANDON_ANTIQUITY_SCRYING_PROGRESS", { antiquityId = antiquityData:GetId(), })
            end)
        end
        ShowMenu(control)
    end
end

function ZO_MapAntiquities_Keyboard:AntiquityMapEntryMouseEnter(control)
    ZO_ScrollList_MouseEnter(self.list, control)
end

function ZO_MapAntiquities_Keyboard:AntiquityMapEntryMouseExit(control)
    ZO_ScrollList_MouseExit(self.list, control)
end

-- Global XML functions

function ZO_MapAntiquities_Keyboard_OnMouseUp(control, button, upInside)
    if upInside then
        WORLD_MAP_ANTIQUITIES_KEYBOARD:AntiquityMapEntryClicked(control, button)
    end
end

function ZO_MapAntiquities_Keyboard_OnMouseEnter(control)
    WORLD_MAP_ANTIQUITIES_KEYBOARD:AntiquityMapEntryMouseEnter(control)
end

function ZO_MapAntiquities_Keyboard_OnMouseExit(control)
    WORLD_MAP_ANTIQUITIES_KEYBOARD:AntiquityMapEntryMouseExit(control)
end

function ZO_MapAntiquities_Keyboard_OnInitialized(self)
    WORLD_MAP_ANTIQUITIES_KEYBOARD = ZO_MapAntiquities_Keyboard:New(self)
end