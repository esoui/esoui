local CHARACTER_DATA = 1
local g_currentlySelectedCharacterData
local g_deletingCharacterIds = {}
local g_characterOrderDividerHalfHeight
local g_characterSelectStartDragOrder
local g_selectedOrderControl

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
        ZO_CharacterSelectSelectedName:SetText(ZO_CharacterSelect_GetFormattedCharacterName(data))
        ZO_CharacterSelectSelectedRace:SetText(zo_strformat(SI_CHARACTER_SELECT_RACE, GetRaceName(data.gender, data.race)))
        ZO_CharacterSelectSelectedLocation:SetText(zo_strformat(SI_CHARACTER_SELECT_LOCATION, GetLocationName(data.location)))
        ZO_CharacterSelectSelectedClassLevel:SetText(ZO_CharacterSelect_GetFormattedLevelChampionAndClass(data))
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

    characterName:SetText(ZO_CharacterSelect_GetFormattedCharacterName(data))
    characterStatus:SetText(ZO_CharacterSelect_GetFormattedLevelChampionAndClass(data))

    if data.location ~= 0 then
        characterLocation:SetText(zo_strformat(SI_CHARACTER_SELECT_LOCATION, GetLocationName(data.location)))
    else
        characterLocation:SetText(GetString(SI_UNKNOWN_LOCATION))
    end

    local allianceTexture = ZO_GetAllianceIcon(data.alliance)
    if allianceTexture then
        characterAlliance:SetTexture(allianceTexture)
    end

    if not control.orderUpButton then
        local characterOrderUp = control:GetNamedChild("OrderUp")
        local characterOrderDown = control:GetNamedChild("OrderDown")
        characterOrderUp:SetHidden(true)
        characterOrderDown:SetHidden(true)

        control.orderUpButton = characterOrderUp;
        control.orderDownButton = characterOrderDown;
    end

    local selectedData = ZO_CharacterSelect_GetSelectedCharacterData();
    if selectedData == data then
        control.orderUpButton:SetHidden(false)
        control.orderDownButton:SetHidden(false)
    else
        control.orderUpButton:SetHidden(true)
        control.orderDownButton:SetHidden(true)
    end

    if g_characterSelectStartDragOrder and g_characterSelectStartDragOrder ~= data.order then
        characterName:SetAlpha(0.5)
        characterStatus:SetAlpha(0.5)
        characterLocation:SetAlpha(0.5)
        characterAlliance:SetAlpha(0.5)
    else
        characterName:SetAlpha(1)
        characterStatus:SetAlpha(1)
        characterLocation:SetAlpha(1)
        characterAlliance:SetAlpha(1)
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
    if IsPregameCharacterConstructionReady() then
        KEYBOARD_CHARACTER_CREATE_MANAGER:GenerateRandomCharacter()
        SelectClothing(DRESSING_OPTION_STARTING_GEAR)
    end

    SetCharacterManagerMode(CHARACTER_MODE_SELECTION)
    SetSuppressCharacterChanges(false)
    SelectCharacterToView(index)
    ZO_CharacterSelect_SetChromaColorForCharacterIndex(index)
end

local SetupCharacterList
local SelectedCharacterChanged
local SetupScrollList
do
    SetupScrollList = function()
        local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
        local characterDataList = ZO_CharacterSelect_GetCharacterDataList()
        if #characterDataList > 0 then
            for _, dataEntry in ipairs(characterDataList) do
                table.insert(dataList, ZO_ScrollList_CreateDataEntry(CHARACTER_DATA, dataEntry))
            end

            ZO_ScrollList_Commit(ZO_CharacterSelectScrollList)
        end
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
        SetupScrollList()

        local characterData = ZO_CharacterSelect_GetBestSelectionData()
        if characterData then
            SelectCharacter(characterData)
            ZO_ScrollList_ScrollDataToCenter(ZO_CharacterSelectScrollList, characterData.order)
        end

        local accountChampionPoints = ZO_CharacterSelect_GetAccountChampionPoints()
        if accountChampionPoints > 0 then
            ZO_CharacterSelectChampionPoints:SetText(zo_strformat(SI_KEYBOARD_ACCOUNT_CHAMPION_POINTS, accountChampionPoints))
        else
            ZO_CharacterSelectChampionPoints:SetHidden(true)
        end
    end

    SelectedCharacterChanged = function(self, previouslySelected, selected)
        if previouslySelected then
            if previouslySelected.dataEntry.control then
                previouslySelected.dataEntry.control.orderUpButton:SetHidden(true)
                previouslySelected.dataEntry.control.orderDownButton:SetHidden(true)
            end
        end

        if selected then
            if g_currentlySelectedCharacterData == nil or g_currentlySelectedCharacterData.index ~= selected.index then
                g_currentlySelectedCharacterData = selected

                if IsPregameCharacterConstructionReady() then
                    ZO_CharacterSelect_EnableSelection(g_currentlySelectedCharacterData)
                    DoCharacterSelection(g_currentlySelectedCharacterData.index)
                end
            end

            if selected.dataEntry.control then
                selected.dataEntry.control.orderUpButton:SetHidden(false)
                selected.dataEntry.control.orderDownButton:SetHidden(false)
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

local g_requestedCharacterRename = ""

local function OnCharacterRenamedErrorCallback()
    ZO_CharacterSelect_BeginRename(ZO_CharacterSelect_GetSelectedCharacterData())
end

local function OnCharacterRenamed(eventCode, charId, result)
    local OnSuccessCallback = nil

    ZO_CharacterSelect_OnCharacterRenamedCommon(eventCode, charId, result, g_requestedCharacterRename, OnSuccessCallback, OnCharacterRenamedErrorCallback)
end

function ZO_CharacterSelect_BeginRename(characterData)
    ZO_Dialogs_ShowDialog("RENAME_CHARACTER_KEYBOARD", { characterData = characterData })
end

local function SetupRenameDialog(dialog, data)
    local nameHeader = dialog:GetNamedChild("NameHeader")
    nameHeader:SetText(zo_strformat(SI_RENAME_CHARACTER_NAME_LABEL, data.characterData.name))

    dialog.nameEdit = dialog:GetNamedChild("NameEdit")

    dialog.attemptRenameButton = dialog:GetNamedChild("AttemptRename")
    dialog.cancelButton = dialog:GetNamedChild("Cancel")

    if(dialog.renameInstructions == nil) then
        local NAME_INSTRUCTIONS_OFFSET_X = -20
        local NAME_INSTRUCTIONS_OFFSET_Y = 0
    
        dialog.renameInstructions = ZO_ValidNameInstructions:New(dialog:GetNamedChild("RenameInstructions"))
        dialog.renameInstructions:SetPreferredAnchor(RIGHT, dialog, LEFT, NAME_INSTRUCTIONS_OFFSET_X, NAME_INSTRUCTIONS_OFFSET_Y)   -- Attach instructions to left side of the dialog
    end

    SetupEditControlForNameValidation(dialog.nameEdit)
    dialog.nameEdit:SetText("")
end

function ZO_RenameCharacterDialog_OnInitialized(self)
    ZO_Dialogs_RegisterCustomDialog("RENAME_CHARACTER_KEYBOARD",
    {
        customControl = self,
        canQueue = true,
        setup = SetupRenameDialog,
        title =
        {
            text = function(dialog)
                        local titleText = SI_CHARACTER_SELECT_RENAME_CHARACTER_FROM_TOKEN_TITLE

                        if dialog.data.characterData.needsRename then
                            titleText = SI_CHARACTER_SELECT_RENAME_CHARACTER_TITLE
                        end

                        return GetString(titleText)
                   end,
        },
        buttons =
        {
            {
                control =   GetControl(self, "AttemptRename"),
                text =      SI_CHARACTER_SELECT_RENAME_SAVE_NEW_NAME,
                callback =  function(dialog)
                                g_requestedCharacterRename = ZO_RenameCharacterDialogNameEdit:GetText()
                                AttemptCharacterRename(dialog.data.characterData.id, g_requestedCharacterRename)
                                
                                -- Show a loading dialog in its place until the rename request finishes
                                ZO_Dialogs_ShowDialog("CHARACTER_SELECT_CHARACTER_RENAMING")
                            end,
            },
            {
                control =   GetControl(self, "Cancel"),
                text =      SI_DIALOG_CANCEL,
            },
        },
        updateFn = function(dialog)
                        local nameText = dialog.nameEdit:GetText()
                        local nameViolations = { IsValidCharacterName(nameText) }

                        if #nameViolations > 0 then
                            dialog.renameInstructions:Show(nil, nameViolations)
                            dialog.attemptRenameButton:SetEnabled(false)
                        else
                            dialog.renameInstructions:Hide()
                            dialog.attemptRenameButton:SetEnabled(true)
                        end

                        local correctedName = CorrectCharacterNameCase(nameText)
                        if correctedName ~= nameText then
                            -- only set the text if it's actually changed
                            dialog.nameEdit:SetText(correctedName)
                        end
                   end,
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

ZO_CHARACTER_SELECT_ENTRY_HEIGHT = 90

function ZO_CharacterSelect_Initialize(self)
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

    local function OnPregameFullyLoaded()
        if ZO_CharacterSelect_CanShowAdditionalSlotsInfo() then
            ZO_CharacterSelectExtraCharacterSlots:SetHidden(false)
            ZO_CharacterSelectExtraCharacterSlots:SetText(zo_strformat(SI_ADDITIONAL_CHARACTER_SLOTS_DESCRIPTION, ZO_CharacterSelect_GetAdditionalSlotsRemaining()))
            ZO_CharacterSelectCharacterSlots:SetAnchor(TOP, nil, TOP, 0, 10)
        else
            ZO_CharacterSelectExtraCharacterSlots:SetHidden(true)
            ZO_CharacterSelectCharacterSlots:SetAnchor(TOP, nil, TOP, 0, 31)
        end

        local chapterUpgradeId = GetCurrentChapterUpgradeId()
        if chapterUpgradeId == 0 or IsChapterOwned(chapterUpgradeId) then
            ZO_CharacterSelectChapterUpgrade:SetHidden(true)
        else
            local chapterCollectibleId = GetChapterCollectibleId(chapterUpgradeId)
            ZO_CharacterSelectChapterUpgradeTitle:SetText(zo_strformat(SI_CHARACTER_SELECT_CHAPTER_LOCKED_FORMAT, GetCollectibleName(chapterCollectibleId)))
            ZO_CharacterSelectChapterUpgradeImage:SetTexture(GetCurrentChapterMediumLogoFileIndex())

            ZO_CharacterSelectChapterUpgrade:SetHidden(false)
        end
    end

    local list = ZO_CharacterSelectScrollList
    ZO_ScrollList_AddDataType(list, CHARACTER_DATA, "ZO_CharacterEntry", ZO_CHARACTER_SELECT_ENTRY_HEIGHT, SetupCharacterEntry)
    ZO_ScrollList_EnableSelection(list, "ZO_TallListHighlight", OnCharacterSelectionChanged)
    ZO_ScrollList_EnableHighlight(list, "ZO_TallListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(list, false)

    ZO_ScrollList_AddResizeOnScreenResize(list)

    self:RegisterForEvent(EVENT_CHARACTER_LIST_RECEIVED, ContextFilter(OnCharacterListReceived))
    self:RegisterForEvent(EVENT_CHARACTER_DELETED, ContextFilter(CharacterDeleted))
    self:RegisterForEvent(EVENT_CHARACTER_SELECTED_FOR_PLAY, ContextFilter(OnCharacterSelectedForPlay))
    self:RegisterForEvent(EVENT_CHARACTER_RENAME_RESULT, ContextFilter(OnCharacterRenamed))

    self:SetHandler("OnUpdate", function(_, timeS)
        ZO_CharacterSelect_OnUpdate(timeS)
    end)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", ContextFilter(OnCharacterConstructionReady))
    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", ContextFilter(OnPregameFullyLoaded))

    CHARACTER_SELECT_FRAGMENT = ZO_FadeSceneFragment:New(self, 300)
end

function ZO_CharacterOrderDivider_Initialize()
    g_characterOrderDividerHalfHeight = ZO_CharacterOrderDivider:GetHeight() / 2
end

function ZO_CharacterSelect_SetupAddonManager()
    if not ADD_ON_MANAGER then
        ADD_ON_MANAGER = ZO_AddOnManager:New()
    end

    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    ADD_ON_MANAGER:SetCharacterData(dataList)
end

function ZO_CharacterSelect_ClearList()
    g_currentlySelectedCharacterData = nil
    g_currrentSelectionPriority = -1
    ZO_CharacterSelect_DisableSelection()
    ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    if ADD_ON_MANAGER then
        ADD_ON_MANAGER:SetCharacterData(dataList)
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

do
    local DRAG_GRACE_DISTANCE = 50
    function ZO_CharacterSelect_OnUpdate(timeS)
        if g_characterSelectStartDragOrder then
            local control = WINDOW_MANAGER:GetMouseOverControl()
            if control and control.dataEntry then -- make sure we are looking at a control in the scroll list
                ZO_CharacterOrderDivider:ClearAnchors()
                ZO_CharacterOrderDivider:SetHidden(false)
                local centerX, centerY = control:GetCenter()
                local mouseX, mouseY = GetUIMousePosition()
                if mouseY > centerY then
                    ZO_CharacterOrderDivider:SetAnchor(TOP, control, BOTTOM, 0, -g_characterOrderDividerHalfHeight)
                else
                    ZO_CharacterOrderDivider:SetAnchor(BOTTOM, control, TOP, 0 , g_characterOrderDividerHalfHeight)
                end
                g_selectedOrderControl = control
            elseif g_selectedOrderControl then
                local mouseX = GetUIMousePosition()
                if g_selectedOrderControl:GetLeft() - mouseX > DRAG_GRACE_DISTANCE then
                    g_selectedOrderControl = nil
                    ZO_CharacterOrderDivider:ClearAnchors()
                    ZO_CharacterOrderDivider:SetHidden(true)
                end
            end
        end
    end
end

function ZO_CharacterSelect_GetSelectedCharacterData()
    return ZO_ScrollList_GetSelectedData(ZO_CharacterSelectScrollList)
end

local function ChangeSelectedCharacter(direction)
    local list = ZO_CharacterSelectScrollList
    local selectedData = ZO_ScrollList_GetSelectedData(list)
    if PregameStateManager_GetCurrentState() == "CharacterSelect" and selectedData ~= nil then
        local dataList = ZO_ScrollList_GetDataList(list)
        local selectedDataIndex
        for index, dataEntry in ipairs(dataList) do
            if dataEntry.data == selectedData then
                selectedDataIndex = index
                break
            end
        end
        local nextDataIndex = selectedDataIndex + direction
        if nextDataIndex >= 1 and nextDataIndex <= #dataList then
            local nextDataEntry = dataList[nextDataIndex]
            ZO_CharacterSelect_SetPlayerSelectedCharacterId(nextDataEntry.data.id)
            ZO_ScrollList_ScrollDataIntoView(list, nextDataIndex)
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

function ZO_CharacterEntry_OnDragStart(self)
    local data = ZO_ScrollList_GetData(self)
    g_characterSelectStartDragOrder = data.order
    ZO_CharacterSelect_RefreshCharacters()
end

function ZO_CharacterEntry_OnMouseUp(self)
    if g_characterSelectStartDragOrder then
        if g_selectedOrderControl then
            local selectedData = ZO_CharacterSelect_GetSelectedCharacterData()
            local endedOrder = g_selectedOrderControl.dataEntry.data.order
            local centerX, centerY = g_selectedOrderControl:GetCenter()
            local mouseX, mouseY = GetUIMousePosition()
            -- correct end order based on mouse position and direction we are reordering
            if endedOrder < g_characterSelectStartDragOrder and mouseY > centerY then
                endedOrder = endedOrder + 1
            elseif endedOrder > g_characterSelectStartDragOrder and mouseY <= centerY then
                endedOrder = endedOrder - 1
            end
            ZO_CharacterSelect_ChangeCharacterOrders(g_characterSelectStartDragOrder, endedOrder)

            g_selectedOrderControl = nil
            g_characterSelectStartDragOrder = nil

            ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
            SetupScrollList()
            SelectCharacter(selectedData)
        else
            g_characterSelectStartDragOrder = nil
            g_selectedOrderControl = nil
            ZO_CharacterSelect_RefreshCharacters()
        end

        ZO_CharacterOrderDivider:ClearAnchors()
        ZO_CharacterOrderDivider:SetHidden(true)
    end
end

function ZO_CharacterEntry_OnMouseDoubleClick(self, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local orderUpButton = self:GetNamedChild("OrderUp")
        if MouseIsInside(orderUpButton) then
            return
        end
        local orderDownButton = self:GetNamedChild("OrderDown")
        if MouseIsInside(orderDownButton) then
            return
        end

        ZO_CharacterSelect_Login(CHARACTER_OPTION_EXISTING_AREA)
    end
end

function ZO_CharacterEntry_OnMouseEnter(self)
    if not g_characterSelectStartDragOrder then
        ZO_ScrollList_MouseEnter(ZO_CharacterSelectScrollList, self)
    end
end

function ZO_CharacterEntry_OnMouseExit(self)
    ZO_ScrollList_MouseExit(ZO_CharacterSelectScrollList, self)
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

function ZO_CharacterSelectChapterUpgradeRegisterButton_OnMouseEnter(control)
    local platformServiceType = GetPlatformServiceType()
    local upgradeMethodsStringId = ZO_PLATFORM_ALLOWS_CHAPTER_CODE_ENTRY[platformServiceType] and SI_CHARACTER_SELECT_CHAPTER_UPGRADE_REGISTER_TOOLTIP_UPGRADE_OR_CODE or SI_CHARACTER_SELECT_CHAPTER_UPGRADE_REGISTER_TOOLTIP_UPGRADE_ONLY
    InitializeTooltip(InformationTooltip, control, BOTTOMLEFT, 5, 0, BOTTOMRIGHT)
    InformationTooltip:AddLine(GetString(upgradeMethodsStringId), "", ZO_NORMAL_TEXT:UnpackRGB())
end

function ZO_CharacterSelectChapterUpgradeRegisterButton_OnMouseExit()
    ClearTooltip(InformationTooltip)
end

function ZO_CharacterSelect_Move_Character_Up()
    local selectedData = ZO_CharacterSelect_GetSelectedCharacterData()
    if selectedData and selectedData.order > 1 then
        ZO_CharacterSelect_OrderCharacterUp(selectedData.order)
        ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
        SetupScrollList()
        SelectCharacter(selectedData)
    end
end

function ZO_CharacterSelect_Move_Character_Down()
    local selectedData = ZO_CharacterSelect_GetSelectedCharacterData()
    if selectedData and selectedData.order < GetNumCharacters() then
        ZO_CharacterSelect_OrderCharacterDown(selectedData.order)
        ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
        SetupScrollList()
        SelectCharacter(selectedData)
    end
end

-- Service Token Indicator Functions

local ServiceTokenIndicator = ZO_Object:Subclass()

function ServiceTokenIndicator:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ServiceTokenIndicator:Initialize(control, tokenType, iconTexture)
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    self.tokenCount = control:GetNamedChild("TokenCount")
    self.highlight = control:GetNamedChild("BG"):GetNamedChild("Highlight")

    if iconTexture then
        self.icon:SetTexture(iconTexture)
    end

    self.tokenType = tokenType

    self:SetTokenCount(GetNumServiceTokens(tokenType))

    self.tooltip = ServiceTooltip
    self.tooltipHeaderText = zo_strformat(SI_SERVICE_TOOLTIP_HEADER_FORMATTER, GetString("SI_SERVICETOKENTYPE", tokenType))

    local function OnTokensUpdated(eventId, tokenType, numTokens)
        if tokenType == self.tokenType then
            self:SetTokenCount(numTokens)
        end
    end

    control:RegisterForEvent(EVENT_SERVICE_TOKENS_UPDATED, ContextFilter(OnTokensUpdated))

    control:SetHandler("OnMouseUp", function(control, button, upInside)
        if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
            self:OnMouseUp(control)
        end
    end)

    control:SetHandler("OnMouseEnter", function(control)
        self:OnMouseEnter(control)
    end)

    control:SetHandler("OnMouseExit", function(control)
        self:OnMouseExit(control)
    end)
end

function ServiceTokenIndicator:SetTokenCount(numTokens)
    self.tokenCount:SetText(numTokens)

    self.enabled = numTokens ~= 0
    
    self.icon:SetDesaturation(self.enabled and 0 or 1)
end

function ServiceTokenIndicator:OnMouseEnter()
    InitializeTooltip(self.tooltip, self.control, BOTTOM, 0, -10, TOP)
    self.highlight:SetHidden(false)

    local tokensAvailableText
    local tokensAvailableTextColor
    local numTokens = GetNumServiceTokens(self.tokenType)
    if numTokens ~= 0 then
        tokensAvailableText = zo_strformat(SI_SERVICE_TOOLTIP_SERVICE_TOKENS_AVAILABLE, numTokens, GetString("SI_SERVICETOKENTYPE", self.tokenType))
        tokensAvailableTextColor = ZO_SUCCEEDED_TEXT
    else
        tokensAvailableText = zo_strformat(SI_SERVICE_TOOLTIP_NO_SERVICE_TOKENS_AVAILABLE, GetString("SI_SERVICETOKENTYPE", self.tokenType))
        tokensAvailableTextColor = ZO_ERROR_COLOR
    end

    self:AddHeader(self.tooltipHeaderText)
    self:AddBodyText(self:GetDescription())
    self:AddBodyText(tokensAvailableText, tokensAvailableTextColor)
end

local SET_TO_FULL_SIZE = true
function ServiceTokenIndicator:AddHeader(headerText)
    local r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    self.tooltip:AddHeaderLine(GetString(SI_SERVICE_TOOLTIP_TYPE), "ZoFontWinH5", 1, THS_LEFT, r, g, b)

    r, g, b = ZO_SELECTED_TEXT:UnpackRGB()
    self.tooltip:AddLine(headerText, "ZoFontWinH3", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_UPPERCASE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)

    ZO_Tooltip_AddDivider(self.tooltip)
end

function ServiceTokenIndicator:AddBodyText(bodyText, bodyTextColor)
    local r, g, b
    if bodyTextColor then
        r, g, b = bodyTextColor:UnpackRGB()
    else
        r, g, b = ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB()
    end
    self.tooltip:AddLine(bodyText, "", r, g, b, TOPLEFT, MODIFY_TEXT_TYPE_NONE, TEXT_ALIGN_CENTER, SET_TO_FULL_SIZE)
end

function ServiceTokenIndicator:OnMouseExit()
    ClearTooltip(self.tooltip)
    self.highlight:SetHidden(true)
end

function ServiceTokenIndicator:OnMouseUp()
    -- to be overridden by subclasses to perform their action
end

function ServiceTokenIndicator:GetDescription()
    return GetServiceTokenDescription(self.tokenType)
end

-- Name Change Tokens

local NameChangeTokenIndicator = ServiceTokenIndicator:Subclass()

function NameChangeTokenIndicator:New(...)
    return ServiceTokenIndicator.New(self, ...)
end

function NameChangeTokenIndicator:Initialize(control)
    ServiceTokenIndicator.Initialize(self, control, SERVICE_TOKEN_NAME_CHANGE, "EsoUI/Art/Icons/Token_NameChange.dds")
end

function NameChangeTokenIndicator:OnMouseUp()
    if self.enabled then
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()

        if characterData.needsRename then
            ZO_Dialogs_ShowDialog("INELIGIBLE_SERVICE")
        else
            ZO_CharacterSelect_BeginRename(characterData)
        end
    end
end

function ZO_NameChangeIndicator_Initialize(control)
    NAME_CHANGE_TOKEN_INDICATOR = NameChangeTokenIndicator:New(control)
end

-- Race Change Tokens

local RaceChangeTokenIndicator = ServiceTokenIndicator:Subclass()

function RaceChangeTokenIndicator:New(...)
    return ServiceTokenIndicator.New(self, ...)
end

function RaceChangeTokenIndicator:Initialize(control)
    ServiceTokenIndicator.Initialize(self, control, SERVICE_TOKEN_RACE_CHANGE, "EsoUI/Art/Icons/Token_RaceChange.dds")
end

function RaceChangeTokenIndicator:OnMouseUp()
    if self.enabled then
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        ZO_CHARACTERCREATE_MANAGER:InitializeForRaceChange(characterData)
        PregameStateManager_SetState("CharacterCreate_Barbershop")
    end
end

function ZO_RaceChangeIndicator_Initialize(control)
    RACE_CHANGE_TOKEN_INDICATOR = RaceChangeTokenIndicator:New(control)
end

-- Appearance Change Tokens

local AppearanceChangeTokenIndicator = ServiceTokenIndicator:Subclass()

function AppearanceChangeTokenIndicator:New(...)
    return ServiceTokenIndicator.New(self, ...)
end

function AppearanceChangeTokenIndicator:Initialize(control)
    ServiceTokenIndicator.Initialize(self, control, SERVICE_TOKEN_APPEARANCE_CHANGE, "EsoUI/Art/Icons/Token_AppearanceChange.dds")
end

function AppearanceChangeTokenIndicator:OnMouseUp()
    if self.enabled then
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        ZO_CHARACTERCREATE_MANAGER:InitializeForAppearanceChange(characterData)
        PregameStateManager_SetState("CharacterCreate_Barbershop")
    end
end

function ZO_AppearanceChangeIndicator_Initialize(control)
    APPEARANCE_CHANGE_TOKEN_INDICATOR = AppearanceChangeTokenIndicator:New(control)
end
