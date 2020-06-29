-- Common Data for CharacterCreate

CHARACTER_CREATE_SLIDER_TYPE_SLIDER = "slider"
CHARACTER_CREATE_SLIDER_TYPE_ICON = "icon"
CHARACTER_CREATE_SLIDER_TYPE_COLOR = "color"
CHARACTER_CREATE_SLIDER_TYPE_NAMED = "named"
CHARACTER_CREATE_SLIDER_TYPE_GENDER = "gender"

CREATE_BUCKET_RACE = 1
CREATE_BUCKET_CLASS = 2
CREATE_BUCKET_BODY = 3
CREATE_BUCKET_HEAD_TYPE = 4
CREATE_BUCKET_FEATURES = 5
CREATE_BUCKET_BODY_SHAPE = 6
CREATE_BUCKET_FACE = 7
CREATE_BUCKET_EYES = 8
CREATE_BUCKET_EARS = 9
CREATE_BUCKET_NOSE = 10
CREATE_BUCKET_MOUTH = 11
NUM_CREATE_BUCKETS = 11

CHARACTER_CREATE_MODE_CREATE = "create"
CHARACTER_CREATE_MODE_EDIT_RACE = "raceChange"
CHARACTER_CREATE_MODE_EDIT_APPEARANCE = "appearanceChange"
CHARACTER_CREATE_MODE_EDIT_ALLIANCE = "allianceChange"

CHARACTER_CREATE_SELECTOR_RACE = "race"
CHARACTER_CREATE_SELECTOR_CLASS = "class"
CHARACTER_CREATE_SELECTOR_ALLIANCE = "alliance"
CHARACTER_CREATE_SELECTOR_GENDER = "gender"

CHARACTER_CREATE_MAX_SUPPORTED_CLASSES = 6

--[[ Character Create Manager]]--

ZO_CHARACTER_CREATE_SYSTEM_NAME = "CHARACTER_CREATE"

ZO_CharacterCreate_Manager = ZO_Object:Subclass()

function ZO_CharacterCreate_Manager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_CharacterCreate_Manager:Initialize()
    self.characterData = ZO_CharacterCreateData:New()
    self.shouldPromptForTutorialSkip = true -- this in addition to the account flag means we should prompt
    self.playingTransitionAnimations = false
    self.characterMode = CHARACTER_MODE_CREATION
    self.randomCharacterGenerated = false
    self.characterUnsavedSettings = {}

    local function OnLogoutSuccessful()
        local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
        characterCreate:OnLogoutSuccessful()
    end

    local function OnCharacterCreated(eventCode, characterId)
        self:SetShouldPromptForTutorialSkip(true)

        local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
        characterCreate:OnCharacterCreated(characterId)
    end

    local function OnCharacterCreateFailed(eventCode, reason)
        local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
        characterCreate:OnCharacterCreateFailed(reason)

        self:SetShouldPromptForTutorialSkip(true)
    end

    local function OnCharacterEditSucceeded(eventCode, characterId, pendingAllianceChange)
        ZO_Dialogs_ReleaseAllDialogsOfName("CHARACTER_CREATE_SAVING_CHANGES")
        ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_SAVE_SUCCESS", { characterId = characterId, pendingAllianceChange = pendingAllianceChange })
    end

    local function OnCharacterEditFailed(eventCode, characterId, error)
        ZO_Dialogs_ReleaseAllDialogsOfName("CHARACTER_CREATE_SAVING_CHANGES")
        local dialogParams =
        {
            mainTextParams = { GetString("SI_CHARACTERCREATEEDITERROR", error) },
        }

        ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_SAVE_ERROR", nil, dialogParams)
    end

    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_LOGOUT_SUCCESSFUL, OnLogoutSuccessful)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_CREATED, OnCharacterCreated)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_CREATE_FAILED, OnCharacterCreateFailed)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_EDIT_SUCCEEDED, OnCharacterEditSucceeded)
    EVENT_MANAGER:RegisterForEvent("ZO_CharacterCreate_Gamepad", EVENT_CHARACTER_EDIT_FAILED, OnCharacterEditFailed)

    local function OnCharacterConstructionReady()
        self.characterData:PerformDeferredInitialization()

        local characterCreateGamepad
        local characterCreateKeyboard
        if IsGamepadUISupported() then
            characterCreateGamepad = SYSTEMS:GetGamepadObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
            characterCreateGamepad:InitializeSelectors()
        end

        if IsKeyboardUISupported() then
            characterCreateKeyboard = SYSTEMS:GetKeyboardObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
            characterCreateKeyboard:InitializeSelectors()
        end

        -- Nightmare load-ordering dependency...there are probably other ways around this, and they're probably just as bad.
        -- Once game data is loaded, generate a random character for character create just to advance the
        -- load state. It won't necessarily do any extra work creating an actual character, since we're going
        -- to drop back into the current state, but we need to tell the system to load something
        if GetNumCharacters() == 0 then
            SetSuppressCharacterChanges(true)
            -- in order to load correctly we need to be put into CHARACTER_MODE_CREATION first
            self:SetCharacterMode(CHARACTER_MODE_CREATION)
            -- now reset character create to generate a random character
            if characterCreateGamepad then
                characterCreateGamepad:Reset()
            end
            if characterCreateKeyboard then
                characterCreateKeyboard:Reset()
            end
            CharacterCreateSetFirstTimePosture()
            SetSuppressCharacterChanges(false)
        end
    end

    local function OnCharacterCreateRequested()
        local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
        characterCreate:OnCharacterCreateRequested()
    end

    CALLBACK_MANAGER:RegisterCallback("OnCharacterConstructionReady", OnCharacterConstructionReady)
    CALLBACK_MANAGER:RegisterCallback("CharacterCreateRequested", OnCharacterCreateRequested)
end

function ZO_CharacterCreate_Manager:SetRandomCharacterGenerated(wasGenerated)
    self.randomCharacterGenerated = wasGenerated
end

function ZO_CharacterCreate_Manager:HasRandomCharacterGenerated()
    return self.randomCharacterGenerated
end

function ZO_CharacterCreate_Manager:GetCharacterData()
    return self.characterData
end

function ZO_CharacterCreate_Manager:SetShouldPromptForTutorialSkip(shouldPrompt)
    self.shouldPromptForTutorialSkip = shouldPrompt
end

function ZO_CharacterCreate_Manager:GetShouldPromptForTutorialSkip()
    return self.shouldPromptForTutorialSkip
end

function ZO_CharacterCreate_Manager:SetPlayingTransitionAnimations(isPlaying)
    self.playingTransitionAnimations = isPlaying
end

function ZO_CharacterCreate_Manager:GetPlayingTransitionAnimations()
    return self.playingTransitionAnimations
end

function ZO_CharacterCreate_Manager:SetCharacterMode(characterMode)
    self.characterMode = characterMode
    SetCharacterManagerMode(characterMode)
end

function ZO_CharacterCreate_Manager:GetCharacterMode()
    return self.characterMode
end

function ZO_CharacterCreate_Manager:SetCharacterUnsavedSetting(name, type, value, locked)
    if not self.characterUnsavedSettings[name] then
        self.characterUnsavedSettings[name] = {}
    end

    if not self.characterUnsavedSettings[name][type] then
        self.characterUnsavedSettings[name][type] = {}
    end

    self.characterUnsavedSettings[name][type] =
    {
        value = value,
        locked = locked,
    }
end

function ZO_CharacterCreate_Manager:GetCharacterUnsavedSetting(name, type)
    if not (self.characterUnsavedSettings[name] and self.characterUnsavedSettings[name][type]) then
        return
    end

    return self.characterUnsavedSettings[name][type].value, self.characterUnsavedSettings[name][type].locked
end

function ZO_CharacterCreate_Manager:InitializeForAppearanceChange(characterData)
    self:SetCharacterMode(CHARACTER_MODE_EDIT)
    -- match the appearance set here to the default apperance set in PregameCharacterManager to avoid reloading the character
    SelectClothing(DRESSING_OPTION_YOUR_GEAR_AND_COLLECTIBLES)
    local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
    characterCreate:InitializeForAppearanceChange(characterData)
end

function ZO_CharacterCreate_Manager:InitializeForRaceChange(characterData)
    self:SetCharacterMode(CHARACTER_MODE_EDIT)
    -- match the appearance set here to the default apperance set in PregameCharacterManager to avoid reloading the character
    SelectClothing(DRESSING_OPTION_YOUR_GEAR_AND_COLLECTIBLES)
    local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
    characterCreate:InitializeForRaceChange(characterData)
end

function ZO_CharacterCreate_Manager:InitializeForAllianceChange(characterData)
    self:SetCharacterMode(CHARACTER_MODE_EDIT)
    -- match the appearance set here to the default apperance set in PregameCharacterManager to avoid reloading the character
    SelectClothing(DRESSING_OPTION_YOUR_GEAR_AND_COLLECTIBLES)
    local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
    characterCreate:InitializeForAllianceChange(characterData)
end

function ZO_CharacterCreate_Manager:InitializeForCharacterCreate()
    self:SetCharacterMode(CHARACTER_MODE_CREATION)
    local characterCreate = SYSTEMS:GetObject(ZO_CHARACTER_CREATE_SYSTEM_NAME)
    characterCreate:Reset()
    characterCreate:InitializeForCharacterCreate()
end

function ZO_CharacterCreate_Manager.GetOptionRestrictionString(restrictionReason, restrictingCollectible)
    if restrictionReason ~= CHARACTER_CREATE_OPTION_RESTRICTION_REASON_NONE then
        local restrictionString = GetString("SI_CHARACTERCREATEOPTIONRESTRICTIONREASON", restrictionReason)
        if restrictingCollectible ~= 0 then
            restrictionString = zo_strformat(restrictionString, GetCollectibleName(restrictingCollectible), GetCollectibleCategoryName(restrictingCollectible))
        else
            internalassert(false, "A collectible must be added to this entitlement restricted class/race def.")
        end

        return restrictionString
    end
    return ""
end

--[[ Character Create Base ]]--

ZO_CharacterCreate_Base = ZO_Object:Subclass()

function ZO_CharacterCreate_Base:New(...)
    local characterCreate = ZO_Object.New(self)
    characterCreate:Initialize(...)
    return characterCreate
end

function ZO_CharacterCreate_Base:Initialize(control)
    self.control = control
    self.characterData = ZO_CHARACTERCREATE_MANAGER:GetCharacterData()

    self.characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
    self.characterStartLocation = nil

    self.characterCreateMode = CHARACTER_CREATE_MODE_CREATE

    self:InitializeControls()
end

function ZO_CharacterCreate_Base:SetCharacterCreateMode(mode)
    self.characterCreateMode = mode
end

function ZO_CharacterCreate_Base:GetCharacterCreateMode()
    return self.characterCreateMode
end

function ZO_CharacterCreate_Base:GetTokenTypeForCharacterCreateMode(characterCreateMode)
    if characterCreateMode == CHARACTER_CREATE_MODE_EDIT_APPEARANCE then
        return SERVICE_TOKEN_APPEARANCE_CHANGE
    elseif characterCreateMode == CHARACTER_CREATE_MODE_EDIT_RACE then
        return SERVICE_TOKEN_RACE_CHANGE
    elseif characterCreateMode == CHARACTER_CREATE_MODE_EDIT_ALLIANCE then
        return SERVICE_TOKEN_ALLIANCE_CHANGE
    else
        return SERVICE_TOKEN_NONE
    end
end

function ZO_CharacterCreate_Base:DoesCurrentCharacterCreateModeAllowAppearanceChange()
    return self:GetCharacterCreateMode() ~= CHARACTER_CREATE_MODE_EDIT_ALLIANCE
end

function ZO_CharacterCreate_Base:DoesCurrentCharacterCreateModeAllowClassChange()
    return self:GetCharacterCreateMode() == CHARACTER_CREATE_MODE_CREATE
end

-- Any functions that end up changing sliders need to be wrapped like this
function ZO_CharacterCreate_Base:SetRace(race, options)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentRace = CharacterCreateGetRace(characterMode)
    if race == currentRace then
        return
    end

    CharacterCreateSetRace(race)
    
    -- When picking a race, unless the player is entitled to playing any race as any alliance or if the newly selected race
    -- has no alliance, we need to choose a new alliance for the player.  This is currently done as picking an alliance that matches
    -- the newly selected race
    local chooseNewAlliance = true
    if CanPlayAnyRaceAsAnyAlliance() or options == "preventAllianceChange" then
        chooseNewAlliance = false
    end

    local currentRaceData = self.characterData:GetRaceForRaceDef(CharacterCreateGetRace(characterMode))
    if currentRaceData.alliance == ALLIANCE_NONE then
        chooseNewAlliance = false
    end

    if chooseNewAlliance then
        local alliances = self.characterData:GetAllianceInfo()
        for _, allianceData in ipairs(alliances) do
            if allianceData.alliance == currentRaceData.alliance then
                self:SetAlliance(allianceData.alliance, "preventRaceChange")
            end
        end
    end

    self:ResetControls()
end

function ZO_CharacterCreate_Base:SetAlliance(allianceDef, options)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentAlliance = CharacterCreateGetAlliance(characterMode)
    if allianceDef == currentAlliance then
        return
    end

    ZO_CharacterCreate_SetAlliance(allianceDef)

    -- When picking an alliance, unless the player is entitled to playing any race as any alliance or if the current race
    -- has no alliance, we need to choose a new race for the player.  This is currently done as picking a race in the new
    -- alliance column that shares the row with the previous race.  If that race isn't selectable, then a random race in the
    -- new alliance will be selected.
    if CanPlayAnyRaceAsAnyAlliance() or options == "preventRaceChange" then
        return
    end

    local currentRaceData = self.characterData:GetRaceForRaceDef(CharacterCreateGetRace(characterMode))
    if currentRaceData.alliance == ALLIANCE_NONE then
        return
    end

    local currentAllianceData = self.characterData:GetAllianceForAllianceDef(allianceDef)

    -- Looking for the race on the same row as this one in the column under the appropriate alliance
    local racePos = currentRaceData.position - 1
    local raceRow = zo_floor(racePos / 3)
    local allianceCol = currentAllianceData.position - 1
    local desiredRacePos = (raceRow * 3) + allianceCol + 1

    local races = self.characterData:GetRaceInfo()
    for _, raceData in ipairs(races) do
        if raceData.position == desiredRacePos then
            self:SetRace(raceData.race, "preventAllianceChange")
        end
    end
end

function ZO_CharacterCreate_Base:SetGender(gender)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentGender = CharacterCreateGetGender(characterMode)
    if gender == currentGender then
        return
    end

    CharacterCreateSetGender(gender)
    self:ResetControls()
end

function ZO_CharacterCreate_Base:SetClass(class)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentClass = CharacterCreateGetClass(characterMode)
    if class == currentClass then
        return
    end

    CharacterCreateSetClass(class)
end

function ZO_CharacterCreate_Base:PickRandomSelectableClass()
    CharacterCreateSetClass(self.characterData:PickRandomClass())
end

function ZO_CharacterCreate_Base:PickRandomGender()
    CharacterCreateSetGender(self.characterData:PickRandomGender())
end

function ZO_CharacterCreate_Base:PickRandomRace()
    CharacterCreateSetRace(self.characterData:PickRandomRace())
end

function ZO_CharacterCreate_Base:PickRandomAlliance()
    ZO_CharacterCreate_SetAlliance(self.characterData:PickRandomAlliance())
end

function ZO_CharacterCreate_Base:GetCurrentAllianceData()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local selectedAlliance = CharacterCreateGetAlliance(characterMode)
    local alliance = self.characterData:GetAllianceForAllianceDef(selectedAlliance)

    if alliance then
        return alliance.name, alliance.backdropTop, alliance.backdropBottom
    end

    return "", "", ""
end

function ZO_CharacterCreate_Base:InitializeSelectorButton(buttonControl, data, radioGroup)
    if data == nil then
        return
    end

    buttonControl:SetHidden(false)
    buttonControl.selectorData = data

    self:InitializeSelectorButtonTextures(buttonControl, data)

    radioGroup:Add(buttonControl)
    self:SetSelectorButtonEnabled(buttonControl, radioGroup, data.isSelectable)
end

function ZO_CharacterCreate_Base:InitializeAllianceSelector(allianceButton, allianceData)
    self:InitializeSelectorButton(allianceButton, allianceData, self.allianceRadioGroup)

    allianceButton.name = allianceData.name
    allianceButton.defId = allianceData.alliance
end

function ZO_CharacterCreate_Base:AddRaceSelectionDataToSelector(buttonControl, raceData)
    buttonControl.nameFn = GetRaceName
    buttonControl.defId = raceData.race
    buttonControl.alliance = raceData.alliance
end

function ZO_CharacterCreate_Base:GenerateRandomCharacter()
    if not ZO_CHARACTERCREATE_MANAGER:HasRandomCharacterGenerated() and self.characterData:GetRaceInfo() ~= nil then
        ZO_CHARACTERCREATE_MANAGER:SetRandomCharacterGenerated(true)
        self:PickRandomRace()
        self:PickRandomAlliance()
        self:PickRandomGender()
        self:PickRandomSelectableClass()

        self:ResetControls()
        self:OnGenerateRandomCharacter()
        return true
    end

    return false
end

function ZO_CharacterCreate_Base:CreateCharacter(startLocation, createOption)
    local requestSkipTutorial = createOption == CHARACTER_CREATE_SKIP_TUTORIAL
    self.characterCreateOption = createOption
    CreateCharacter(self.characterName, requestSkipTutorial)
    self.characterStartLocation = startLocation or CHARACTER_OPTION_EXISTING_AREA
    CALLBACK_MANAGER:FireCallbacks("CharacterCreateRequested")
end

function ZO_CharacterCreate_Base:SetSelectorButtonEnabled(selectorButton, radioGroup, enabled)
    radioGroup:SetButtonIsValidOption(selectorButton, enabled)

    local desaturation = enabled and 0 or 1
    selectorButton:SetDesaturation(desaturation)
end

function ZO_CharacterCreate_Base:UpdateRaceSelectorsForTemplate(raceData, templateData)
    local enabled = raceData.isSelectable -- Only if the user is able to play the race in the first place do we even consider enabling it...
    if enabled then
        local templateRace = templateData.race
        -- check if the template has a race it forces the player to
        if templateRace ~= 0 then
            -- if this isn't the race specified by the template, disable it
            if templateRace ~= raceData.race then
                enabled = false
            end
        else
            -- check to see if the selected race is allowed based on the template alliance
            local templateAlliance = templateData.alliance
            if templateAlliance ~= ALLIANCE_NONE then
                if templateAlliance ~= raceData.alliance and not CanPlayAnyRaceAsAnyAlliance() then
                    enabled = false
                end
            end

            -- Exceptions to the rule, some races may still be enabled (Imperials is the only case now...)
            if raceData.alliance == ALLIANCE_NONE then
                enabled = true
            end
        end
    end

    return enabled
end

function ZO_CharacterCreate_Base:UpdateClassSelectorsForTemplate(classData, templateData)
    return classData.isSelectable and (templateData.class == 0 or templateData.class == classData.class)
end

function ZO_CharacterCreate_Base:UpdateAllianceSelectorsForTemplate(allianceData, templateData)
    return allianceData.isSelectable and (templateData.alliance == ALLIANCE_NONE or templateData.alliance == allianceData.alliance)
end

function ZO_CharacterCreate_Base:UpdateSelectorsForTemplate(isEnabledCallback, characterDataTable, templateData, radioGroup, optionalValidIndexTable)
    for button in radioGroup:IterateButtons() do
        local data = button.selectorData
        local enabled = isEnabledCallback(data, templateData)
        data.isRadioEnabled = enabled

        self:SetSelectorButtonEnabled(button, radioGroup, enabled)

        if optionalValidIndexTable and enabled then
            local dataIndex = ZO_IndexOfElementInNumericallyIndexedTable(characterDataTable, data)
            table.insert(optionalValidIndexTable, dataIndex)
        end
    end
end

function ZO_CharacterCreate_Base:OnLogoutSuccessful()
    ZO_CHARACTERCREATE_MANAGER:SetRandomCharacterGenerated(false)

    local NUM_FLASHES_BEFORE_SOLID = 7
    FlashTaskbarWindow("LOGOUT", NUM_FLASHES_BEFORE_SOLID)
end

function ZO_CharacterCreate_Base:OnCharacterCreated(characterId)
    ZO_CHARACTERCREATE_MANAGER:SetRandomCharacterGenerated(false) -- the next time we enter character create, we want to generate a random character again.
    self.characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION

    PregameStateManager_PlayCharacter(characterId, self.characterStartLocation)
end

function ZO_CharacterCreate_Base:SaveCharacterChanges()
    local tokenType
    local createMode = self:GetCharacterCreateMode()
    if createMode == CHARACTER_CREATE_MODE_EDIT_APPEARANCE then
        tokenType = SERVICE_TOKEN_APPEARANCE_CHANGE
    elseif createMode == CHARACTER_CREATE_MODE_EDIT_RACE then
        tokenType = SERVICE_TOKEN_RACE_CHANGE
    elseif createMode == CHARACTER_CREATE_MODE_EDIT_ALLIANCE then
        tokenType = SERVICE_TOKEN_ALLIANCE_CHANGE
    end

    local tokenString = GetString("SI_SERVICETOKENTYPE", tokenType)
    if IsEditCharacterDifferentFromSelectionCharacter() then
        ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_CONFIRM_SAVE_CHANGES", { tokenType = tokenType }, { mainTextParams = { tokenString } })
    else
        ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_NO_CHANGES_MADE", { tokenType = tokenType, newState = "CharacterSelect_FromIngame" }, { mainTextParams = { tokenString } })
    end
end

function ZO_CharacterCreate_Base:ExitToState(stateName)
    local createMode = self:GetCharacterCreateMode()
    if createMode == CHARACTER_CREATE_MODE_CREATE then
        PregameStateManager_SetState(stateName)
    else
        local tokenType
        if createMode == CHARACTER_CREATE_MODE_EDIT_APPEARANCE then
            tokenType = SERVICE_TOKEN_APPEARANCE_CHANGE
        elseif createMode == CHARACTER_CREATE_MODE_EDIT_RACE then
            tokenType = SERVICE_TOKEN_RACE_CHANGE
        elseif createMode == CHARACTER_CREATE_MODE_EDIT_ALLIANCE then
            tokenType = SERVICE_TOKEN_ALLIANCE_CHANGE
        end

        local tokenString = GetString("SI_SERVICETOKENTYPE", tokenType)
        if IsEditCharacterDifferentFromSelectionCharacter() then
            ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_CONFIRM_REVERT_CHANGES", { newState = stateName }, { mainTextParams = { tokenString } })
        else
            ZO_Dialogs_ShowPlatformDialog("CHARACTER_CREATE_NO_CHANGES_MADE", { tokenType = tokenType, newState = stateName }, { mainTextParams = { tokenString } })
        end
    end
end

function ZO_CharacterCreate_Base:Reset()
    -- Should be overridden
end

function ZO_CharacterCreate_Base:InitializeControls()
    -- Should be overridden
end

function ZO_CharacterCreate_Base:InitializeSelectors()
    -- Should be overridden
end

function ZO_CharacterCreate_Base:OnCharacterCreateRequested()
    -- Should be overridden
end

function ZO_CharacterCreate_Base:OnCharacterCreateFailed(reason)
    -- Should be overridden
end

function ZO_CharacterCreate_Base:ResetControls()
    -- Should be overridden
end

function ZO_CharacterCreate_Base:InitializeSelectorButtonTextures(buttonControl, data)
    -- Should be overridden
end

function ZO_CharacterCreate_Base:OnGenerateRandomCharacter()
    -- optional override
end

function ZO_CharacterCreate_Base:InitializeForAppearanceChange(characterData)
    -- optional override
end

function ZO_CharacterCreate_Base:InitializeForRaceChange(characterData)
    -- optional override
end

function ZO_CharacterCreate_Base:InitializeForAllianceChange(characterData)
    -- optional override
end

function ZO_CharacterCreate_Base:InitializeForCharacterCreate()
    -- optional override
end

--[[ Character Create Global functions ]]--

ZO_CHARACTERCREATE_MANAGER = ZO_CharacterCreate_Manager:New()

function ZO_CharacterCreate_FadeIn()
    ZO_CharacterCreateOverlay.fadeTimeline:Stop()
    ZO_CharacterCreateOverlay:SetHidden(false)
    ZO_CharacterCreateOverlay:SetMouseEnabled(true)
    ZO_CharacterCreateOverlay:SetAlpha(1)

    ZO_CharacterCreateOverlay.fadeTimeline:PlayFromStart()
    ZO_CHARACTERCREATE_MANAGER:SetPlayingTransitionAnimations(true)
end

function ZO_CharacterCreate_FadeInMainControls()
    local screen

    if IsInGamepadPreferredMode() then
        screen = ZO_CharacterCreate_Gamepad
    else
        screen = ZO_CharacterCreate
    end

    screen.fadeTimeline:PlayFromStart()
    ZO_CHARACTERCREATE_MANAGER:SetPlayingTransitionAnimations(true)
end

function ZO_CharacterCreate_FinishTransitions()
    ZO_CharacterCreateOverlay:SetMouseEnabled(false)
    ZO_CHARACTERCREATE_MANAGER:SetPlayingTransitionAnimations(false)

    PregameStateManager_SetState("CharacterCreate")
end

function OnCharacterCreateOptionChanged()
    ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true)
end

function ZO_CharacterCreate_SetAlliance(alliance)
    CharacterCreateSetAlliance(alliance)
    ZO_CharacterCreate_SetChromaColorForAlliance(alliance)
end

function ZO_CharacterCreate_SetChromaColorForAlliance(alliance)
    if ZO_RZCHROMA_EFFECTS then
        ZO_RZCHROMA_EFFECTS:SetAlliance(alliance)
    end
end