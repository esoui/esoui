ZO_WorldMapChoiceDialog_Gamepad = ZO_Object:Subclass()

function ZO_WorldMapChoiceDialog_Gamepad:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_WorldMapChoiceDialog_Gamepad:Initialize()
    local dialogInfo =
    {
        setup = function(...) self:Setup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_WORLD_MAP_MAKE_A_CHOICE,
        },
        parametricList = {}, --we'll generate the entries on setup
        buttons =
        {
            -- Select Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                enabled = function(dialog)
                    return dialog.entryList:GetTargetData() ~= nil
                end,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    ZO_WorldMap_ChoosePinOption(targetData.pin, targetData.handler)
                end,
            },
            --Back
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
            },            
        },
    }

    ZO_Dialogs_RegisterCustomDialog("WORLD_MAP_CHOICE_GAMEPAD", dialogInfo)
end

--Pin Entry Creation
function ZO_WorldMapChoiceDialog_Gamepad:CreatePinEntryData(name, icon, pin, handler)
    local entryData = ZO_GamepadEntryData:New(name, icon)
    entryData.setup = ZO_SharedGamepadEntry_OnSetup
    entryData.pin = pin
    entryData.handler = handler
    entryData:SetFontScaleOnSelection(false)
    return entryData
end

--Travel Entries
do
    local function GetTravelPinNodeInfo(pin)
        if pin:IsFastTravelKeep() then
            local keepId = pin:GetFastTravelKeepId()
            return GetKeepName(keepId)
        elseif pin:IsKeepOrDistrict() then
            local keepId = pin:GetKeepId()
            return GetKeepName(keepId)
        elseif pin:IsFastTravelWayShrine() then
            local nodeIndex = pin:GetFastTravelNodeIndex()
            local _, name, _, _, icon = GetFastTravelNodeInfo(nodeIndex)
            return name, icon
        end
    end

    local function TravelPinHandlerSortFunction(firstPinHandlerInfo, secondPinHandlerInfo)
        local firstPin = firstPinHandlerInfo.pin
        local secondPin = secondPinHandlerInfo.pin
        local isFirstLocked = firstPin:IsLockedByLinkedCollectible()
        local isSecondLocked = secondPin:IsLockedByLinkedCollectible()

        if isFirstLocked ~= isSecondLocked then
            return isFirstLocked
        else
            local firstName = GetTravelPinNodeInfo(firstPin)
            local secondName = GetTravelPinNodeInfo(secondPin)
            return firstName < secondName
        end
    end

    local function TravelPinEnabledFunction(selectedData)
        local pin = selectedData.pin
        local travelCost, canTravel = pin:GetFastTravelCost()
        return canTravel
    end

    local HEADER_TYPES =
    {
        HEADER_TRAVEL = 1,
        HEADER_CROWN_STORE = 2,
        HEADER_UPGRADE_CHAPTER = 3,
    }

    local HEADER_STRINGS = 
    {
        [HEADER_TYPES.HEADER_TRAVEL] = GetString(SI_GAMEPAD_WORLD_MAP_TRAVEL),
        [HEADER_TYPES.HEADER_CROWN_STORE] = GetString(SI_WORLD_MAP_ACTION_GO_TO_CROWN_STORE),
        [HEADER_TYPES.HEADER_UPGRADE_CHAPTER] = GetString(SI_WORLD_MAP_ACTION_UPGRADE_CHAPTER),
    }

    function ZO_WorldMapChoiceDialog_Gamepad:AddTravelDialogItems(parametricListEntries, mouseOverPinHandlers)
        --Only create each header once
        local headersAdded = {}

        local travelPinHandlers = {}
        for _, pinHandlerInfo in ipairs(mouseOverPinHandlers) do
            local handler = pinHandlerInfo.handler
            local gamepadPinActionGroup = ZO_WorldMap_GetGamepadPinActionGroupForHandler(handler)
            if gamepadPinActionGroup == ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_FAST_TRAVEL then
                table.insert(travelPinHandlers, pinHandlerInfo)
            end
        end
        table.sort(travelPinHandlers, TravelPinHandlerSortFunction)

        for _, pinHandlerInfo in ipairs(travelPinHandlers) do
            local pin = pinHandlerInfo.pin
            local handler = pinHandlerInfo.handler

            local headerType = HEADER_TYPES.HEADER_TRAVEL
            if pin:IsLockedByLinkedCollectible() then
                headerType = pin:GetLinkedCollectibleType() == COLLECTIBLE_CATEGORY_TYPE_CHAPTER and HEADER_TYPES.HEADER_UPGRADE_CHAPTER or HEADER_TYPES.HEADER_CROWN_STORE
            end
            local name, icon = GetTravelPinNodeInfo(pin)

            local entryData = self:CreatePinEntryData(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), icon, pin, handler)
            if not TravelPinEnabledFunction(entryData) then
                entryData:SetIconTint(ZO_ERROR_COLOR, ZO_ERROR_COLOR)
            end

            local dialogListEntry = { entryData = entryData, template = "ZO_GamepadMenuEntryNoCapitalization" }
            if not headersAdded[headerType] then
                dialogListEntry.header = HEADER_STRINGS[headerType]
                headersAdded[headerType] = true
            end
            table.insert(parametricListEntries, dialogListEntry)
        end
    end
end

--Quest Entries
do
    local function QuestPinHandlersSortFunction(firstPinHandlerInfo, secondPinHandlerInfo)
        local firstPin = firstPinHandlerInfo.pin
        local secondPin = secondPinHandlerInfo.pin
        local firstQuestIndex = firstPin:GetQuestData()
        local secondQuestIndex = secondPin:GetQuestData()
        local firstName = GetJournalQuestName(firstQuestIndex)
        local secondName = GetJournalQuestName(secondQuestIndex)

        return firstName < secondName
    end

    function ZO_WorldMapChoiceDialog_Gamepad:AddQuestDialogItems(parametricListEntries, mouseOverPinHandlers)
        local header = GetString(SI_GAMEPAD_WORLD_MAP_SET_ACTIVE_QUEST)
            
        local questPinHandlers = {}
        for _, pinHandlerInfo in ipairs(mouseOverPinHandlers) do
            local gamepadPinActionGroup = ZO_WorldMap_GetGamepadPinActionGroupForHandler(pinHandlerInfo.handler)
            if gamepadPinActionGroup == ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_QUEST then                                 
                table.insert(questPinHandlers, pinHandlerInfo)
            end
        end
        table.sort(questPinHandlers, QuestPinHandlersSortFunction)

        for _, pinHandlerInfo in ipairs(questPinHandlers) do
            local pin = pinHandlerInfo.pin
            local questIndex = pin:GetQuestData()

            local questName = GetJournalQuestName(questIndex)
            local questLevel = GetJournalQuestLevel(questIndex)
            local questColor = GetColorDefForCon(GetCon(questLevel))
            local isAssisted = FOCUSED_QUEST_TRACKER:IsTrackTypeAssisted(TRACK_TYPE_QUEST, questIndex)
            local icon = isAssisted and CONSTANTS.FOCUSED_QUEST_ICON or nil

            local entryData = self:CreatePinEntryData(questName, icon, pin, pinHandlerInfo.handler)
            entryData:SetNameColors(questColor, questColor:Lerp(ZO_BLACK, 0.25))

            local dialogListEntry = { entryData = entryData, template = "ZO_GamepadMenuEntryNoCapitalization" }
            if header then
                dialogListEntry.header = header
                header = nil
            end
            table.insert(parametricListEntries, dialogListEntry)
        end
    end
end

--Respawn Entries
function ZO_WorldMapChoiceDialog_Gamepad:AddRespawnDialogItems(parametricListEntries, mouseOverPinHandlers)
    local header = GetString(SI_GAMEPAD_WORLD_MAP_TITLE_CHOOSE_REVIVE)

    for _, pinHandlerInfo in ipairs(mouseOverPinHandlers) do
        local handler = pinHandlerInfo.handler
        local gamepadPinActionGroup = ZO_WorldMap_GetGamepadPinActionGroupForHandler(handler)
        if gamepadPinActionGroup == ZO_WORLD_MAP_GAMEPAD_PIN_ACTION_GROUP_RESPAWN then
            local pin = pinHandlerInfo.pin

            local canRespawn = true
            if handler.isKeepRespawnHandler then
                local keepId = pin:GetKeepId()
                if not CanRespawnAtKeep(keepId) then
                    canRespawn = false
                end
            end

            if canRespawn then
                local entryData = self:CreatePinEntryData(handler.name, nil, pin, handler)
                local dialogListEntry = { entryData = entryData, template = "ZO_GamepadMenuEntryNoCapitalization" }
                if header then
                    dialogListEntry.header = header
                    header = nil
                end
                table.insert(parametricListEntries, dialogListEntry)
            end
        end
    end
end

--List Construction
function ZO_WorldMapChoiceDialog_Gamepad:BuildChoiceEntries(dialog, data)
    local parametricListEntries = dialog.info.parametricList
    local mouseOverPinHandlers = data.mouseOverPinHandlers

    ZO_ClearNumericallyIndexedTable(parametricListEntries)
        
    self:AddTravelDialogItems(parametricListEntries, mouseOverPinHandlers)
    self:AddQuestDialogItems(parametricListEntries, mouseOverPinHandlers)
    self:AddRespawnDialogItems(parametricListEntries, mouseOverPinHandlers)
end

function ZO_WorldMapChoiceDialog_Gamepad:Setup(dialog, data)
    self:BuildChoiceEntries(dialog, data)
    dialog:setupFunc()
end

--Events

function ZO_WorldMapChoiceDialog_Gamepad:OnPinRemovedFromMap(pin)
    if ZO_Dialogs_IsShowing("WORLD_MAP_CHOICE_GAMEPAD") then
        --A pin that we were showing in the dialog was just removed from the map.
        local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)
        local parametricListEntries = parametricDialog.info.parametricList
        local entryRemoved = false
        for i, dialogListEntry in ipairs(parametricListEntries) do
            if dialogListEntry.entryData.pin == pin then
                --if we are removing a header entry then migrate that header label to the next entry in the section if it exists
                if dialogListEntry.header then
                    local nextListEntry = parametricListEntries[i + 1]
                    --if it already has a header it is the start of the next section
                    if nextListEntry and not nextListEntry.header then
                        nextListEntry.header = dialogListEntry.header
                    end
                end
                table.remove(parametricListEntries, i)
                entryRemoved = true
                break
            end
        end

        if entryRemoved then
            if #parametricListEntries == 0 then
                ZO_Dialogs_ReleaseDialog("WORLD_MAP_CHOICE_GAMEPAD")
            else
                ZO_GenericParametricListGamepadDialogTemplate_RebuildEntryList(parametricDialog)
            end
        end
    end
end

WORLD_MAP_CHOICE_DIALOG_GAMEPAD = ZO_WorldMapChoiceDialog_Gamepad:New()