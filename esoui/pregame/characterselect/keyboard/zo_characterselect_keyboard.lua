local CHARACTER_DATA = 1
local addOnManager
local g_currentlySelectedCharacterData
local g_deletingCharacterIds = {}

local function GetDataForCharacterId(charId)
    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    for _, dataEntry in ipairs(dataList) do
        if(AreId64sEqual(dataEntry.data.id, charId)) then
            return dataEntry
        end
    end
end

local function UpdateSelectedCharacterData(data)
    if(data) then
        ZO_CharacterSelectSelectedName:SetText(zo_strformat(SI_CHARACTER_SELECT_NAME, data.name))
        ZO_CharacterSelectSelectedRace:SetText(zo_strformat(SI_CHARACTER_SELECT_RACE, GetRaceName(data.gender, data.race)))
        ZO_CharacterSelectSelectedLocation:SetText(zo_strformat(SI_CHARACTER_SELECT_LOCATION, GetLocationName(data.location)))
        ZO_CharacterSelectSelectedClassLevel:SetText(ZO_CharacterSelect_GetFormattedLevelRankAndClass(data))
    else
        ZO_CharacterSelectSelectedName:SetText("")
        ZO_CharacterSelectSelectedRace:SetText("")
        ZO_CharacterSelectSelectedLocation:SetText("")
        ZO_CharacterSelectSelectedClassLevel:SetText("")
    end
end

function ZO_CharacterSelect_DisableSelection(data)
    ZO_CharacterSelectLogin:SetState(BSTATE_DISABLED, true)
    UpdateSelectedCharacterData(data)
end

function ZO_CharacterSelect_EnableSelection(data)
    ZO_CharacterSelectLogin:SetState(BSTATE_NORMAL, false)
    UpdateSelectedCharacterData(data)
end

local function SetupCharacterEntry(control, data)
    local characterName = GetControl(control, "Name")
    local characterStatus = GetControl(control, "ClassLevel")
    local characterLocation = GetControl(control, "Location")
    local characterAlliance = GetControl(control, "Alliance")

    characterName:SetText(zo_strformat(SI_CHARACTER_SELECT_NAME, data.name))
    characterStatus:SetText(ZO_CharacterSelect_GetFormattedLevelRankAndClass(data))

    if(data.location ~= 0) then
        characterLocation:SetText(zo_strformat(SI_CHARACTER_SELECT_LOCATION, GetLocationName(data.location)))
    else
        characterLocation:SetText(GetString(SI_UNKNOWN_LOCATION))
    end

    local allianceTexture = ZO_GetAllianceIcon(data.alliance)
    if(allianceTexture) then
        characterAlliance:SetTexture(allianceTexture)
    end
end

local function SelectCharacter(characterData)
    ZO_ScrollList_SelectData(ZO_CharacterSelectScrollList, characterData)

    if(characterData.needsRename) then
        ZO_CharacterSelectLogin:SetText(GetString(SI_RENAME_CHARACTER))
    else
        ZO_CharacterSelectLogin:SetText(GetString(SI_LOGIN_CHARACTER))
    end
end

local function DoCharacterSelection(index)
    -- Get character select first random selection loaded in so not waiting for it
    -- when move to Create
    SetSuppressCharacterChanges(true)
    if(IsPregameCharacterConstructionReady()) then
        ZO_CharacterCreate_GenerateRandomCharacter()
        SelectClothing(DRESSING_OPTION_STARTING_GEAR)
    end

    SetCharacterManagerMode(CHARACTER_MODE_SELECTION)
    SetSuppressCharacterChanges(false)
    SelectCharacterToView(index)
end

local SetupCharacterList
local SelectedCharacterChanged
do
    local function AddCharacter(characterData)
        local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
        table.insert(dataList, ZO_ScrollList_CreateDataEntry(CHARACTER_DATA, characterData))
    end

    SetupCharacterList = function(self, eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
        
        ZO_CharacterSelect_OnCharacterListReceivedCommon(eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)

        ZO_CharacterSelect_ClearList()

        ZO_CharacterSelectCreate:SetEnabled(numCharacters < maxCharacters)
        ZO_CharacterSelectCharacterSlots:SetText(zo_strformat(SI_CHARACTER_SELECT_SLOTS, numCharacters, maxCharacters))

        local formattedNumDeletes = zo_strformat(SI_DELETE_CHARACTER_NUM_DELETES, numCharacterDeletesRemaining)
        if(numCharacterDeletesRemaining > 0) then
            ZO_CharacterSelectDelete:SetText(zo_strformat(SI_DELETE_CHARACTER, ZO_DEFAULT_ENABLED_COLOR:Colorize(formattedNumDeletes)))
            ZO_CharacterSelectDelete:SetEnabled(true)
        else
            ZO_CharacterSelectDelete:SetText(zo_strformat(SI_DELETE_CHARACTER, formattedNumDeletes))
            ZO_CharacterSelectDelete:SetEnabled(false)
        end

        -- Sharing data from ZO_CharacterSelectCommon
        local characterDataList = ZO_CharacterSelect_GetCharacterDataList()
        if(#characterDataList > 0) then
            for _, dataEntry in ipairs(characterDataList) do
                AddCharacter(dataEntry)
            end

            ZO_ScrollList_Commit(ZO_CharacterSelectScrollList)

            SelectCharacter(ZO_CharacterSelect_GetBestSelectionData())
        end
    end

    SelectedCharacterChanged = function(self, previouslySelected, selected)
        if(selected) then
            if(g_currentlySelectedCharacterData == nil or g_currentlySelectedCharacterData.index ~= selected.index) then
                g_currentlySelectedCharacterData = selected

                if(IsPregameCharacterConstructionReady()) then
                    ZO_CharacterSelect_EnableSelection(g_currentlySelectedCharacterData)
                    DoCharacterSelection(g_currentlySelectedCharacterData.index)
                end
            end
        end
    end
end

local function CharacterDeleted(eventCode, charId)
    -- Destroy the existing character list...then request a new one and the server will tell us which state to drop into.
    -- NOTE: This is actually passed the character id, but we're going to let the server handle the empty list case for now.
    ZO_CharacterSelect_ClearList()
    RequestCharacterList()
    ZO_CharacterSelect_FlagAsDeleting(charId, false)
end

local function OnCharacterRenamed(eventCode, charId, result)
    ZO_Dialogs_ReleaseDialog("RENAME_CHARACTER")
    if(result ~= NAME_RULE_NO_ERROR) then
        local errorReason = GetString("SI_NAMINGERROR", result)

        -- Show the fact that the character could not be created.
        ZO_Dialogs_ShowDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})
    end
end

local renamingId
function ZO_CharacterSelect_BeginRename(characterData)
    renamingId = characterData.id
    ZO_Dialogs_ShowDialog("RENAME_CHARACTER")
end

local renameInstructions
local function SetupRenameDialog(dialog, data)
    local nameEdit = dialog:GetNamedChild("NameEdit")

    if(renameInstructions == nil) then
        renameInstructions = ZO_ValidNameInstructions:New(ZO_CharacterSelectRenameInstructionsContainer)
    end

    renameInstructions:SetPreferredAnchor(TOPRIGHT, nameEdit, TOPLEFT, -30, -118)
    ZO_CharacterCreate_InitializeNameControl(nameEdit, ZO_RenameCharacterDialogAttemptRename, renameInstructions)
    nameEdit:SetText("")
end

function ZO_RenameCharacterDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("RENAME_CHARACTER",
    {
        customControl = self,
        setup = SetupRenameDialog,
        title =
        {
            text = SI_PROMPT_TITLE_RENAME_CHARACTER,
        },
        buttons =
        {
            [1] =
            {
                control =   GetControl(self, "AttemptRename"),
                text =      SI_OK,
                noReleaseOnClick = true,
                callback =  function(dialog)
                                AttemptCharacterRename(renamingId, ZO_RenameCharacterDialogNameEdit:GetText())
                                -- Do not release dialog here, wait until the server responds, this solves a few issues with button mashers.
                            end,
            },

            [2] =
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            }
        }
    })
end

local function OnCharacterConstructionReady()
    ZO_CharacterSelect_RefreshCharacters()

    if(GetNumCharacters() > 0) then
        ZO_CharacterSelect_EnableSelection(g_currentlySelectedCharacterData)
        DoCharacterSelection(g_currentlySelectedCharacterData.index)
    end
end

local function ContextFilter(callback)
    -- This will wrap the callback so that it gets called in the appropriate context
    return function(...)
        if not IsConsoleUI() then
            callback(...)
        end
    end
end

local function OnPregameCharacterListReceived(characterCount, previousCharacterCount)
    if (characterCount > 0) then
        PregameStateManager_SetState("CharacterSelect")
    end
end

function ZO_CharacterSelect_Initialize(self)
    ZO_CharacterSelectRealmName:SetText("")

    local function OnCharacterSelectionChanged(previouslySelected, selected)
        SelectedCharacterChanged(self, previouslySelected, selected)
    end

    local function OnCharacterListReceived(eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
        SetupCharacterList(self, eventCode, numCharacters, maxCharacters, mostRecentlyPlayedCharacterId, numCharacterDeletesRemaining, maxCharacterDeletes)
    end

    local function OnCharacterSelectedForPlay(eventCode, charId)
        local data = GetDataForCharacterId(charId)
        -- data will come back as nil on character creation
        local charData = data and data.data or nil
        ZO_CharacterSelect_DisableSelection(charData)
    end

    local list = ZO_CharacterSelectScrollList
    ZO_ScrollList_AddDataType(list, CHARACTER_DATA, "ZO_CharacterEntry", 80, SetupCharacterEntry)
    ZO_ScrollList_EnableSelection(list, "ZO_TallListHighlight", OnCharacterSelectionChanged)
    ZO_ScrollList_EnableHighlight(list, "ZO_TallListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(list, false)

    self:RegisterForEvent(EVENT_CHARACTER_LIST_RECEIVED, ContextFilter(OnCharacterListReceived))
    self:RegisterForEvent(EVENT_CHARACTER_DELETED, ContextFilter(CharacterDeleted))
    self:RegisterForEvent(EVENT_CHARACTER_SELECTED_FOR_PLAY, ContextFilter(OnCharacterSelectedForPlay))
    self:RegisterForEvent(EVENT_CHARACTER_RENAME_RESULT, ContextFilter(OnCharacterRenamed))

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", ContextFilter(OnCharacterConstructionReady))
    CALLBACK_MANAGER:RegisterCallback("PregameCharacterListReceived", ContextFilter(OnPregameCharacterListReceived))

    CHARACTER_SELECT_FRAGMENT = ZO_FadeSceneFragment:New(self, 300)
end

function ZO_CharacterSelect_SetupAddonManager()
    if not addOnManager then
        addOnManager = ZO_AddOnManager:New()
    end

    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    addOnManager:SetCharacterData(dataList)
end

function ZO_CharacterSelect_ClearList()
    g_currentlySelectedCharacterData = nil
    g_currrentSelectionPriority = -1
    ZO_CharacterSelect_DisableSelection()
    ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    if addOnManager then
        addOnManager:SetCharacterData(dataList)
    end
end

function ZO_CharacterSelect_Login(option)
    local state = PregameStateManager_GetCurrentState()
    --Entering and returning from a cinematic leaves us in CharacterSelect_FromCinematic. This is not a state, and it should
    --never have been one. It should be a edge back to the character select state.
    if(state == "CharacterSelect" or state == "CharacterSelect_FromCinematic") then
        local selectedData = ZO_ScrollList_GetSelectedData(ZO_CharacterSelectScrollList)
        if(selectedData) and (not g_deletingCharacterIds[selectedData.id]) then
            if(selectedData.needsRename) then
                ZO_CharacterSelect_BeginRename(selectedData)
            else
                PregameStateManager_PlayCharacter(selectedData.id, option)
            end
        end
    end
end

local function ChangeSelectedCharacter(direction)
    local list = ZO_CharacterSelectScrollList
    local selectedData = ZO_ScrollList_GetSelectedData(list)
    if(PregameStateManager_GetCurrentState() == "CharacterSelect" and selectedData ~= nil) then
        local dataList = ZO_ScrollList_GetDataList(list)
        local selectedDataIndex = selectedData.index
        local nextDataIndex = selectedDataIndex + direction
        if(nextDataIndex >= 1 and nextDataIndex <= #dataList) then
            local nextDataEntry = dataList[nextDataIndex]
            ZO_CharacterSelect_SetPlayerSelectedCharacterId(nextDataEntry.data.id)
            SelectCharacter(nextDataEntry.data)
        end
    end
end

function ZO_CharacterSelect_NextCharacter()
    ChangeSelectedCharacter(1)
end

function ZO_CharacterSelect_PreviousCharacter()
    ChangeSelectedCharacter(-1)
end

function ZO_CharacterSelect_DeleteSelected()
    local data = ZO_ScrollList_GetSelectedData(ZO_CharacterSelectScrollList)
    if(data and not ZO_Dialogs_IsShowing("DELETE_SELECTED_CHARACTER")) then
        local confirmationString = GetString(SI_DELETE_CHARACTER_CONFIRMATION_TEXT)
        local confirmationButtonName = GetString(SI_DELETE_CHARACTER_CONFIRMATION_BUTTON)
        local numCharacterDeletesRemaining = GetNumCharacterDeletesRemaining()
        ZO_Dialogs_ShowDialog("DELETE_SELECTED_CHARACTER", {characterId = data.id}, {mainTextParams = {data.name, confirmationString, confirmationButtonName, numCharacterDeletesRemaining}})
        ZO_CharacterSelectDelete:SetState(BSTATE_DISABLED, true)
    end
end

function ZO_CharacterSelect_FlagAsDeleting(characterId, deleting)
    if (deleting) then
        g_deletingCharacterIds[characterId] = true
    else
        g_deletingCharacterIds[characterId] = nil
    end
end

function ZO_CharacterEntry_OnMouseClick(self)
    local data = ZO_ScrollList_GetData(self)
    ZO_CharacterSelect_SetPlayerSelectedCharacterId(data.id)
    SelectCharacter(data)
end

function ZO_CharacterSelect_RefreshCharacters()
    ZO_ScrollList_RefreshVisible(ZO_CharacterSelectScrollList)
end

function ZO_CharacterSelectDelete_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMRIGHT, 0, -5, TOPRIGHT)

    local numCharacterDeletesRemaining = GetNumCharacterDeletesRemaining()
    local maxCharacterDeletes = GetMaxCharacterDeletes()

    if numCharacterDeletesRemaining == maxCharacterDeletes then
        InformationTooltip:AddLine(zo_strformat(GetString(SI_DELETE_CHARACTER_MAX_ENABLED_TOOLTIP), numCharacterDeletesRemaining), "", ZO_NORMAL_TEXT:UnpackRGB())
    elseif numCharacterDeletesRemaining > 0 then
        InformationTooltip:AddLine(zo_strformat(GetString(SI_DELETE_CHARACTER_ENABLED_TOOLTIP), numCharacterDeletesRemaining), "", ZO_NORMAL_TEXT:UnpackRGB())
    else
        InformationTooltip:AddLine(GetString(SI_DELETE_CHARACTER_DISABLED_TOOLTIP), "", ZO_NORMAL_TEXT:UnpackRGB())
    end
end

function ZO_CharacterSelectDelete_OnMouseExit()
    ClearTooltip(InformationTooltip)
end
