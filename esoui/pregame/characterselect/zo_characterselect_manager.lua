local PRIORITY_DEFAULT = 1
local PRIORITY_MOST_RECENT_CHARACTER = 2
local PRIORITY_PLAYER_CHOSEN = 3

ZO_CharacterSelect_Manager = ZO_CallbackObject:Subclass()

function ZO_CharacterSelect_Manager:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_CharacterSelect_Manager:Initialize()
    self.characterDataList = {}
    self.bestSelectionData = nil
    self.bestSelectionIndex = nil
    self.accountChampionPoints = 0
    self.playerSelectedCharacterId = nil
    self.bestSelectionPriority = 0
    self.mostRecentCharId = nil
    self.autoShowIndex = nil

    self:RegisterForEvents()

    local function OnSavedVarsReady(savedVars)
        self.savedVars = savedVars

        --- Character List depends on Event Announcements on Gamepad so Event Announcements must be called first when they're both ready
        if self.eventAnnouncementDataReady then
            self:PopulateEventAnnouncements()
            self.eventAnnouncementDataReady = nil
        end

        if self.pendingCharacterListParams then
            self:OnCharacterListReceived(unpack(self.pendingCharacterListParams))
            self.pendingCharacterListParams = nil
        end

        self:FireCallbacks("OnSavedDataReady")
    end

    local defaults = { eventBannerLastSeenTimestamp = 0, }
    local VERSION = 1
    ZO_RegisterForSavedVars("CharacterSelect_Manager", VERSION, defaults, OnSavedVarsReady)
end

function ZO_CharacterSelect_Manager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterSelect_Manager", EVENT_CHARACTER_LIST_RECEIVED, function(_, ...)
        if not self.savedVars then
            self.pendingCharacterListParams = { ... }
        else
            self:OnCharacterListReceived(...)
        end
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterSelect_Manager", EVENT_CHARACTER_RENAME_RESULT, function(_, ...)
        self:OnCharacterRenameResultReceived(...)
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterSelect_Manager", EVENT_CHARACTER_DELETED, function(_, ...)
        self:OnCharacterDeleted(...)
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterSelect_Manager", EVENT_EVENT_ANNOUNCEMENTS_RECEIVED, function(_, ...)
        self.autoShowIndex = nil

        if not self.savedVars then
            self.eventAnnouncementDataReady = true
        else
            self:PopulateEventAnnouncements()
            self:FireCallbacks("EventAnnouncementsReceived")
        end
    end)

    function OnEventAnnouncementsUpdated()
        self:PopulateEventAnnouncements()
        self:FireCallbacks("EventAnnouncementExpired")
    end

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterSelect_Manager", EVENT_EVENT_ANNOUNCEMENTS_UPDATED, OnEventAnnouncementsUpdated)
end

function ZO_CharacterSelect_Manager:IsSavedDataReady()
    return self.savedVars ~= nil
end

function ZO_CharacterSelect_Manager:PopulateEventAnnouncements()
    self.eventAnnouncements = {}
    if self.savedVars then
        self.autoShowIndex = nil
        local numEventAnnouncements = GetNumEventAnnouncements()
        for i = 1, numEventAnnouncements do
            local eventStartTime = GetEventAnnouncementStartTimeByIndex(i)
            local data =
            {
                index = i,
                name = GetEventAnnouncementNameByIndex(i),
                description = GetEventAnnouncementDescriptionByIndex(i),
                image = GetEventAnnouncementPregameImageByIndex(i),
                startTime = eventStartTime,
                remainingTime = GetEventAnnouncementRemainingTimeByIndex(i),
            }

            table.insert(self.eventAnnouncements, data)

            if eventStartTime > self.savedVars.eventBannerLastSeenTimestamp and not self.autoShowIndex then
                self.autoShowIndex = i
            end
        end
    end
end

function ZO_CharacterSelect_Manager:UpdateLastSeenTimestamp()
    if self.savedVars then
        self.savedVars.eventBannerLastSeenTimestamp = GetTimeStamp()
        self.autoShowIndex = nil
        for i = 1, self:GetNumEventAnnouncements() do
            local data = self:GetEventAnnouncementDataByIndex(i)
            if data.startTime > self.savedVars.eventBannerLastSeenTimestamp and not self.autoShowIndex then
                self.autoShowIndex = i
            end
        end
    end
end

function ZO_CharacterSelect_Manager:GetNumEventAnnouncements()
    return self.eventAnnouncements and #self.eventAnnouncements or 0
end

function ZO_CharacterSelect_Manager:GetEventAnnouncementDataByIndex(index)
    return self.eventAnnouncements and self.eventAnnouncements[index]
end

function ZO_CharacterSelect_Manager:GetEventAnnouncementAutoShowIndex()
    return self.autoShowIndex
end

function ZO_CharacterSelect_Manager:ClearEventAnnouncementAutoShowIndex()
    self.autoShowIndex = nil
end

function ZO_CharacterSelect_Manager:GetEventAnnouncementRemainingTimeByIndex(index)
    local eventAnnouncementData = self.eventAnnouncements and self.eventAnnouncements[index]
    local remainingTime = GetEventAnnouncementRemainingTimeByIndex(index)
    if eventAnnouncementData then
        eventAnnouncementData.remainingTime = remainingTime
    end

    return remainingTime
end

function ZO_CharacterSelect_Manager:GetCharacterDataList()
    return self.characterDataList
end

function ZO_CharacterSelect_Manager:GetDataForCharacterId(charId)
    for _, dataEntry in ipairs(self.characterDataList) do
        if AreId64sEqual(dataEntry.id, charId) then
            return dataEntry
        end
    end
end

do
    local function CompareCharacterDataObjects(left, right)
        if left.order == right.order then
            return left.index < right.index
        elseif left.order == 0 then -- orders of 0 must always be sorted to the bottom
            return false
        elseif right.order == 0 then -- orders of 0 must always be sorted to the bottom
            return true
        else
            return left.order < right.order
        end
    end
    function ZO_CharacterSelect_Manager:SortCharacterDataList()
        table.sort(self.characterDataList, CompareCharacterDataObjects)
    end
end

function ZO_CharacterSelect_Manager:SetupInitialOrder()
    for index, characterData in ipairs(self.characterDataList) do
        characterData.order = index
    end
end

function ZO_CharacterSelect_Manager:FindCharacterWithOrder(order)
    for _, characterData in ipairs(self.characterDataList) do
        if characterData.order == order then
            return characterData
        end
    end

    return nil
end

function ZO_CharacterSelect_Manager:SaveCharacterOrder()
    for _, characterData in ipairs(self.characterDataList) do
        ChangeCharacterOrder(characterData.index, characterData.order)
    end
end

function ZO_CharacterSelect_Manager:SwapCharacterOrderUp(fromOrder)
    local toOrder = fromOrder - 1
    local fromCharacterData = self.characterDataList[fromOrder]
    local toCharacterData = self.characterDataList[toOrder]
    if toCharacterData then
        fromCharacterData.order = toOrder
        toCharacterData.order = fromOrder
        self:SaveCharacterOrder()
        self:SortCharacterDataList()
        self:FireCallbacks("CharacterOrderChanged", fromCharacterData)
        self:SetPlayerSelectedCharacter(fromCharacterData)
    end
end

function ZO_CharacterSelect_Manager:SwapCharacterOrderDown(fromOrder)
    local toOrder = fromOrder + 1
    local fromCharacterData = self.characterDataList[fromOrder]
    local toCharacterData = self.characterDataList[toOrder]
    if toCharacterData then
        fromCharacterData.order = toOrder
        toCharacterData.order = fromOrder
        self:SaveCharacterOrder()
        self:SortCharacterDataList()
        self:FireCallbacks("CharacterOrderChanged", fromCharacterData)
        self:SetPlayerSelectedCharacter(fromCharacterData)
    end
end

function ZO_CharacterSelect_Manager:ChangeCharacterOrders(startingOrder, endingOrder)
    if startingOrder == endingOrder then
        return
    end

    local currentCharacterData = self.characterDataList[startingOrder]
    local direction = endingOrder - startingOrder > 0 and 1 or -1
    local nextOrder = startingOrder 
    while nextOrder ~= endingOrder do
        nextOrder = nextOrder + direction
        local nextCharacterData = self.characterDataList[nextOrder]
        nextCharacterData.order = nextOrder - direction
    end
    currentCharacterData.order = endingOrder

    self:SaveCharacterOrder()
    self:SortCharacterDataList()
    self:FireCallbacks("CharacterOrderChanged", currentCharacterData)
    self:SetPlayerSelectedCharacter(currentCharacterData)
end

function ZO_CharacterSelect_Manager:GetBestSelectionData()
    return self.bestSelectionData
end

function ZO_CharacterSelect_Manager:GetBestSelectionIndex()
    return self.bestSelectionIndex
end

function ZO_CharacterSelect_Manager:GetAccountChampionPoints()
    return self.accountChampionPoints
end

function ZO_CharacterSelect_Manager:SetPlayerSelectedCharacter(characterData)
    self.playerSelectedCharacterId = characterData.id
    self:SetSelectedCharacter(characterData)
end

function ZO_CharacterSelect_Manager:SetSelectedCharacter(characterData)
    self.selectedCharacterData = characterData
    self:RefreshConstructedCharacter()
    self:FireCallbacks("SelectedCharacterUpdated", characterData)
end

function ZO_CharacterSelect_Manager:RefreshConstructedCharacter()
    if IsPregameCharacterConstructionReady() then
        SetSuppressCharacterChanges(true)
        if IsInGamepadPreferredMode() then
            GAMEPAD_CHARACTER_CREATE_MANAGER:GenerateRandomCharacter()
        else
            KEYBOARD_CHARACTER_CREATE_MANAGER:GenerateRandomCharacter()
        end
        SelectClothing(DRESSING_OPTION_STARTING_GEAR)

        SetSuppressCharacterChanges(false)
        local selectedCharacterData = self:GetSelectedCharacterData()
        if selectedCharacterData then
            SetCharacterManagerMode(CHARACTER_MODE_SELECTION)
            SelectCharacterToView(selectedCharacterData.index)
            -- Generating the random character for pregame may have changed the alliance color
            if ZO_RZCHROMA_EFFECTS then
                ZO_RZCHROMA_EFFECTS:SetAlliance(selectedCharacterData.alliance)
            end
        end
    end
end

function ZO_CharacterSelect_Manager:GetSelectedCharacterData()
    return self.selectedCharacterData
end

function ZO_CharacterSelect_Manager:AddCharacterToList(characterIndex)
    local name, gender, level, championPoints, class, race, alliance, id, locationId, order, needsRename = GetCharacterInfo(characterIndex)

    -- if one character has champion points, than the account has champion points
    -- also make sure that the account never loses champion points between characters
    if championPoints > 0  and self.accountChampionPoints < championPoints then
        self.accountChampionPoints = championPoints
    end

    -- Because of the way the messaging works, ensure this character doesn't already exist in the table.
    local characterData = self:GetDataForCharacterId(id)
    if characterData == nil then
        local characterIndex = #self.characterDataList + 1
        characterData =
        {
            name = name,
            gender = gender,
            level = level,
            championPoints = championPoints,
            class = class,
            race = race,
            alliance = alliance,
            id = id,
            location = locationId,
            needsRename = needsRename,
            index = characterIndex,
            order = order,
        }
        self.characterDataList[characterIndex] = characterData

        if self.bestSelectionPriority < PRIORITY_DEFAULT then
            self.bestSelectionPriority = PRIORITY_DEFAULT
            self.bestSelectionData = characterData
            self.bestSelectionIndex = i
        end

        if AreId64sEqual(self.playerSelectedCharacterId, id) then
            self.bestSelectionPriority = PRIORITY_PLAYER_CHOSEN
            self.bestSelectionData = characterData
            self.bestSelectionIndex = i
        end

        if AreId64sEqual(self.mostRecentCharId, id) then
            if self.bestSelectionPriority < PRIORITY_MOST_RECENT_CHARACTER then
                self.bestSelectionPriority = PRIORITY_MOST_RECENT_CHARACTER
                self.bestSelectionData = characterData
                self.bestSelectionIndex = i
            end
        end
    end
end

function ZO_CharacterSelect_Manager:OnCharacterListReceived(numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
    self.mostRecentCharId = mostRecentlyPlayedCharacterId
    self.bestSelectionPriority = 0
    self.accountChampionPoints = 0
    self.bestSelectionData = nil
    self:SetSelectedCharacter(nil)

    self.numCharacters = numCharacters
    self.maxCharacters = maxCharacters

    self.numCharacterDeletesRemaining = numCharacterDeletesRemaining
    self.maxCharacterDeletes = maxCharacterDeletes

    ZO_ClearNumericallyIndexedTable(self.characterDataList)

    for characterIndex = 1, numCharacters do
        self:AddCharacterToList(characterIndex)
    end

    self:SortCharacterDataList()
    self:SetupInitialOrder()
    self:FireCallbacks("CharacterListUpdated")
    self:SetSelectedCharacter(self:GetBestSelectionData())
end

function ZO_CharacterSelect_Manager:OnCharacterRenameResultReceived(characterId, result)
    local requestedName = self.characterRenameRequestedName
    local resultCallback = self.characterRenameResultCallback

    ZO_Dialogs_ReleaseAllDialogsOfName("CHARACTER_SELECT_CHARACTER_RENAMING")

    if result == NAME_RULE_NO_ERROR then
        ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_RENAME_CHARACTER_SUCCESS", { callback = resultCallback }, { mainTextParams = { requestedName } })
    else
        local titleText
        local errorMessageText

        if result == NAME_RULE_DUPLICATE_NAME then
            titleText = GetString(SI_RENAME_CHARACTER_NAME_IN_USE_ERROR_HEADER)
            errorMessageText = zo_strformat(SI_RENAME_CHARACTER_NAME_IN_USE_ERROR_BODY, requestedName)
        else
            titleText = GetString(SI_RENAME_CHARACTER_GENERIC_ERROR_HEADER)
            errorMessageText = GetString("SI_NAMINGERROR", result)
        end

        local dialogParams = {
            titleParams = { titleText },
            mainTextParams = { errorMessageText },
        }

        ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_RENAME_CHARACTER_ERROR", { callback = resultCallback }, dialogParams)
    end
end

function ZO_CharacterSelect_Manager:AttemptCharacterRename(characterId, requestedName, resultCallback)
    self.characterRenameRequestedName = requestedName
    self.characterRenameResultCallback = resultCallback
    AttemptCharacterRename(characterId, requestedName)

    -- Show a loading dialog in its place until the rename request finishes
    ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_CHARACTER_RENAMING")
end

function ZO_CharacterSelect_Manager:OnCharacterDeleted(characterId)
    ZO_Dialogs_ReleaseAllDialogsOfName("CHARACTER_SELECT_DELETING")
    -- Request a new character list from the server, presumably without the character we just deleted
    -- Once that's loaded the CharacterListUpdated callback will update the local state and potentially jump to character create if there are no characters to select from.
    RequestCharacterList()
end

function ZO_CharacterSelect_Manager:AttemptCharacterDelete(characterId)
    TrySaveCharacterListOrder()
    DeleteCharacter(characterId)

    -- Show a loading dialog in its place until the rename request finishes
    ZO_Dialogs_ShowPlatformDialog("CHARACTER_SELECT_DELETING")
end

function ZO_CharacterSelect_Manager:GetNumCharacters()
    return self.numCharacters
end

function ZO_CharacterSelect_Manager:GetMaxCharacters()
    return self.maxCharacters
end

function ZO_CharacterSelect_Manager:CanCreateNewCharacters()
    return self.numCharacters < self.maxCharacters
end

function ZO_CharacterSelect_Manager:CanShowAdditionalSlotsInfo()
    local currentUsedSlots = GetNumCharacters()
    local ownedCharacterSlots = GetNumOwnedCharacterSlots()

    return ownedCharacterSlots <= currentUsedSlots and self:GetAdditionalSlotsRemaining() > 0
end

function ZO_CharacterSelect_Manager:GetAdditionalSlotsRemaining()
    local ownedCharacterSlots = GetNumOwnedCharacterSlots()
    local maxSlotsAvailable = GetNumMaxCharacterSlotsAvailable()

    return maxSlotsAvailable - ownedCharacterSlots
end

function ZO_CharacterSelect_Manager:GetNumCharacterDeletesRemaining()
    return self.numCharacterDeletesRemaining
end

function ZO_CharacterSelect_Manager:AreAllCharacterDeletesRemaining()
    local maxCharacterDeletes = GetMaxCharacterDeletes()
    return self.numCharacterDeletesRemaining == maxCharacterDeletes
end

CHARACTER_SELECT_MANAGER = ZO_CharacterSelect_Manager:New()

function ZO_CharacterSelect_Manager_GetFormattedCharacterName(characterData)
    return zo_strformat(SI_CHARACTER_SELECT_NAME, characterData.name)
end
