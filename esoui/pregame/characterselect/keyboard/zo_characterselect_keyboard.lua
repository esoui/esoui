local CHARACTER_DATA = 1
local g_characterOrderDividerHalfHeight
local g_characterSelectStartDragOrder
local g_selectedOrderControl

function ZO_CharacterSelect_GetFormattedLevelChampion(characterData)
    if characterData.championPoints and characterData.championPoints > 0 then
        return zo_strformat(SI_CHARACTER_SELECT_CHAMPION_CLASS, characterData.championPoints, '')
    else
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CLASS, characterData.level, '')
    end
end

function ZO_CharacterSelect_GetFormattedLevelChampionAndClass(characterData)
    local className = characterData.class and GetClassName(characterData.gender, characterData.class) or GetString(SI_UNKNOWN_CLASS)
    if characterData.championPoints and characterData.championPoints > 0 then
        local keyboardIconString = "EsoUI/Art/Champion/champion_icon.dds"
        local formattedIcon = zo_iconFormat(keyboardIconString, "100%", "100%")
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CHAMPION_CLASS, characterData.level, formattedIcon, className)
    else
        return zo_strformat(SI_CHARACTER_SELECT_LEVEL_CLASS, characterData.level, className)
    end
end

local function UpdateSelectedCharacterData(data)
    if data then
        ZO_CharacterSelectSelectedName:SetText(ZO_CharacterSelect_Manager_GetFormattedCharacterName(data))
        ZO_CharacterSelectSelectedRace:SetText(zo_strformat(SI_CHARACTER_SELECT_RACE, GetRaceName(data.gender, data.race)))
        ZO_CharacterSelectSelectedLocation:SetText(zo_strformat(SI_CHARACTER_SELECT_LOCATION, GetLocationName(data.location)))
        ZO_CharacterSelectSelectedClassLevel:SetText(ZO_CharacterSelect_GetFormattedLevelChampion(data))
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
    local characterName = control:GetNamedChild("Name")
    local characterStatus = control:GetNamedChild("ClassLevel")
    local characterLocation = control:GetNamedChild("Location")
    local characterAlliance = control:GetNamedChild("Alliance")

    characterName:SetText(ZO_CharacterSelect_Manager_GetFormattedCharacterName(data))
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

        control.orderUpButton = characterOrderUp
        control.orderDownButton = characterOrderDown
    end

    local selectedData = ZO_CharacterSelect_GetSelectedCharacterData()
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

local function SetupScrollList()
    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    local characterDataList = CHARACTER_SELECT_MANAGER:GetCharacterDataList()
    if #characterDataList > 0 then
        for _, dataEntry in ipairs(characterDataList) do
            table.insert(dataList, ZO_ScrollList_CreateDataEntry(CHARACTER_DATA, dataEntry))
        end

        ZO_ScrollList_Commit(ZO_CharacterSelectScrollList)
    end
end

local function SetupCharacterList()
    ZO_CharacterSelect_ClearList()

    ZO_CharacterSelectCreate:SetEnabled(CHARACTER_SELECT_MANAGER:CanCreateNewCharacters())
    ZO_CharacterSelectCharacterSlots:SetText(zo_strformat(SI_CHARACTER_SELECT_SLOTS, CHARACTER_SELECT_MANAGER:GetNumCharacters(), CHARACTER_SELECT_MANAGER:GetMaxCharacters()))

    local numCharacterDeletesRemaining = CHARACTER_SELECT_MANAGER:GetNumCharacterDeletesRemaining()
    local formattedNumDeletes = zo_strformat(SI_DELETE_CHARACTER_NUM_DELETES, numCharacterDeletesRemaining)
    if numCharacterDeletesRemaining > 0 then
        ZO_CharacterSelectDelete:SetText(zo_strformat(SI_DELETE_CHARACTER, ZO_DEFAULT_ENABLED_COLOR:Colorize(formattedNumDeletes)))
        ZO_CharacterSelectDelete:SetEnabled(true)
    else
        ZO_CharacterSelectDelete:SetText(zo_strformat(SI_DELETE_CHARACTER, formattedNumDeletes))
        ZO_CharacterSelectDelete:SetEnabled(false)
    end

    SetupScrollList()

    local characterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
    if characterData then
        ZO_ScrollList_SelectData(ZO_CharacterSelectScrollList, characterData)
        ZO_ScrollList_ScrollDataToCenter(ZO_CharacterSelectScrollList, characterData.order)
    end

    local accountChampionPoints = CHARACTER_SELECT_MANAGER:GetAccountChampionPoints()
    if accountChampionPoints > 0 then
        ZO_CharacterSelectChampionPoints:SetText(zo_strformat(SI_KEYBOARD_ACCOUNT_CHAMPION_POINTS, accountChampionPoints))
    else
        ZO_CharacterSelectChampionPoints:SetHidden(true)
    end
end

local function SelectedCharacterChanged(self, previouslySelectedCharacterData, selectedCharacterData)
    if previouslySelectedCharacterData then
        if previouslySelectedCharacterData.dataEntry.control then
            previouslySelectedCharacterData.dataEntry.control.orderUpButton:SetHidden(true)
            previouslySelectedCharacterData.dataEntry.control.orderDownButton:SetHidden(true)
        end
    end

    if selectedCharacterData then
        if IsPregameCharacterConstructionReady() then
            ZO_CharacterSelect_EnableSelection(selectedCharacterData)
        end

        if selectedCharacterData.dataEntry.control then
            selectedCharacterData.dataEntry.control.orderUpButton:SetHidden(false)
            selectedCharacterData.dataEntry.control.orderDownButton:SetHidden(false)
        end

        if selectedCharacterData.needsRename then
            ZO_CharacterSelectLogin:SetText(GetString(SI_RENAME_CHARACTER))
        else
            ZO_CharacterSelectLogin:SetText(GetString(SI_LOGIN_CHARACTER))
        end

        if ZO_RZCHROMA_EFFECTS then
            ZO_RZCHROMA_EFFECTS:SetAlliance(selectedCharacterData.alliance)
        end
    end
    ZO_CharacterSelect_RefreshVisibleList()
end

function ZO_CharacterSelect_BeginRename(characterData)
    if internalassert(characterData) then
        ZO_Dialogs_ShowDialog("RENAME_CHARACTER_KEYBOARD", { characterData = characterData })
    end
end

local function SetupRenameDialog(dialog, data)
    local nameHeader = dialog:GetNamedChild("NameHeader")
    nameHeader:SetText(zo_strformat(SI_RENAME_CHARACTER_NAME_LABEL, data.characterData.name))

    dialog.nameEdit = dialog:GetNamedChild("NameEdit")

    dialog.attemptRenameButton = dialog:GetNamedChild("AttemptRename")
    dialog.cancelButton = dialog:GetNamedChild("Cancel")

    if dialog.renameInstructions == nil then
        local NAME_INSTRUCTIONS_OFFSET_X = -20
        local NAME_INSTRUCTIONS_OFFSET_Y = 0

        local VALIDATOR_RULES =
        {
            NAME_RULE_TOO_SHORT,
            NAME_RULE_CANNOT_START_WITH_SPACE,
            NAME_RULE_MUST_END_WITH_LETTER,
            NAME_RULE_TOO_MANY_IDENTICAL_ADJACENT_CHARACTERS,
            NAME_RULE_NO_NUMBERS,
            NAME_RULE_NO_ADJACENT_PUNCTUATION_CHARACTERS,
            NAME_RULE_TOO_MANY_PUNCTUATION_CHARACTERS,
            NAME_RULE_INVALID_CHARACTERS
        }
        local DEFAULT_TEMPLATE = nil
        dialog.renameInstructions = ZO_ValidNameInstructions:New(dialog:GetNamedChild("RenameInstructions"), DEFAULT_TEMPLATE, VALIDATOR_RULES)
        dialog.renameInstructions:SetPreferredAnchor(RIGHT, dialog, LEFT, NAME_INSTRUCTIONS_OFFSET_X, NAME_INSTRUCTIONS_OFFSET_Y)   -- Attach instructions to left side of the dialog
    end

    dialog.nameEdit:SetHandler("OnFocusGained", function()
        local control = dialog.renameInstructions
        if control:HasRules() then
            local DEFAULT_ANCHOR_CONTROL = nil
            local nameText = dialog.nameEdit:GetText()
            local violations = {IsValidCharacterName(nameText)}
            control:Show(DEFAULT_ANCHOR_CONTROL, violations)
        end
    end, "RenameInstructions")

    dialog.nameEdit:SetHandler("OnFocusLost", function()
        local control = dialog.renameInstructions
        if control:HasRules() then
            local nameText = dialog.nameEdit:GetText()
            local violations = {IsValidCharacterName(nameText)}
            if #violations == 0 then
                control:Hide()
            end
        end
    end, "RenameInstructions")

    SetupEditControlForNameValidation(dialog.nameEdit)
    dialog.nameEdit:SetText("")
end

function ZO_RenameCharacterDialog_OnInitialized(self)
    local function OnRenameResult(success)
        if not success then
            -- restart flow
            ZO_CharacterSelect_BeginRename(ZO_CharacterSelect_GetSelectedCharacterData())
        end
    end
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
                control = GetControl(self, "AttemptRename"),
                text = SI_CHARACTER_SELECT_RENAME_SAVE_NEW_NAME,
                callback = function(dialog)
                    local requestedName = ZO_RenameCharacterDialogNameEdit:GetText()
                    CHARACTER_SELECT_MANAGER:AttemptCharacterRename(dialog.data.characterData.id, requestedName, OnRenameResult)
                end,
            },
            {
                control = GetControl(self, "Cancel"),
                text = SI_DIALOG_CANCEL,
            },
        },
        updateFn = function(dialog)
            local nameText = dialog.nameEdit:GetText()
            local nameViolations = { IsValidCharacterName(nameText) }
            local DEFAULT_ANCHOR_CONTROL = nil
            
            if dialog.nameEdit:HasFocus() then
                dialog.renameInstructions:Show(DEFAULT_ANCHOR_CONTROL, nameViolations)
            end

            if #nameViolations > 0 then
                dialog.attemptRenameButton:SetEnabled(false)
            else
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
    ZO_CharacterSelect_RefreshVisibleList()

    local selectedCharacterData = CHARACTER_SELECT_MANAGER:GetSelectedCharacterData()
    if selectedCharacterData then
        ZO_CharacterSelect_EnableSelection(selectedCharacterData)
        CHARACTER_SELECT_MANAGER:RefreshConstructedCharacter()
    end
end

ZO_CHARACTER_SELECT_ENTRY_HEIGHT = 90

function ZO_CharacterSelect_Initialize(self)
    local function OnCharacterSelectionChanged(previouslySelected, selected)
        SelectedCharacterChanged(self, previouslySelected, selected)
    end

    local function OnCharacterSelectedForPlay(eventCode, charId)
        local data = CHARACTER_SELECT_MANAGER:GetDataForCharacterId(charId)
        ZO_CharacterSelect_DisableSelection(data)
    end

    local function PopulateCarousel()
        if not self.carousel then
            return
        end

        self.carousel:Clear()

        local numEvents = CHARACTER_SELECT_MANAGER:GetNumEventAnnouncements()
        for i = 1, numEvents do
            local data = CHARACTER_SELECT_MANAGER:GetEventAnnouncementDataByIndex(i)
            local entryData =
            {
                index = data.index,
                name = data.name,
                description = data.description,
                image = data.image,
                startTime = data.startTime,
                remainingTime = data.remainingTime,
                callback = function() self.carousel:UpdateSelection(i) end
            }

            self.carousel:AddEntry(entryData)
        end

        self.carousel:Commit()

        -- update visibility of events/chapter upgrade as appropriate

        if numEvents > 0 then
            ZO_CharacterSelectEventMinimized:SetHidden(false)
            ZO_CharacterSelectChapterUpgrade:SetHidden(true)
        elseif not CHAPTER_UPGRADE_MANAGER:CanRegister() then
            ZO_CharacterSelectChapterUpgrade:SetHidden(true)
            ZO_CharacterSelectEventMinimized:SetHidden(true)
        else
            local chapterUpgradeId = GetCurrentChapterUpgradeId()
            local chapterCollectibleId = GetChapterCollectibleId(chapterUpgradeId)
            ZO_CharacterSelectChapterUpgradeTitle:SetText(zo_strformat(SI_CHARACTER_SELECT_CHAPTER_LOCKED_FORMAT, GetCollectibleName(chapterCollectibleId)))
            ZO_CharacterSelectChapterUpgradeImage:SetTexture(GetCurrentChapterMediumLogoFileIndex())

            ZO_CharacterSelectChapterUpgrade:SetHidden(false)
            ZO_CharacterSelectEventMinimized:SetHidden(true)
        end

        local autoShowIndex = CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex()
        self.carousel:SetSelectedIndex(autoShowIndex and (1 - autoShowIndex) or 0)
    end

    local function OnPregameFullyLoaded()
        if CHARACTER_SELECT_MANAGER:CanShowAdditionalSlotsInfo() then
            ZO_CharacterSelectExtraCharacterSlots:SetHidden(false)
            ZO_CharacterSelectExtraCharacterSlots:SetText(zo_strformat(SI_ADDITIONAL_CHARACTER_SLOTS_DESCRIPTION, CHARACTER_SELECT_MANAGER:GetAdditionalSlotsRemaining()))
            ZO_CharacterSelectCharacterSlots:SetAnchor(TOP, nil, TOP, 0, 10)
        else
            ZO_CharacterSelectExtraCharacterSlots:SetHidden(true)
            ZO_CharacterSelectCharacterSlots:SetAnchor(TOP, nil, TOP, 0, 31)
        end

        if not self.carousel then
            -- Setup events minimized display if we have events, otherwise show chapter upgrade if relevant, or show nothing
            self.carousel = ZO_Carousel_Shared:New(ZO_CharacterSelectEventMinimizedCarousel, "ZO_CharacterSelect_SmallEventTile_Keyboard_Control")
            self.carousel:SetSelectionIndicatorPipStateImages("EsoUI/Art/Buttons/RadioButtonDown.dds", "EsoUI/Art/Buttons/RadioButtonUp.dds", "EsoUI/Art/Buttons/RadioButtonHighlight.dds")
        end

        PopulateCarousel()

        if CHARACTER_SELECT_FRAGMENT:IsShowing() then
            ZO_CharacterSelect_OnCharacterSelectShown(self)
        end
    end

    local list = ZO_CharacterSelectScrollList
    ZO_ScrollList_AddDataType(list, CHARACTER_DATA, "ZO_CharacterEntry", ZO_CHARACTER_SELECT_ENTRY_HEIGHT, SetupCharacterEntry)
    ZO_ScrollList_EnableSelection(list, "ZO_TallListHighlight", OnCharacterSelectionChanged)
    ZO_ScrollList_EnableHighlight(list, "ZO_TallListHighlight")
    ZO_ScrollList_SetDeselectOnReselect(list, false)

    ZO_ScrollList_AddResizeOnScreenResize(list)

    self:RegisterForEvent(EVENT_CHARACTER_SELECTED_FOR_PLAY, OnCharacterSelectedForPlay)
    self:RegisterForEvent(EVENT_ENTITLEMENT_STATE_CHANGED, function()
        -- Need the game data to be loaded before we can populate the carousel, which is handled by OnPregameFullyLoaded()
        if PregameIsFullyLoaded() then
            PopulateCarousel()
        end
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("CharacterListUpdated", function()
        SetupCharacterList()
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("CharacterOrderChanged", function()
        ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
        SetupScrollList()
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("SelectedCharacterUpdated", function(characterData)
        ZO_ScrollList_SelectData(ZO_CharacterSelectScrollList, characterData)
    end)

    CHARACTER_SELECT_MANAGER:RegisterCallback("EventAnnouncementExpired", function() PopulateCarousel() end)

    self:SetHandler("OnUpdate", function(_, timeS)
        ZO_CharacterSelect_OnUpdate(timeS)
    end)

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", OnCharacterConstructionReady)
    CALLBACK_MANAGER:RegisterCallback("PregameFullyLoaded", OnPregameFullyLoaded)

    CHARACTER_SELECT_BACKGROUND_FRAGMENT = ZO_SimpleSceneFragment:New(ZO_CharacterSelectBG)
    CHARACTER_SELECT_FRAGMENT = ZO_FadeSceneFragment:New(self, 300)
    CHARACTER_SELECT_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWN then
            SCENE_MANAGER:AddFragment(CHARACTER_SELECT_BACKGROUND_FRAGMENT)
            ZO_CharacterSelect_OnCharacterSelectShown(self)
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            SCENE_MANAGER:RemoveFragment(CHARACTER_SELECT_BACKGROUND_FRAGMENT)
            if self.carousel then
                self.carousel:Deactivate()
            end
        end
    end)
end

function ZO_CharacterSelect_OnCharacterSelectShown(self)
    if not IsInGamepadPreferredMode() and self.carousel then
        self.carousel:Activate()
        self.carousel:UpdateArrows()

        local autoShowIndex = CHARACTER_SELECT_MANAGER:GetEventAnnouncementAutoShowIndex()
        if autoShowIndex then
            ZO_CharacterSelect_ShowEventBanner()
            CHARACTER_SELECT_MANAGER:UpdateLastSeenTimestamp()
        end
    end
end

function ZO_CharacterSelect_IsKeyboardCharacterSelectShowing()
    return CHARACTER_SELECT_FRAGMENT:IsShowing()
end

function ZO_CharacterOrderDivider_Initialize()
    g_characterOrderDividerHalfHeight = ZO_CharacterOrderDivider:GetHeight() / 2
end

function ZO_CharacterSelect_SetupAddonManager()
    if not ADD_ON_MANAGER then
        local primaryKeybindDescriptor =
        {
            keybind = "ADDONS_PANEL_PRIMARY",
            name = GetString(SI_ADDON_MANAGER_VIEW_EULA),
            visible = function()
                return not HasAgreedToEULA(EULA_TYPE_ADDON_EULA)
            end,
            callback = function()
                CALLBACK_MANAGER:FireCallbacks("ShowAddOnEULAIfNecessary")
            end,
        }
        local NO_SECONDARY_KEYBIND_DESCRIPTOR = nil
        ADD_ON_MANAGER = ZO_AddOnManager:New(primaryKeybindDescriptor, NO_SECONDARY_KEYBIND_DESCRIPTOR)
    end

    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    ADD_ON_MANAGER:SetCharacterData(dataList)
end

function ZO_CharacterSelect_ClearList()
    ZO_CharacterSelect_DisableSelection()
    ZO_ScrollList_Clear(ZO_CharacterSelectScrollList)
    local dataList = ZO_ScrollList_GetDataList(ZO_CharacterSelectScrollList)
    if ADD_ON_MANAGER then
        ADD_ON_MANAGER:SetCharacterData(dataList)
    end
end

function ZO_CharacterSelect_Login(option)
    local state = PregameStateManager_GetCurrentState()
    if state == "CharacterSelect" then
        local selectedData = ZO_ScrollList_GetSelectedData(ZO_CharacterSelectScrollList)
        if selectedData then
            if selectedData.needsRename then
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
            ZO_ScrollList_ScrollDataIntoView(list, nextDataIndex)
            CHARACTER_SELECT_MANAGER:SetPlayerSelectedCharacter(nextDataEntry.data)
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
    if data and not ZO_Dialogs_IsShowing("DELETE_SELECTED_CHARACTER") then
        local confirmationString = GetString(SI_DELETE_CHARACTER_CONFIRMATION_TEXT)
        local confirmationButtonName = GetString(SI_DELETE_CHARACTER_CONFIRMATION_BUTTON)
        local numCharacterDeletesRemaining = CHARACTER_SELECT_MANAGER:GetNumCharacterDeletesRemaining()
        local textParams =
        {
            data.name,
            confirmationString,
            confirmationButtonName,
            numCharacterDeletesRemaining
        }
        ZO_Dialogs_ShowDialog("DELETE_SELECTED_CHARACTER", { characterId = data.id }, { mainTextParams = textParams })
    end
end

function ZO_CharacterEntry_OnMouseClick(self)
    PlaySound(SOUNDS.DEFAULT_CLICK)
    local characterData = ZO_ScrollList_GetData(self)
    CHARACTER_SELECT_MANAGER:SetPlayerSelectedCharacter(characterData)
end

function ZO_CharacterEntry_OnDragStart(self)
    local data = ZO_ScrollList_GetData(self)
    g_characterSelectStartDragOrder = data.order
    ZO_CharacterSelect_RefreshVisibleList()
end

function ZO_CharacterEntry_OnMouseUp(self)
    if g_characterSelectStartDragOrder then
        if g_selectedOrderControl then
            local startOrder = g_characterSelectStartDragOrder
            local endOrder = g_selectedOrderControl.dataEntry.data.order
            local centerX, centerY = g_selectedOrderControl:GetCenter()
            local mouseX, mouseY = GetUIMousePosition()
            -- correct end order based on mouse position and direction we are reordering
            if endOrder < startOrder and mouseY > centerY then
                endOrder = endOrder + 1
            elseif endOrder > endOrder and mouseY <= centerY then
                endOrder = endOrder - 1
            end
            g_selectedOrderControl = nil
            g_characterSelectStartDragOrder = nil
            CHARACTER_SELECT_MANAGER:ChangeCharacterOrders(startOrder, endOrder)
        else
            g_characterSelectStartDragOrder = nil
            g_selectedOrderControl = nil
            ZO_CharacterSelect_RefreshVisibleList()
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

function ZO_CharacterSelect_RefreshVisibleList()
    ZO_ScrollList_RefreshVisible(ZO_CharacterSelectScrollList)
end

function ZO_CharacterSelectDelete_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOMRIGHT, 0, -5, TOPRIGHT)

    local numCharacterDeletesRemaining = CHARACTER_SELECT_MANAGER:GetNumCharacterDeletesRemaining()

    if CHARACTER_SELECT_MANAGER:AreAllCharacterDeletesRemaining() then
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
        CHARACTER_SELECT_MANAGER:SwapCharacterOrderUp(selectedData.order)
    end
end

function ZO_CharacterSelect_Move_Character_Down()
    local selectedData = ZO_CharacterSelect_GetSelectedCharacterData()
    if selectedData and selectedData.order < CHARACTER_SELECT_MANAGER:GetNumCharacters() then
        CHARACTER_SELECT_MANAGER:SwapCharacterOrderDown(selectedData.order)
    end
end

function ZO_CharacterSelect_ShowEventBanner()
    SCENE_MANAGER:AddFragment(CHARACTER_SELECT_EVENT_BANNER_KEYBOARD:GetFragment())
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

    control:RegisterForEvent(EVENT_SERVICE_TOKENS_UPDATED, OnTokensUpdated)

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

    control:SetHandler("OnEffectivelyShown", function(control)
        self:RefreshEnabledState(GetNumServiceTokens(self.tokenType))
    end)
end

function ServiceTokenIndicator:SetTokenCount(numTokens)
    self.tokenCount:SetText(numTokens)

    self:RefreshEnabledState(numTokens)
end

function ServiceTokenIndicator:RefreshEnabledState(numTokens)
    local hasTokens = numTokens > 0
    self.icon:SetDesaturation(hasTokens and 0 or 1)

    if self:MeetsUsageRequirements() or not hasTokens then
        self.icon:SetColor(ZO_WHITE:UnpackRGB())
        self.enabled = hasTokens
    else
        self.icon:SetColor(ZO_ERROR_COLOR:UnpackRGB())
        self.enabled = false
    end
end

function ServiceTokenIndicator:OnMouseEnter()
    self.highlight:SetHidden(false)

    InitializeTooltip(self.tooltip, self.control, BOTTOM, 0, -10, TOP)
    self:AddHeader(self.tooltipHeaderText)
    self:AddBodyText(self:GetDescription())

    local requiredCollectibleId = self:GetRequiredCollectibleId()
    if requiredCollectibleId ~= 0 then
        local collectibleName = GetCollectibleName(requiredCollectibleId)
        local categoryName = GetCollectibleCategoryNameByCollectibleId(requiredCollectibleId)
        local requiredCollectibleText = zo_strformat(SI_SERVICE_TOOLTIP_REQUIRES_COLLECTIBLE_TO_USE, collectibleName, categoryName)

        local meetsRequirementTextStyle
        local numTokens = GetNumServiceTokens(tokenType)
        if self:MeetsUsageRequirements() then
            meetsRequirementTextStyle = ZO_SUCCEEDED_TEXT
        else
            meetsRequirementTextStyle = ZO_ERROR_COLOR
        end
        self:AddBodyText(requiredCollectibleText, meetsRequirementTextStyle)
    end

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

function ServiceTokenIndicator:MeetsUsageRequirements()
    -- optional override
    return true
end

function ServiceTokenIndicator:GetRequiredCollectibleId()
    -- optional override
    return 0
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
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        if characterData.needsRename then
            ZO_Dialogs_ShowDialog("INELIGIBLE_SERVICE")
        else
            ZO_CharacterSelect_BeginRename(characterData)
        end
    end
end

function ZO_NameChangeIndicator_Initialize(control)
    local nameChangeTokenIndicator = NameChangeTokenIndicator:New(control)
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
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        ZO_CHARACTERCREATE_MANAGER:InitializeForRaceChange(characterData)
        PregameStateManager_SetState("CharacterCreate_Barbershop")
    end
end

function ZO_RaceChangeIndicator_Initialize(control)
    local raceChangeTokenIndicator = RaceChangeTokenIndicator:New(control)
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
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        ZO_CHARACTERCREATE_MANAGER:InitializeForAppearanceChange(characterData)
        PregameStateManager_SetState("CharacterCreate_Barbershop")
    end
end

function ZO_AppearanceChangeIndicator_Initialize(control)
    local appearanceChangeTokenIndicator = AppearanceChangeTokenIndicator:New(control)
end

-- Alliance Change Tokens

local AllianceChangeTokenIndicator = ServiceTokenIndicator:Subclass()

function AllianceChangeTokenIndicator:New(...)
    return ServiceTokenIndicator.New(self, ...)
end

function AllianceChangeTokenIndicator:Initialize(control)
    ServiceTokenIndicator.Initialize(self, control, SERVICE_TOKEN_ALLIANCE_CHANGE, "EsoUI/Art/Icons/Token_AllianceChange.dds")
end

function AllianceChangeTokenIndicator:OnMouseUp()
    if self.enabled then
        PlaySound(SOUNDS.DEFAULT_CLICK)
        local characterData = ZO_CharacterSelect_GetSelectedCharacterData()
        ZO_CHARACTERCREATE_MANAGER:InitializeForAllianceChange(characterData)
        PregameStateManager_SetState("CharacterCreate_Barbershop")
    end
end

function AllianceChangeTokenIndicator:MeetsUsageRequirements()
    return CanPlayAnyRaceAsAnyAlliance()
end

function AllianceChangeTokenIndicator:GetRequiredCollectibleId()
    return GetAnyRaceAnyAllianceCollectibleId()
end

function ZO_AllianceChangeIndicator_Initialize(control)
    local allianceChanceTokenIndicator = AllianceChangeTokenIndicator:New(control)
end
