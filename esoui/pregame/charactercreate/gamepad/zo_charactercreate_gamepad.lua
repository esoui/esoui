local g_randomizeAppearanceEnabled = true

local CHARACTER_CREATE_GAMEPAD_DIALOG = "CHARACTER_CREATE_GAMEPAD"
local SKIP_TUTORIAL_GAMEPAD_DIALOG = "SKIP_TUTORIAL_GAMEPAD"

local SELECTOR_PER_ROW_CENTER_OFFSET = -65

local INITIAL_BUCKET = CREATE_BUCKET_RACE

local function CreatePreviewOption(dressingOption)
    return  {
                name = zo_strformat(SI_CREATE_CHARACTER_GAMEPAD_PREVIEW_OPTION_FORMAT, GetString("SI_CHARACTERCREATEDRESSINGOPTION", dressingOption)),
                OnSelectedCallback =    function()
                                            SelectClothing(dressingOption)
                                        end
            }
end

local PREVIEW_NO_GEAR = CreatePreviewOption(DRESSING_OPTION_NUDE)
local PREVIEW_NOVICE_GEAR = CreatePreviewOption(DRESSING_OPTION_STARTING_GEAR)
local PREVIEW_CHAMPION_GEAR = CreatePreviewOption(DRESSING_OPTION_WARDROBE_1)
local PREVIEW_CURRENT_GEAR = CreatePreviewOption(DRESSING_OPTION_YOUR_GEAR)
local PREVIEW_CURRENT_GEAR_AND_COLLECTIBLES = CreatePreviewOption(DRESSING_OPTION_YOUR_GEAR_AND_COLLECTIBLES)

local CHARACTER_CREATE_PREVIEW_GEAR_INFO = 
{
    PREVIEW_NOVICE_GEAR,
    PREVIEW_CHAMPION_GEAR,
    PREVIEW_NO_GEAR,
}

local CHARACTER_EDIT_PREVIEW_GEAR_INFO = 
{
    PREVIEW_CURRENT_GEAR_AND_COLLECTIBLES, -- match the first appearance here to the default apperance set in PregameCharacterManager to avoid reloading the character
    PREVIEW_CURRENT_GEAR,
    PREVIEW_CHAMPION_GEAR,
    PREVIEW_NO_GEAR,
}

-- Slider Randomization Helper...all sliders share the sliderObject from the top control, so this just helps cut down on duplicate functions
local function RandomizeSlider(control, randomizeType)
    control.sliderObject:Randomize(randomizeType)
end

-- Character Create Slider and Appearance Slider Managers
-- Manages a collection of sliders with a pool

local CharacterCreateSliderManager = ZO_Object:Subclass()

function CharacterCreateSliderManager:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function CharacterCreateSliderManager:Initialize(parent)
    local CreateSlider =    function(pool)
                                local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateSlider", "ZO_CharacterCreateSlider_Gamepad", pool, parent)
                                return ZO_CharacterCreateSlider_Gamepad:New(control)
                            end

    local CreateAppearanceSlider =  function(pool)
                                        local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateAppearanceSlider", "ZO_CharacterCreateSlider_Gamepad", pool, parent)
                                        return ZO_CharacterCreateAppearanceSlider_Gamepad:New(control)
                                    end

    local CreateColorPicker =   function(pool)
                                    local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateColorPicker", "ZO_CharacterCreateSlider_Gamepad", pool, parent)
                                    return ZO_CharacterCreateAppearanceSlider_Gamepad:New(control)
                                end

    local CreateVoiceSlider =   function(pool)
                                    local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateVoiceSlider", "ZO_CharacterCreateSlider_Gamepad", pool, parent)
                                    return ZO_CharacterCreateVoiceSlider_Gamepad:New(control)
                                end

    local CreateGenderSlider =  function(pool)
                                    local control = ZO_ObjectPool_CreateNamedControl("CharacterCreateGenderSlider", "ZO_CharacterCreateSlider_Gamepad", pool, parent)
                                    return ZO_CharacterCreateGenderSlider_Gamepad:New(control)
                                end

    local function ResetSlider(slider)
        local sliderControl = slider.control
        GAMEPAD_BUCKET_MANAGER:RemoveControl(sliderControl)
        sliderControl:SetHidden(true)
        if slider:IsLocked() then
            slider:ToggleLocked()
        end
    end

    self.pools =
    {
        [CHARACTER_CREATE_SLIDER_TYPE_SLIDER] = ZO_ObjectPool:New(CreateSlider, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_ICON] = ZO_ObjectPool:New(CreateAppearanceSlider, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_COLOR] = ZO_ObjectPool:New(CreateColorPicker, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_NAMED] = ZO_ObjectPool:New(CreateVoiceSlider, ResetSlider),
        [CHARACTER_CREATE_SLIDER_TYPE_GENDER] = ZO_ObjectPool:New(CreateGenderSlider, ResetSlider),
    }
end

function CharacterCreateSliderManager:AcquireObject(objectType)
    local pool = self.pools[objectType]
    if pool then
        return pool:AcquireObject()
    end
end

function CharacterCreateSliderManager:ReleaseAllObjects()
    for poolType, pool in pairs(self.pools) do
        pool:ReleaseAllObjects()
    end
end

--[[ Character Create Manager ]]--

local ZO_CharacterCreate_Gamepad = ZO_CharacterCreate_Base:Subclass()

function ZO_CharacterCreate_Gamepad:New(...)
    return ZO_CharacterCreate_Base.New(self, ...)
end

function ZO_CharacterCreate_Gamepad:Initialize(...)
    ZO_CharacterCreate_Base.Initialize(self, ...)

    CHARACTER_CREATE_GAMEPAD_FRAGMENT = ZO_FadeSceneFragment:New(self.control)
    GAMEPAD_CHARACTER_CREATE_SCENE = ZO_Scene:New("gamepadCharacterCreate", SCENE_MANAGER)
    GAMEPAD_CHARACTER_CREATE_SCENE:AddFragment(CHARACTER_CREATE_GAMEPAD_FRAGMENT)
    GAMEPAD_CHARACTER_CREATE_SCENE:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
    self.scene = GAMEPAD_CHARACTER_CREATE_SCENE

    local ALWAYS_ANIMATE = true
    CHARACTER_CREATE_GAMEPAD_FINISH_ERROR_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate_GamepadFinishError, ALWAYS_ANIMATE)
    CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT = ZO_FadeSceneFragment:New(ZO_CharacterCreate_GamepadContainer, ALWAYS_ANIMATE)

    local function CharacterNameValidationCallback(isValid)
        if isValid then
            if ZO_CHARACTERCREATE_MANAGER:GetShouldPromptForTutorialSkip() and CanSkipTutorialArea() then
                ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(false)
                -- color the character name white so it's highlighted in the dialog
                local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
                local genderDecoratedCharacterName = ZO_SELECTED_TEXT:Colorize(GetGrammarDecoratedName(self.characterName, CharacterCreateGetGender(characterMode)))
                ZO_Dialogs_ShowGamepadDialog(SKIP_TUTORIAL_GAMEPAD_DIALOG, { characterName = self.characterName }, {mainTextParams = { genderDecoratedCharacterName }})
            else
                ZO_CharacterCreate_Gamepad_DoCreate(self.characterStartLocation, self.characterCreateOption)
            end
        else
            local errorReason = GetString("SI_CHARACTERCREATEEDITERROR", CHARACTER_CREATE_EDIT_ERROR_INVALID_NAME)
            ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})
        end
    end

    ZO_CharacterNaming_Gamepad_CreateDialog(self.control,
        {
            errorControl = ZO_CharacterCreate_GamepadFinishError,
            errorFragment = CHARACTER_CREATE_GAMEPAD_FINISH_ERROR_FRAGMENT,
            dialogName = CHARACTER_CREATE_GAMEPAD_DIALOG,
            dialogTitle = SI_CREATE_CHARACTER_GAMEPAD_FINISH_TITLE,
            dialogMainText = "",
            onBack = function() 
                if self.focusControl then
                    self.focusControl:EnableFocus(true)
                end
            end,
            onFinish = function(dialog)
                local characterName = dialog.selectedName
                self.characterName = characterName

                if characterName and #characterName > 0 then
                    if IsConsoleUI() then
                        PLAYER_CONSOLE_INFO_REQUEST_MANAGER:RequestNameValidation(characterName, CharacterNameValidationCallback)
                    else
                        CharacterNameValidationCallback(IsValidName(characterName))
                    end
                end
            end,
        })

    self:InitializeSkipTutorialDialog()

    self.currentGearPreviewIndex = 1

    -- MovementController for changing the option on the currently selected Focus
    self.movementControllerChangeGenericOption = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)

    -- MovementController for changing focus between controls
    self.movementControllerMoveFocus = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)

    self.focusControl = nil
end

local function CreateTriangle(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    local triangle = ZO_CharacterCreateTriangle_Gamepad:New(control, setterFn, updaterFn, triangleStringId, topStringId, leftStringId, rightStringId)
    triangle:SetOnValueChangedCallback(OnCharacterCreateOptionChanged)
    control.selectedCenterOffset = -140
    return triangle
end

function ZO_CharacterCreate_Gamepad:InitializeControls()
    self.control.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("CharacterCreateMainControlsFade", self.control)

    self.bucketsControl = self.control:GetNamedChild("ContainerInnerBuckets")
    self.sliderManager = CharacterCreateSliderManager:New(self.bucketsControl)

    self.allianceRadioGroup = ZO_RadioButtonGroup:New()
    self.raceRadioGroup = ZO_RadioButtonGroup:New()
    self.classRadioGroup = ZO_RadioButtonGroup:New()

    -- create the triangle controls
    local physiqueTriangleControl = CreateControlFromVirtual("$(parent)PhysiqueSelection", self.control, "ZO_CharacterCreateTriangleTemplate_Gamepad")
    self.physiqueTriangle = CreateTriangle(physiqueTriangleControl, SetPhysique, GetPhysique, SI_CREATE_CHARACTER_BODY_TRIANGLE_LABEL, SI_CREATE_CHARACTER_TRIANGLE_MUSCULAR, SI_CREATE_CHARACTER_TRIANGLE_FAT, SI_CREATE_CHARACTER_TRIANGLE_THIN)

    local faceTriangleControl = CreateControlFromVirtual("$(parent)FaceSelection", self.control, "ZO_CharacterCreateTriangleTemplate_Gamepad")
    self.faceTriangle = CreateTriangle(faceTriangleControl, SetFace, GetFace, SI_CREATE_CHARACTER_FACE_TRIANGLE_LABEL, SI_CREATE_CHARACTER_TRIANGLE_FACE_MUSCULAR, SI_CREATE_CHARACTER_TRIANGLE_FACE_FAT, SI_CREATE_CHARACTER_TRIANGLE_FACE_THIN)

    self:CreateGenderControl()

    self.containerControl = self.control:GetNamedChild("Container")

    self.containerControl:SetHandler("OnUpdate", function (...) self:ContainerOnUpdate(...) end)

    self.header = self.containerControl:GetNamedChild("HeaderContainerHeader")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)

    self.customBucketControls = 
    {
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_GENDER] = {control = self.genderSlider.control, updateFn = UpdateSlider, shouldAdd = true},
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE] = {control = ZO_CharacterCreate_GamepadAlliance, updateFn = function() self:UpdateRaceControl() end, shouldAdd = true},
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE] = {control = ZO_CharacterCreate_GamepadRace, updateFn = function() self:UpdateRaceControl() end, shouldAdd = true},
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS] = {control = ZO_CharacterCreate_GamepadClass, updateFn = function() self:UpdateClassControl() end, shouldAdd = true},
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_PHYSIQUE] = {control = physiqueTriangleControl, updateFn = UpdateSlider, randomizeFn = RandomizeSlider, shouldAdd = true},
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_FACE] = {control = faceTriangleControl, updateFn = UpdateSlider, randomizeFn = RandomizeSlider, shouldAdd = true},
    }
end

function ZO_CharacterCreate_Gamepad:InitializeSelectors()
    self:InitializeAllianceSelectors()
    self:InitializeRaceSelectors()
    self:InitializeClassSelectors()
    self:InitializeTemplatesDialog()
end

function ZO_CharacterCreate_Gamepad:OnCharacterCreateRequested()
    ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_CREATING")
end

function ZO_CharacterCreate_Gamepad:OnCharacterCreateFailed(reason)
    local errorReason = GetString("SI_CHARACTERCREATEEDITERROR", reason)

    -- Show the fact that the character could not be created.
    ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_FAILED_REASON", nil, {mainTextParams = {errorReason}})

    self.isCreating = false
end

function ZO_CharacterCreate_Gamepad:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self.currentGearPreviewIndex = 1

        self.scene:AddFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        ZO_CharacterCreate_GamepadCharacterViewport.Activate()
        SCENE_MANAGER:AddFragment(CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT)

        ZO_GamepadGenericHeader_Activate(self.header)
        GAMEPAD_BUCKET_MANAGER:Activate()

        -- Refresh the keybind strip after we activate our bucket since
        -- that may change our focus control which will impact the keybinds
        self:RefreshKeybindStrip()
    elseif newState == SCENE_HIDDEN then
        self.scene:RemoveFragment(KEYBIND_STRIP_GAMEPAD_FRAGMENT)
        ZO_CharacterCreate_GamepadCharacterViewport.Deactivate()
        SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_GAMEPAD_CONTAINER_FRAGMENT)

        if self.currentKeystrip then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeystrip)
            self.currentKeystrip = nil
        end

        self.isCreating = false

        ZO_GamepadGenericHeader_Deactivate(self.header)
        GAMEPAD_BUCKET_MANAGER:Deactivate()
    end
end

function ZO_CharacterCreate_Gamepad:InitializeSkipTutorialDialog()
    ZO_Dialogs_RegisterCustomDialog(SKIP_TUTORIAL_GAMEPAD_DIALOG,
    {
        mustChoose = true,
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = SI_PROMPT_TITLE_SKIP_TUTORIAL,
        },
        mainText = 
        {
            text = SI_PROMPT_BODY_SKIP_TUTORIAL,
        },
        buttons =
        {
            {
                text = SI_PROMPT_PLAY_TUTORIAL_BUTTON,
                keybind = "DIALOG_PRIMARY",
                callback =  function(dialog)
                                self:CreateCharacter(dialog.data.startLocation, CHARACTER_CREATE_DEFAULT_LOCATION)
                            end,
            },

            {
                text = SI_PROMPT_SKIP_TUTORIAL_BUTTON,
                keybind = "DIALOG_SECONDARY",
                callback =  function(dialog)
                                self:CreateCharacter(dialog.data.startLocation, CHARACTER_CREATE_SKIP_TUTORIAL)
                            end,
            },

            {
                text = SI_PROMPT_BACK_TUTORIAL_BUTTON,
                keybind = "DIALOG_NEGATIVE",
                callback =  function(dialog)
                                ZO_CharacterCreate_Gamepad_CancelSkipDialogue()
                                ZO_Dialogs_ShowGamepadDialog(CHARACTER_CREATE_GAMEPAD_DIALOG, { characterName = dialog.data.characterName })
                            end,
            },
        }
    })
end

do
    local function ReturnToCharacterSelect()
        PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
        GAMEPAD_CHARACTER_CREATE_MANAGER:ExitToState("CharacterSelect")
    end

    function ZO_CharacterCreate_Gamepad:GenerateKeybindingDescriptor()
        if self.isCreating then
            return nil  -- No keybind while creating
        end

        local keybindStripDescriptor =
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            {
                name = function()
                    return (self.focusControl and self.focusControl.primaryButtonName) or GetString(SI_GAMEPAD_SELECT_OPTION)
                end,
                keybind = "UI_SHORTCUT_PRIMARY",
                ethereal = not (self.focusControl and self.focusControl.showKeybind),

                callback = function()
                    ZO_CharacterCreate_Gamepad_OnPrimaryButtonPressed()
                end,
            },
            {
                name = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH),
                keybind = "UI_SHORTCUT_TERTIARY",

                callback = function()
                    if ZO_CHARACTERCREATE_MANAGER:GetCharacterMode() == CHARACTER_MODE_CREATION then
                        PlaySound(SOUNDS.GAMEPAD_MENU_FORWARD)
                        ZO_CharacterCreate_Gamepad_ShowFinishScreen()
                    else
                        self:SaveCharacterChanges()
                    end
                end,
            },
            {
                name = GetString(SI_CREATE_CHARACTER_GAMEPAD_RANDOMIZE),
                keybind = "UI_SHORTCUT_SECONDARY",

                callback = function()
                    ZO_CharacterCreate_Gamepad_RandomizeAppearance()
                end,
                sound = SOUNDS.CC_RANDOMIZE,
            },
            {
                name = GetString(SI_CREATE_CHARACTER_GAMEPAD_USE_TEMPLATE),
                keybind = "UI_SHORTCUT_LEFT_TRIGGER",

                callback = function()
                    PlaySound(SOUNDS.CC_GAMEPAD_CHARACTER_CLICK)
                    ZO_Dialogs_ShowGamepadDialog("CHARACTER_CREATE_TEMPLATE_SELECT")
                end,

                visible = function()
                        local shouldShow = false
                        if ZO_CHARACTERCREATE_MANAGER:GetCharacterMode() == CHARACTER_MODE_CREATION then
                            if GetTemplateStatus() then
                                local templates = self.characterData:GetTemplateInfo()
                                shouldShow = templates and #templates > 0
                            end
                        end
                        return shouldShow
                end,
            }
        }

        if self.focusControl and self.focusControl.CanLock then
            if self.focusControl.CanLock() then
                local keybindName
                local callbackSound
                if self.focusControl:IsLocked() then
                    keybindName = GetString(SI_CREATE_CHARACTER_GAMEPAD_UNLOCK_VALUE)
                    callbackSound = SOUNDS.CC_UNLOCK_VALUE
                else
                    keybindName = GetString(SI_CREATE_CHARACTER_GAMEPAD_LOCK_VALUE)
                    callbackSound = SOUNDS.CC_LOCK_VALUE
                end

                keybindStripDescriptor[#keybindStripDescriptor + 1] =
                    {
                        name = keybindName,
                        keybind = "UI_SHORTCUT_RIGHT_STICK",

                        callback = function()
                            self.focusControl:ToggleLocked()
                            PlaySound(callbackSound)
                            self:RefreshKeybindStrip()
                        end,
                    }
            end
        end

        local gearPreviews
        if ZO_CHARACTERCREATE_MANAGER:GetCharacterMode() == CHARACTER_MODE_CREATION then
            gearPreviews = CHARACTER_CREATE_PREVIEW_GEAR_INFO
        else
            gearPreviews = CHARACTER_EDIT_PREVIEW_GEAR_INFO
        end

        local nextGear = (self.currentGearPreviewIndex % #gearPreviews) + 1
        local name = gearPreviews[nextGear].name

        keybindStripDescriptor[#keybindStripDescriptor + 1] =
        {
            name = name,
            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",

            callback = function()
                self.currentGearPreviewIndex = (self.currentGearPreviewIndex % #gearPreviews) + 1

                gearPreviews[self.currentGearPreviewIndex].OnSelectedCallback()
                PlaySound(SOUNDS.CC_PREVIEW_GEAR)

                self:RefreshKeybindStrip()
            end,
        }

        local state = PregameStateManager_GetPreviousState()
        local numCharacters = GetNumCharacters()
        if (state == "CharacterSelect" or state == "CharacterSelect_FromCinematic") and numCharacters > 0 then
            keybindStripDescriptor[#keybindStripDescriptor + 1] = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ReturnToCharacterSelect)
        elseif numCharacters == 0 then
            -- mimic the behavior from the character select screen
            keybindStripDescriptor[#keybindStripDescriptor + 1] = KEYBIND_STRIP:GenerateGamepadBackButtonDescriptor(ZO_Disconnect)
        end

        return keybindStripDescriptor
    end
end

-- Can't simply return (currentStrip ~= newStrip) because ZoKeybindStrip stores additional 
-- variables on the descriptor (such as currentStrip.handledDown). This causes an altered
-- version of the keybind strip to differ from an unaltered version of the same strip.
local function ShouldRefreshKeybindStrip(currentStrip, newStrip)
    local stripsExist = currentStrip and newStrip

    if stripsExist then
        -- if the strips have the same number of buttons see if they are all the same
        if #currentStrip == #newStrip then
            for i = 1, #currentStrip do
                local currentButton = currentStrip[i]
                local newButton = newStrip[i]

                if currentButton.name ~= newButton.name then
                    return true
                end
            end
            -- all the buttons are the same in the strips, so don't refresh
            return false
        end
    end

    -- the keybind strips don't match so we should refresh
    return true
end

function ZO_CharacterCreate_Gamepad:RefreshKeybindStrip()
    local keybindStrip = self:GenerateKeybindingDescriptor()
    local removed = true

    if ShouldRefreshKeybindStrip(self.currentKeystrip, keybindStrip) then
        if self.currentKeystrip then
            removed = KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currentKeystrip)
        end

        -- won't try to replace keybind strip if there's a current one and it wasn't removed
        -- this occurs when current descriptor is pushed to stack, so can't be found
        if removed then
            self.currentKeystrip = keybindStrip

            if self.currentKeystrip then
                KEYBIND_STRIP:RemoveDefaultExit()
                KEYBIND_STRIP:AddKeybindButtonGroup(self.currentKeystrip)
            end
        end
    end
end

function ZO_CharacterCreate_Gamepad:SetFocus(newFocusControl)
    local oldFocusControl = self.focusControl

    if newFocusControl and oldFocusControl and oldFocusControl ~= newFocusControl then
        if newFocusControl.SetHighlightIndexByColumn and oldFocusControl.GetHighlightColumn then
            -- Highlight the current selection
            newFocusControl:SetHighlightIndexByColumn(oldFocusControl:GetHighlightColumn(), newFocusControl:GetFocusIndex() > oldFocusControl:GetFocusIndex())
        end
    end

    if oldFocusControl ~= nil and oldFocusControl.EnableFocus then
        oldFocusControl:EnableFocus(false)
    end

    self.focusControl = newFocusControl
    if newFocusControl ~= nil and newFocusControl.EnableFocus then
        newFocusControl:EnableFocus(true)
    end

    if not self.control:IsHidden() then
        self:RefreshKeybindStrip()
    end
end

function ZO_CharacterCreate_Gamepad:GetNextFocus(control)
    if control == nil then
        return nil
    end

    local bucket = control.info.bucketIndex
    local index = control.info.index

    while index < #(ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD[bucket].controls) do
        index = index + 1

        local newControl = self.controls[bucket][index]
        if newControl then
            return newControl
        end
    end

    return control
end

function ZO_CharacterCreate_Gamepad:GetPreviousFocus(control)
    if control == nil then
        return nil
    end

    local bucket = control.info.bucketIndex
    local index = control.info.index

    while index > 1 do
        index = index - 1

        local newControl = self.controls[bucket][index]
        if newControl then
            return newControl
        end
    end

    return control
end

-- Creator Control Initialization

function ZO_CharacterCreate_Gamepad:UpdateGenderSpecificText(currentGender)
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    currentGender = currentGender or CharacterCreateGetGender(characterMode)

    ZO_CharacterCreate_GamepadLoreInfoRaceName:SetText(zo_strformat(SI_RACE_NAME, GetRaceName(currentGender, CharacterCreateGetRace(characterMode))))
    ZO_CharacterCreate_GamepadLoreInfoClassName:SetText(zo_strformat(SI_CLASS_NAME, GetClassName(currentGender, CharacterCreateGetClass(characterMode))))
end

local function SetSelectorsControlSelectedCenterOffset(control, numSelectors)
    if control then
        if numSelectors > GAMEPAD_SELECTOR_STRIDE then
            control.selectedCenterOffset = zo_ceil((numSelectors - GAMEPAD_SELECTOR_STRIDE) / GAMEPAD_SELECTOR_STRIDE) * SELECTOR_PER_ROW_CENTER_OFFSET
        else
            control.selectedCenterOffset = 0
        end
    end
end

-- override of ZO_CharacterCreate_Base:SetSelectorButtonEnabled
function ZO_CharacterCreate_Gamepad:SetSelectorButtonEnabled(selectorButton, radioGroup, enabled)
    radioGroup:SetButtonIsValidOption(selectorButton, enabled)

    local alpha = enabled and 1 or 0.5
    selectorButton:SetAlpha(alpha)
end

function ZO_CharacterCreate_Gamepad:InitializeSelectorButtonTextures(buttonControl, data)
    buttonControl:SetNormalTexture(data.gamepadNormalIcon)
    buttonControl:SetPressedTexture(data.gamepadPressedIcon)
end

function ZO_CharacterCreate_Gamepad:InitializeAllianceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreate_GamepadAllianceAllianceSelector1,
        ZO_CharacterCreate_GamepadAllianceAllianceSelector2,
        ZO_CharacterCreate_GamepadAllianceAllianceSelector3,
    }

    local alliances = self.characterData:GetAllianceInfo()
    for _, alliance in ipairs(alliances) do
        local selector = layoutTable[alliance.position]
        self:InitializeAllianceSelector(selector, alliance)
    end

    SetSelectorsControlSelectedCenterOffset(ZO_CharacterCreate_GamepadAlliance, #alliances)
end

function ZO_CharacterCreate_Gamepad:InitializeRaceSelectors()
    local layoutTable =
    {
        ZO_CharacterCreate_GamepadRaceColumn11,
        ZO_CharacterCreate_GamepadRaceColumn21,
        ZO_CharacterCreate_GamepadRaceColumn31,
        ZO_CharacterCreate_GamepadRaceColumn12,
        ZO_CharacterCreate_GamepadRaceColumn22,
        ZO_CharacterCreate_GamepadRaceColumn32,
        ZO_CharacterCreate_GamepadRaceColumn13,
        ZO_CharacterCreate_GamepadRaceColumn23,
        ZO_CharacterCreate_GamepadRaceColumn33,
        ZO_CharacterCreate_GamepadRaceSingleButton,
    }

    -- Hide and reset buttons
    for i, button in ipairs(layoutTable) do
        button:SetHidden(true)
        button.nameFn = nil
        button.defId = nil
        button.alliance = nil
    end

    -- We either need to show 3, 4, 9, or 10 buttons
    -- 3 if they can't play any race any alliance or imperial
    -- 4 if they can't play any race any alliance but can play as imperial
    -- 9 if they can play any race any alliance but not imperial
    -- 10 if they can play any race any alliance and imperial
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local selectedAlliance = CharacterCreateGetAlliance(characterMode)
    local position = 1

    local races = self.characterData:GetRaceInfo()
    for i, race in ipairs(races) do
        if race.alliance == 0 or race.alliance == selectedAlliance or CanPlayAnyRaceAsAnyAlliance() then
            race.position = position
            position = position + 1
        else
            race.position = GAMEPAD_SELECTOR_IGNORE_POSITION
        end
    end

    local raceObject = ZO_CharacterCreate_GamepadRace
    raceObject.numButtons = position - 1

    SetSelectorsControlSelectedCenterOffset(raceObject, raceObject.numButtons)

    for i, race in ipairs(races) do
        if race.position == GAMEPAD_SELECTOR_IGNORE_POSITION then
            --nothing for now
        else
            local raceButton = layoutTable[race.position]
            -- If there are 4 buttons we should center the final button
            if raceObject.numButtons == 4 and raceObject.numButtons == race.position then
                raceButton = layoutTable[5]
            end
            raceButton:SetHidden(false)
            self:InitializeSelectorButton(raceButton, race, self.raceRadioGroup)
            self:AddRaceSelectionDataToSelector(raceButton, race)
        end
    end
end

function ZO_CharacterCreate_Gamepad:SetValidRace()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentRaceId = CharacterCreateGetRace(characterMode)
    local currentAlliance = CharacterCreateGetAlliance(characterMode)

    local currentRace = self.characterData:GetRaceForRaceDef(currentRaceId)
    if currentRace then
        if currentRace.alliance == 0 or currentRace.alliance == currentAlliance or CanPlayAnyRaceAsAnyAlliance() then
            return
        end
    end

    local races = self.characterData:GetRaceInfo()
    for i, race in ipairs(races) do
        if race.alliance == 0 or race.alliance == currentAlliance or CanPlayAnyRaceAsAnyAlliance() then
            GAMEPAD_CHARACTER_CREATE_MANAGER:SetRace(race.race, "preventAllianceChange")
            return
        end
    end
end

function ZO_CharacterCreate_Gamepad:UpdateRaceControl()
    self:InitializeRaceSelectors()

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentRace = CharacterCreateGetRace(characterMode)

    local function IsRaceClicked(button)
        return button.defId == currentRace
    end

    self.raceRadioGroup:UpdateFromData(IsRaceClicked)
    ZO_CharacterCreate_GamepadRace.sliderObject:UpdateButtons()

    -- if we're focused on race, refocus to update name
    if ZO_CharacterCreate_GamepadRace.sliderObject.focused then
        ZO_CharacterCreate_GamepadRace.sliderObject:FocusButton(true)
    end

    local currentAlliance = CharacterCreateGetAlliance(characterMode)

    local function IsAllianceClicked(button)
        return button.defId == currentAlliance
    end

    self.allianceRadioGroup:UpdateFromData(IsAllianceClicked)
    ZO_CharacterCreate_GamepadAlliance.sliderObject:UpdateButtons()

    local race = self.characterData:GetRaceForRaceDef(currentRace)
    if race then
        self:UpdateGenderSpecificText()

        ZO_CharacterCreate_GamepadLoreInfoRaceDescription:SetText(race.lore)

        ZO_CharacterCreate_GamepadLoreInfoRaceIcon:SetTexture(race.gamepadPressedIcon)

        local alliance = self.characterData:GetAllianceForAllianceDef(currentAlliance)
        ZO_CharacterCreate_GamepadLoreInfoAllianceIcon:SetTexture(alliance.gamepadPressedIcon)
        ZO_CharacterCreate_GamepadLoreInfoAllianceName:SetText(zo_strformat(SI_ALLIANCE_NAME, alliance.name))
        ZO_CharacterCreate_GamepadLoreInfoAllianceDescription:SetText(alliance.lore)
    end
end

function ZO_CharacterCreate_Gamepad:UpdateClassControl()
    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local currentClass = CharacterCreateGetClass(characterMode)

    local function IsClassClicked(button)
        return button.defId == currentClass
    end

    self.classRadioGroup:UpdateFromData(IsClassClicked)
    ZO_CharacterCreate_GamepadClass.sliderObject:UpdateButtons()

    local class = self.characterData:GetClassForClassDef(currentClass)
    if class then
        self:UpdateGenderSpecificText()
        ZO_CharacterCreate_GamepadLoreInfoClassIcon:SetTexture(class.gamepadPressedIcon)
        ZO_CharacterCreate_GamepadLoreInfoClassDescription:SetText(class.lore)
    end
end

local function UpdateSlider(slider)
    slider.sliderObject:Update()
end

local function FindBucketFromName(type, name)
    for k,v in pairs(ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD) do
        if v.controls then
            for index, item in ipairs(v.controls) do
                if item[1] == type and item[2] == name then
                    return k, index
                end
            end
        end
    end
    return nil
end

local function ControlComparator(data1, data2)
    local bucket1, index1 = data1.bucketIndex, data1.index
    local bucket2, index2 = data2.bucketIndex, data2.index

    if bucket1 == nil then
        return false
    elseif bucket2 == nil then
        return true
    end

    if bucket1 ~= bucket2 then
        return bucket1 < bucket2
    end

    return index1 < index2
end

function ZO_CharacterCreate_Gamepad:CreateGenderControl()
    self.genderSlider = self.sliderManager:AcquireObject(CHARACTER_CREATE_SLIDER_TYPE_GENDER)
    self.genderSlider:SetData()
end

function ZO_CharacterCreate_Gamepad:ResetControls()
    -- If this was being suppressed changes MUST be applied now or there will be no slider data to build
    SetSuppressCharacterChanges(false)

    self.sliderManager:ReleaseAllObjects()

    GAMEPAD_BUCKET_MANAGER:Reset()

    local controlData = {}

    self.controls = {}

    -- Sliders
    for i = 1, GetNumSliders() do
        local name, category, steps, value, defaultValue = GetSliderInfo(i)

        if name then
            local slider = self.sliderManager:AcquireObject(CHARACTER_CREATE_SLIDER_TYPE_SLIDER)
            slider:SetData(i, name, category, steps, value, defaultValue)

            local bucketIndex, index = FindBucketFromName(GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, name)

            if bucketIndex then
                local info = { bucketIndex = bucketIndex, index = index, type = GAMEPAD_BUCKET_CONTROL_TYPE_SLIDER, name = name, control = slider.control, updateFn = UpdateSlider, randomizeFn = RandomizeSlider }
                slider.info = info
                controlData[#controlData + 1] = info
                self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                self.controls[bucketIndex][index] = slider
            else
                slider.control:SetHidden(true)       -- Hide unused controls
            end
        end
    end

    -- Appearances
    for i = 1, GetNumAppearances() do
        local name, appearanceType, numValues, displayName = GetAppearanceInfo(i)

        if numValues > 0 then
            local slider = self.sliderManager:AcquireObject(appearanceType)
            slider:SetData(name, numValues, displayName)

            local bucketIndex, index = FindBucketFromName(GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, name)

            if bucketIndex then
                local info = { bucketIndex = bucketIndex, index = index, type = GAMEPAD_BUCKET_CONTROL_TYPE_APPEARANCE, name = name, control = slider.control, updateFn = UpdateSlider, randomizeFn = RandomizeSlider }
                slider.info = info
                controlData[#controlData + 1] = info
                self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                self.controls[bucketIndex][index] = slider
            else
                slider.control:SetHidden(true)       -- Hide unused controls
            end
        end
    end

    -- Custom controls
    local customControls = self.customBucketControls
    for bucketIndex, bucket in pairs(ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD) do
        if bucket.controls then
            for index, controlItem in ipairs(bucket.controls) do
                if controlItem[1] == GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM then
                    local controlInfo = customControls[ controlItem[2] ]

                    if controlInfo.shouldAdd then
                        local control = controlInfo.control
                        if type(control) == "function" then
                            control = control()
                        end

                        local info =    {
                                            index = index,
                                            type = GAMEPAD_BUCKET_CONTROL_TYPE_CUSTOM,
                                            bucketIndex = bucketIndex,
                                            control = control,
                                            updateFn = controlInfo.updateFn,
                                            randomizeFn = controlInfo.randomizeFn
                                        }

                        control.sliderObject = control.sliderObject or {}
                        control.sliderObject.info = info
                        controlData[#controlData + 1] = info
                        self.controls[bucketIndex] = self.controls[bucketIndex] or {}
                        self.controls[bucketIndex][index] = control.sliderObject
                    end
                end
            end
        end
    end

    table.sort(controlData, ControlComparator)

    for _, orderingData in ipairs(controlData) do
        GAMEPAD_BUCKET_MANAGER:AddControl(orderingData.control, orderingData.bucketIndex, orderingData.updateFn, orderingData.randomizeFn)
    end

    for category, bucket in pairs(ZO_CHARACTER_CREATE_BUCKET_WINDOW_DATA_GAMEPAD) do
        GAMEPAD_BUCKET_MANAGER:SetEnabled(category, (self.controls[category] ~= nil))
    end

    GAMEPAD_BUCKET_MANAGER:Finalize()

    -- TODO: this fixes a bug where the triangles don't reflect the correct data...there will be more fixes to pregameCharacterManager to address the real issue
    -- (where the triangle data needs to live on its own rather than being tied to the unit)
    self.physiqueTriangle:Update()
    self.faceTriangle:Update()
end

function ZO_CharacterCreate_Gamepad:OnGenerateRandomCharacter()
    ZO_CharacterCreate_Gamepad_RandomizeAppearance("initial")
end

function ZO_CharacterCreate_Gamepad:Reset()
    -- Sanity check
    if not IsPregameCharacterConstructionReady() then
        return
    end

    SetCharacterCameraZoomAmount(-1) -- zoom all the way out when a reset happens
    SetSuppressCharacterChanges(true) -- this will be disabled later, right before controls are reset

    local controlsInitialized = false

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    if characterMode == CHARACTER_MODE_CREATION then
        controlsInitialized = self:GenerateRandomCharacter()
    end

    if not controlsInitialized then
        self:ResetControls()
    end

    GAMEPAD_BUCKET_MANAGER:SwitchBuckets(INITIAL_BUCKET)
    GAMEPAD_BUCKET_MANAGER:SwitchBucketsInternal(INITIAL_BUCKET)
    GAMEPAD_BUCKET_MANAGER:UpdateControlsFromData()

    self.characterStartLocation = nil
    ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true)
    self.characterCreateOption = CHARACTER_CREATE_DEFAULT_LOCATION
end

local function AddClassSelectionDataToSelector(buttonControl, classData)
    buttonControl.nameFn = GetClassName
    buttonControl.defId = classData.class
end

function ZO_CharacterCreate_Gamepad:InitializeClassSelectors()
    local classes = self.characterData:GetClassInfo()
    local numClasses = #classes
    local layoutTable
    -- TODO: Create these controls dynamically
    if numClasses <= 4 then
        -- 4 is the default number of classes and they are laid out
        -- so that the fourth class is i nthe middle column
        layoutTable = {
            ZO_CharacterCreate_GamepadClassColumn11,
            ZO_CharacterCreate_GamepadClassColumn21,
            ZO_CharacterCreate_GamepadClassColumn31,
            ZO_CharacterCreate_GamepadClassColumn22,
        }
    elseif numClasses <= 6 then
        -- if we have 5 or 6 classes, then we can lay them out normally
        -- from left to right without worrying about centering one
        layoutTable = {
            ZO_CharacterCreate_GamepadClassColumn11,
            ZO_CharacterCreate_GamepadClassColumn21,
            ZO_CharacterCreate_GamepadClassColumn31,
            ZO_CharacterCreate_GamepadClassColumn12,
            ZO_CharacterCreate_GamepadClassColumn22,
            ZO_CharacterCreate_GamepadClassColumn32,
        }
    else -- numClasses > CHARACTER_CREATE_MAX_SUPPORTED_CLASSES
        -- we aren't dynamically creating controls and we are out of controls
        -- more controls will have to be added to the XML and additional logic to correctly lay them out
        -- this assert is also duplicated in the keyboard UI so that non-console builds will catch the issue as well
        local errorString = string.format("The gamepad UI currently only supports up to %d classes, but there are currently %d classes used", CHARACTER_CREATE_MAX_SUPPORTED_CLASSES, numClasses)
        assert(false, errorString)
    end

    -- Hide buttons
    for i, button in ipairs(layoutTable) do
        button:SetHidden(true)
    end

    for i, class in ipairs(classes) do
        class.position = i
        local classButton = layoutTable[i]
        assert(classButton ~= nil, "Unable to get class button for class #" .. i)
        self:InitializeSelectorButton(classButton, class, self.classRadioGroup)
        AddClassSelectionDataToSelector(classButton, class)
    end

    SetSelectorsControlSelectedCenterOffset(ZO_CharacterCreate_GamepadClass, numClasses)
end

local function SetRandomizeAppearanceEnabled(enabled)
    g_randomizeAppearanceEnabled = enabled
end

function ZO_CharacterCreate_Gamepad:SetTemplate(templateId)
    local templateData = self.characterData:GetTemplate(templateId)
        if not templateData then
            return false
        end

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    if not templateData.isSelectable or CharacterCreateGetTemplate(characterMode) == templateId then
            return false
        end

    CharacterCreateSetTemplate(templateId)

    GAMEPAD_BUCKET_MANAGER:SwitchBuckets(CREATE_BUCKET_RACE)

    -- Disable appearance related controls if the appearance is overridden in the template.
    local enabled = not templateData.overrideAppearance
    GAMEPAD_BUCKET_MANAGER:SetEnabled(CREATE_BUCKET_BODY, enabled)
    GAMEPAD_BUCKET_MANAGER:SetEnabled(CREATE_BUCKET_FACE, enabled)

    SetRandomizeAppearanceEnabled(enabled)

    local validRaces = {}
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), templateData, self.raceRadioGroup, validRaces)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), templateData, self.classRadioGroup)

    local validAlliances = {}
    self.characterData:UpdateAllianceSelectability()
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), templateData, self.allianceRadioGroup, validAlliances)

    if templateData.gender ~= 0 then
        self.genderSlider:ToggleLocked()
    end

    -- Pick a race
    if templateData.race ~= 0 then
        CharacterCreateSetRace(templateData.race)
    else
        CharacterCreateSetRace(self.characterData:PickRandomRace(validRaces))
    end

    -- Pick an alliance 
    local alliance = templateData.alliance
    if alliance == 0 then
        -- (never random unless a race without a fixed alliance is picked)
        alliance = self.characterData:GetRaceForRaceDef(CharacterCreateGetRace(characterMode)).alliance
        if alliance == 0 then
            alliance = self.characterData:PickRandomAlliance(validAlliances)
        end
    end
    self:SetAlliance(alliance, "preventRaceChange")

    -- Pick a class
    if templateData.class ~= 0 then
        CharacterCreateSetClass(templateData.class)
    else
        self:PickRandomSelectableClass()
    end
    
    -- Pick a gender
    if templateData.gender ~= 0 then
        CharacterCreateSetGender(templateData.gender)
    else
        self:PickRandomGender()
    end

    -- Make the controls match what you picked...
    self:UpdateRaceControl()
    self:UpdateClassControl()
    self.genderSlider:Update()
    if not templateData.overrideAppearance then
        ZO_CharacterCreate_Gamepad_RandomizeAppearance("initial")
    else
        InitializeAppearanceFromTemplate(templateId)
    end
    return true
end

function ZO_CharacterCreate_Gamepad:InitializeTemplatesDialog()
    local templates = self.characterData:GetTemplateInfo()

    local dialogDescription = 
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC
        },

        setup = function(dialog)
            dialog:setupFunc()
        end,

        title =
        {
            text = GetString(SI_CREATE_CHARACTER_TEMPLATE_SELECT_TITLE),
        },

        mainText = 
        {
            text = GetString(SI_CREATE_CHARACTER_TEMPLATE_SELECT_DESCRIPTION),
        },

        parametricList = {},
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local selectedData = dialog.entryList:GetTargetData()
                    if selectedData and selectedData.callback then
                        selectedData.callback()
                    end
                end,
            },

            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
            },

        }
    }

    for index, characterTemplate in ipairs(templates) do
        local data =
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData = {
                isHome = true,
                text = characterTemplate.name,
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function() 
                    self:SetTemplate(characterTemplate.template)
                end,
            },
        }

        table.insert(dialogDescription.parametricList, data)
    end
    
    ZO_Dialogs_RegisterCustomDialog("CHARACTER_CREATE_TEMPLATE_SELECT", dialogDescription)
end

function ZO_CharacterCreate_Gamepad:CreateCharacter(startLocation, createOption)
    if not self.isCreating then
        self.isCreating = true
        ZO_CharacterCreate_Base.CreateCharacter(self, startLocation, createOption)
    end
end

do
    -- Lore Info Controls

    local CREATE_LORE_INFO_CONTROLS =
    {
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE] = {
            "AllianceIcon",
            "AllianceName",
            "AllianceDescription",
        },
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE] = {
            "RaceIcon",
            "RaceName",
            "RaceDescription",
        },
        [GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS] = {
            "ClassIcon",
            "ClassName",
            "ClassDescription",
        },
    }

    function ZO_CharacterCreate_Gamepad:ShowLoreInfo(type)
        SCENE_MANAGER:AddFragment(CHARACTER_CREATE_GAMEPAD_LORE_INFO_FRAGMENT)
        SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)

        for sourceType, t in pairs(CREATE_LORE_INFO_CONTROLS) do
            for i, control in pairs(t) do
                ZO_CharacterCreate_GamepadLoreInfo:GetNamedChild(control):SetHidden(type ~= sourceType)
            end
        end
    end
end

function ZO_CharacterCreate_Gamepad:HideLoreInfo()
    SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_GAMEPAD_LORE_INFO_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_4_BACKGROUND_FRAGMENT)
end


function ZO_CharacterCreate_Gamepad:ShowInformationTooltip(title, description)
    SCENE_MANAGER:AddFragment(CHARACTER_CREATE_GAMEPAD_INFORMATION_TOOLTIP_FRAGMENT)
    SCENE_MANAGER:AddFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)

    local infoTooltip = CHARACTER_CREATE_GAMEPAD_INFORMATION_TOOLTIP_FRAGMENT:GetControl()

    local titleLabel = infoTooltip:GetNamedChild("ContainerTitle")
    titleLabel:SetText(title)

    local descriptionLabel = infoTooltip:GetNamedChild("ContainerDescription")
    descriptionLabel:SetText(description)
end

function ZO_CharacterCreate_Gamepad:HideInformationTooltip()
    SCENE_MANAGER:RemoveFragment(CHARACTER_CREATE_GAMEPAD_INFORMATION_TOOLTIP_FRAGMENT)
    SCENE_MANAGER:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_BACKGROUND_FRAGMENT)
end

-- XML Handlers and global functions

function ZO_CharacterCreate_Gamepad_RandomizeAppearance(randomizeType)
    if g_randomizeAppearanceEnabled then
        GAMEPAD_BUCKET_MANAGER:RandomizeAppearance(randomizeType)
    end
end

function ZO_CharacterCreate_Gamepad:ContainerOnUpdate()
    if self.focusControl and self.focusControl.disableFocusMovementController then
        -- Just do focus update
        if self.focusControl and self.focusControl.FocusUpdate then
            self.focusControl:FocusUpdate()
        end
        return
    end

    -- Handle Generic Option changes
    local changeOption = self.movementControllerChangeGenericOption:CheckMovement()

    if changeOption == MOVEMENT_CONTROLLER_MOVE_NEXT then
        if self.focusControl and self.focusControl.MoveNext then
            self.focusControl:MoveNext()
        end
    elseif changeOption == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        if self.focusControl and self.focusControl.MovePrevious then
            self.focusControl:MovePrevious()
        end
    end

    local moveFocus = self.movementControllerMoveFocus:CheckMovement()

    local updatedFocusControl = false
    if self.focusControl and self.focusControl.FocusUpdate then
        updatedFocusControl = self.focusControl:FocusUpdate(moveFocus)
    end

    if not updatedFocusControl then
      -- Allow the bucketManager to consume the input
        if moveFocus == MOVEMENT_CONTROLLER_MOVE_NEXT then
            GAMEPAD_BUCKET_MANAGER:MoveNext()
        elseif moveFocus == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
            GAMEPAD_BUCKET_MANAGER:MovePrevious()
        end
    end
end

function ZO_CharacterCreate_Gamepad:InitializeForEditChanges(characterInfo, mode)
    self:SetCharacterCreateMode(mode)

    local raceTemplate = characterInfo
    local customControls = self.customBucketControls
    if mode == CHARACTER_CREATE_MODE_EDIT_RACE then
        raceTemplate =  {
                            race = 0,
                            alliance = characterInfo.alliance,
                        }
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE].shouldAdd = false
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE].shouldAdd = true
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS].shouldAdd = false
    elseif mode == CHARACTER_CREATE_MODE_EDIT_APPEARANCE then
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE].shouldAdd = false
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE].shouldAdd = false
        customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS].shouldAdd = false
    end

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), raceTemplate, self.raceRadioGroup)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), characterInfo, self.classRadioGroup)

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), characterInfo, self.allianceRadioGroup)

    self:Reset()

    -- Make the controls match what you picked...
    self:UpdateRaceControl()
    self:UpdateClassControl()
    self.genderSlider:Update()
end

function ZO_CharacterCreate_Gamepad:InitializeForAppearanceChange(characterInfo)
    self:InitializeForEditChanges(characterInfo, CHARACTER_CREATE_MODE_EDIT_APPEARANCE)
end

function ZO_CharacterCreate_Gamepad:InitializeForRaceChange(characterInfo)
    self:InitializeForEditChanges(characterInfo, CHARACTER_CREATE_MODE_EDIT_RACE)
end

function ZO_CharacterCreate_Gamepad:InitializeForCharacterCreate()
    self:SetCharacterCreateMode(CHARACTER_CREATE_MODE_CREATE)

    local customControls = self.customBucketControls
    customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_ALLIANCE].shouldAdd = true
    customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_RACE].shouldAdd = true
    customControls[GAMEPAD_BUCKET_CUSTOM_CONTROL_CLASS].shouldAdd = true

    local characterMode = ZO_CHARACTERCREATE_MANAGER:GetCharacterMode()
    local templateData = self.characterData:GetTemplate(CharacterCreateGetTemplate(characterMode))
    -- we may not have any template selected or we have no templates
    -- so create a default template with no restrictions
    if templateData == nil then
        templateData = self.characterData:GetNoneTemplate()
    end

    self:UpdateSelectorsForTemplate(function(...) return self:UpdateRaceSelectorsForTemplate(...) end, self.characterData:GetRaceInfo(), templateData, self.raceRadioGroup)
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateClassSelectorsForTemplate(...) end, self.characterData:GetClassInfo(), templateData, self.classRadioGroup)

    self.characterData:UpdateAllianceSelectability()
    self:UpdateSelectorsForTemplate(function(...) return self:UpdateAllianceSelectorsForTemplate(...) end, self.characterData:GetAllianceInfo(), templateData, self.allianceRadioGroup)

    -- make sure the controls appear correctly
    self:ResetControls()

    -- Make the controls match what you picked...
    self:UpdateRaceControl()
    self:UpdateClassControl()
    self.genderSlider:Update()
end


function ZO_CharacterCreate_Gamepad_ShowFinishScreen()
    GAMEPAD_BUCKET_MANAGER.isCreating = false
    GAMEPAD_CHARACTER_CREATE_MANAGER.focusControl:EnableFocus(false)

    ZO_Dialogs_ShowGamepadDialog(CHARACTER_CREATE_GAMEPAD_DIALOG)
end

function ZO_CharacterCreate_Gamepad_Initialize(control)
    -- Gamepad pregame is only available to consoles or clients set to force the console flow
    -- so we won't create this on PC for some efficiency
    if IsInGamepadPreferredMode() then
        GAMEPAD_CHARACTER_CREATE_MANAGER = ZO_CharacterCreate_Gamepad:New(control)
        SYSTEMS:RegisterGamepadObject(ZO_CHARACTER_CREATE_SYSTEM_NAME, GAMEPAD_CHARACTER_CREATE_MANAGER)

        local containerBuckets = control:GetNamedChild("ContainerInnerBuckets")
        GAMEPAD_BUCKET_MANAGER = ZO_CharacterCreateBucketManager_Gamepad:New(containerBuckets)
    end
end

function ZO_CharacterCreate_Gamepad_OnPrimaryButtonPressed()
    if GAMEPAD_CHARACTER_CREATE_MANAGER.focusControl ~= nil and GAMEPAD_CHARACTER_CREATE_MANAGER.focusControl.OnPrimaryButtonPressed then
        GAMEPAD_CHARACTER_CREATE_MANAGER.focusControl:OnPrimaryButtonPressed()
    end
end

function ZO_CharacterCreate_Gamepad_DoCreate(startLocation, createOption)
    GAMEPAD_CHARACTER_CREATE_MANAGER:CreateCharacter(startLocation, createOption)
end

function ZO_CharacterCreate_Gamepad_CancelSkipDialogue()
    GAMEPAD_CHARACTER_CREATE_MANAGER.isCreating = false
    ZO_CHARACTERCREATE_MANAGER:SetShouldPromptForTutorialSkip(true) -- should be prompted for tutorial again
end

function ZO_CharacterCreate_Gamepad_IsCreating()
    return GAMEPAD_CHARACTER_CREATE_MANAGER.isCreating
end

function ZO_CharacterCreate_Gamepad_OnSelectorPressed(button)
    local selectorHandlers =
    {
        [CHARACTER_CREATE_SELECTOR_RACE] =  function(button)
                        GAMEPAD_CHARACTER_CREATE_MANAGER:SetRace(button.defId)
                        GAMEPAD_CHARACTER_CREATE_MANAGER:UpdateRaceControl()
                    end,

        [CHARACTER_CREATE_SELECTOR_CLASS] = function(button)
                        CharacterCreateSetClass(button.defId)
                        GAMEPAD_CHARACTER_CREATE_MANAGER:UpdateClassControl()
                    end,

        [CHARACTER_CREATE_SELECTOR_ALLIANCE] =  function(button)
                            GAMEPAD_CHARACTER_CREATE_MANAGER:SetAlliance(button.defId, "preventRaceChange")
                            local oldPosition = ZO_CharacterCreate_GamepadRace.sliderObject:GetSelectedIndex()

                            GAMEPAD_CHARACTER_CREATE_MANAGER:InitializeRaceSelectors()

                            local newButton = ZO_CharacterCreate_GamepadRace.sliderObject:GetButton(oldPosition)
                            if newButton then
                                GAMEPAD_CHARACTER_CREATE_MANAGER:SetRace(newButton.defId)
                            else
                                GAMEPAD_CHARACTER_CREATE_MANAGER:SetValidRace()
                            end

                            GAMEPAD_CHARACTER_CREATE_MANAGER:UpdateRaceControl()
                        end,
    }

    local handler = selectorHandlers[button.selectorType]
    if handler then
        OnCharacterCreateOptionChanged()
        handler(button)
        PlaySound(SOUNDS.CC_GAMEPAD_CHARACTER_CLICK)
    end
end

function ZO_CharacterCreate_Gamepad_CreateAllianceSelector(control)
    ZO_CharacterCreateAllianceSelector_Gamepad:New(control)
end

function ZO_CharacterCreate_Gamepad_CreateRaceSelector(control)
    ZO_CharacterCreateRaceSelector_Gamepad:New(control)
end

function ZO_CharacterCreate_Gamepad_CreateClassSelector(control)
    ZO_CharacterCreateClassSelector_Gamepad:New(control)
end

function ZO_CharacterCreate_GamepadLoreInfo_Initialize(control)
    local ALWAYS_ANIMATE = true
    CHARACTER_CREATE_GAMEPAD_LORE_INFO_FRAGMENT = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
end

function ZO_CharacterCreate_GamepadInformationTooltip_Initialize(control)
    local ALWAYS_ANIMATE = true
    CHARACTER_CREATE_GAMEPAD_INFORMATION_TOOLTIP_FRAGMENT = ZO_FadeSceneFragment:New(control, ALWAYS_ANIMATE)
end

do
    local paperDollInputObject =
    {
        UpdateDirectionalInput = function(self)
            local mx, my = DIRECTIONAL_INPUT:GetXY(ZO_DI_RIGHT_STICK)
            if zo_abs(mx) > zo_abs(my) then
                local scalex = -6.0
                if mx ~= 0 then
                    CharacterCreateStartMouseSpin(mx * scalex)
                else
                    CharacterCreateStopMouseSpin()
                end
                StopCharacterCameraZoom()
            else
                if my > 0 then
                    MoveCharacterCameraZoomAmount(1)
                elseif my < 0 then
                    MoveCharacterCameraZoomAmount(-1)
                else
                    StopCharacterCameraZoom()
                end
                CharacterCreateStopMouseSpin()
            end
        end,
    }

    function ZO_PaperdollManipulation_Gamepad_Initialize(self)
        self.Activate = function()
            DIRECTIONAL_INPUT:Activate(paperDollInputObject, self)
        end

        self.Deactivate = function()
            DIRECTIONAL_INPUT:Deactivate(paperDollInputObject)
        end

        self.StopAllInput = function()
            CharacterCreateStopMouseSpin()
            StopCharacterCameraZoom()
        end
    end
end

function ZO_CharacterNaming_Gamepad_CreateDialog(self, params)
    local parametricDialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    self.errorLabel = params.errorControl:GetNamedChild("Errors")

    local function UpdateSelectedName(name, suppressErrors)
        if parametricDialog.selectedName ~= name then
            parametricDialog.selectedName = name
            parametricDialog.nameViolations = { IsValidCharacterName(parametricDialog.selectedName) }
            parametricDialog.noViolations = #parametricDialog.nameViolations == 0

            parametricDialog.selectedName = CorrectCharacterNameCase(parametricDialog.selectedName)
            
            if not parametricDialog.noViolations then
                if suppressErrors then
                    SCENE_MANAGER:RemoveFragment(params.errorFragment)
                else
                    local HIDE_UNVIOLATED_RULES = true
                    local violationString = ZO_ValidNameInstructions_GetViolationString(parametricDialog.selectedName, parametricDialog.nameViolations, HIDE_UNVIOLATED_RULES, SI_CREATE_CHARACTER_GAMEPAD_INVALID_NAME_DIALOG_INSTRUCTION_FORMAT)

                    self.errorLabel:SetText(violationString)
                    SCENE_MANAGER:AddFragment(params.errorFragment)
                end
            else
                SCENE_MANAGER:RemoveFragment(params.errorFragment)
            end

        end

        KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
    end


    local function ReleaseDialog()
        SCENE_MANAGER:RemoveFragment(params.errorFragment)
        ZO_Dialogs_ReleaseDialogOnButtonPress(params.dialogName)
    end 

    local function SetupDialog(dialog, data)
        dialog.selectedName = nil
        local headerData = {}

        if data ~= nil and data.characterName ~= nil then
            UpdateSelectedName(data.characterName)
        else
            local SUPPRESS_ERRORS = true
            UpdateSelectedName("", SUPPRESS_ERRORS)
        end

        if params and params.createHeaderDataFunction then
            headerData = params.createHeaderDataFunction(dialog, data)
        end

        dialog:setupFunc(nil, headerData)
    end

    local doneEntry = ZO_GamepadEntryData:New(GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_DONE), "EsoUI/Art/Miscellaneous/Gamepad/gp_submit.dds")
    doneEntry.setup = function(control, data, selected, reselectingDuringRebuild, _, active)
        self.doneControl = control

        data.disabled = not parametricDialog.noViolations or self.isCreating
        local enabled = not data.disabled
        data:SetEnabled(enabled)

        ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    end


    ZO_Dialogs_RegisterCustomDialog(params.dialogName,
    {
        mustChoose = true,
        canQueue = true,
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = SetupDialog,
        OnShownCallback = function()
            -- Open Keyboard immediately on entering finishing character dialog
            if self.editBoxControl then
                self.editBoxControl:TakeFocus()
            end
        end,
        blockDialogReleaseOnPress = true, -- We'll handle Dialog Releases ourselves since we don't want DIALOG_PRIMARY to release the dialog on press.

        title =
        {
            text = params.dialogTitle,
        },
        mainText = 
        {
            text = params.dialogMainText,
        },
        parametricList =
        {
            -- name edit box
            {
                template = "ZO_Gamepad_GenericDialog_Parametric_TextFieldItem",

                templateData = {
                    nameField = true,
                    textChangedCallback = function(control) 
                        local newName = control:GetText()
                        
                        UpdateSelectedName(newName)
                        if control:GetText() ~= parametricDialog.selectedName then
                            control:SetText(parametricDialog.selectedName)
                        end
                    end,

                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        control.editBoxControl.textChangedCallback = data.textChangedCallback
                        
                        ZO_EditDefaultText_Initialize(control.editBoxControl, GetString(SI_CREATE_CHARACTER_GAMEPAD_ENTER_NAME))

                        local validInput = parametricDialog.selectedName and parametricDialog.selectedName ~= ""
                        if validInput then
                            control.editBoxControl:SetText(parametricDialog.selectedName)
                        end
                        
                        SetupEditControlForNameValidation(control.editBoxControl)

                        control.editBoxControl:SetMaxInputChars(CHARNAME_MAX_LENGTH)
                        control.highlight:SetHidden(not selected)
                        self.editBoxSelected = selected
                        self.editBoxControl = control.editBoxControl
                    end,
                },
            },
            -- Done menu item
            {
                template = "ZO_GamepadTextFieldSubmitItem",
                templateData = doneEntry,
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_SELECT),

                callback = function(dialog)
                    if self.editBoxSelected then
                        local targetControl = dialog.entryList:GetTargetControl()
                        if targetControl and targetControl.editBoxControl then
                            targetControl.editBoxControl:TakeFocus()
                        end
                    else
                        if not dialog.noViolations then
                            return
                        end

                        ReleaseDialog()

                        if params.onFinish then
                            params.onFinish(dialog)
                        end
                    end
                end,
                enabled = function()
                    return self.editBoxSelected or parametricDialog.noViolations
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_CREATE_CHARACTER_GAMEPAD_FINISH_BACK),

                callback = function(dialog)
                    ReleaseDialog()

                    if params.onBack then
                        params.onBack(dialog)
                    end

                    PlaySound(SOUNDS.GAMEPAD_MENU_BACK)
                end,
            },
        },
    })
end
